import 'dart:convert'; // Import for Encoding and utf8
import 'dart:io';

import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:intl/intl.dart'; // Import intl for DateFormat
import 'package:logger/logger.dart';
import 'package:mediswitch/core/services/log_notifier.dart'; // Fixed: Use package import
import 'package:path/path.dart' as path; // Import path package
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'package:share_plus/share_plus.dart'; // Add share_plus

// --- FileOutput Class (Handles writing to the file sink) ---
/// Output to file
class FileOutput extends LogOutput {
  /// Internal notifier
  final LogNotifier logNotifier; // Add LogNotifier instance
  final File file;
  final bool overrideExisting;
  final Encoding encoding;
  IOSink? _sink;
  bool _initSucceeded = false; // Track if sink opened

  FileOutput({
    required this.logNotifier, // Require LogNotifier
    required this.file,
    this.overrideExisting = false,
    this.encoding = utf8,
  });

  @override
  Future<void> init() async {
    debugPrint('[FileOutput] Initializing sink for file: ${file.path}');
    try {
      // Ensure directory exists
      if (!await file.parent.exists()) {
        debugPrint(
          '[FileOutput] Log directory does not exist, creating: ${file.parent.path}',
        );
        await file.parent.create(recursive: true);
      }
      _sink = file.openWrite(
        mode: overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
        encoding: encoding,
      );
      _initSucceeded = true; // Mark as succeeded
      print("[FileOutput] Sink opened successfully.");
      _sink?.writeln(
        "--- Log Initialized: ${DateTime.now()} ---",
      ); // Write initial marker
    } catch (e, s) {
      debugPrint(
        '[FileOutput] CRITICAL Error opening sink: $e\n$s',
      ); // Console print for error
      _sink = null;
      _initSucceeded = false;
    }
  }

  @override
  void output(OutputEvent event) {
    // Always try to add to notifier first, regardless of file sink state
    try {
      final timestamp = DateFormat(
        'HH:mm:ss.SSS',
      ).format(DateTime.now()); // Add timestamp
      for (var line in event.lines) {
        final formattedLine = '[$timestamp] $line'; // Format line once
        // Add to notifier FIRST
        logNotifier.addLog(formattedLine);
        // Then, attempt to write to file sink if initialized
        if (_initSucceeded && _sink != null) {
          _sink?.writeln(formattedLine);
        }
      }
    } catch (e) {
      // Log error related to file writing specifically
      debugPrint('[FileOutput] Error writing to sink: $e');
      // Maybe try to close and reopen sink? Or just stop logging.
      _initSucceeded = false;
    }
  }

  @override
  Future<void> destroy() async {
    debugPrint('[FileOutput] Destroying sink...');
    if (!_initSucceeded || _sink == null) {
      print("[FileOutput] Sink already closed or failed to initialize.");
      return;
    }
    try {
      _sink?.writeln("--- Log Closed: ${DateTime.now()} ---");
      await _sink?.flush();
      await _sink?.close();
      print("[FileOutput] Sink flushed and closed.");
    } catch (e) {
      print('[FileOutput] Error closing sink: $e');
    }
    _sink = null;
    _initSucceeded = false;
  }
}

// --- FileLoggerService Class (Manages the logger instance) ---
class FileLoggerService {
  /// Internal notifier for log updates
  final LogNotifier logNotifier = LogNotifier(); // Create LogNotifier instance
  /// Logger instance
  late Logger logger;
  File? _logFile;
  bool _isInitialized = false;
  bool _fileOutputInitialized = false;

  // Private constructor
  FileLoggerService._();

  // Singleton instance
  // Singleton instance
  static final FileLoggerService _instance = FileLoggerService._();

  // Factory constructor to return the singleton instance
  factory FileLoggerService() {
    return _instance;
  }

  /// Initialize the logger service
  Future<void> initialize() async {
    if (_isInitialized) return;
    debugPrint('[FileLoggerService] Initializing...');

    // Default to console logger initially
    logger = Logger(printer: SimplePrinter(printTime: true, colors: true));

    Directory? directory;
    String logPathSource = "Unknown";

    // --- Determine Log Directory ---
    try {
      if (Platform.isAndroid) {
        logNotifier.addLog("[INFO] Checking storage permission (Android)...");

        // On Android 11+ (API 30+), use MANAGE_EXTERNAL_STORAGE for broad access if needed,
        // but for Downloads/MediSwitchLogs, standard storage permission or just using the path might work depending on scoped storage.
        // However, for maximum accessibility as requested, we'll try the common Downloads path.

        bool hasPermission = false;
        if (await Permission.manageExternalStorage.isGranted ||
            await Permission.storage.isGranted) {
          hasPermission = true;
        } else {
          logNotifier.addLog("[INFO] Requesting storage permission...");
          final status = await Permission.storage.request();
          hasPermission = status.isGranted;

          if (!hasPermission &&
              await Permission.manageExternalStorage.request().isGranted) {
            hasPermission = true;
          }
        }

        if (hasPermission) {
          logNotifier.addLog('[INFO] Storage permission granted.');
          try {
            // Target the public Downloads directory
            final String downloadPath =
                '/storage/emulated/0/Download/MediSwitchLogs';
            directory = Directory(downloadPath);
            logPathSource = "Public Downloads Folder";

            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          } catch (e) {
            debugPrint(
              '[FileLoggerService] Error creating public log directory: $e',
            );
            directory = null; // Fallback
          }
        } else {
          logNotifier.addLog('[WARN] Storage permission denied.');
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationSupportDirectory();
        logPathSource = "Application Support (iOS)";
      }

      // Fallback
      if (directory == null) {
        logNotifier.addLog(
          '[INFO] Falling back to internal documents directory.',
        );
        directory = await getApplicationDocumentsDirectory();
        logPathSource = 'Internal Documents';
      }
    } catch (e, s) {
      debugPrint('[FileLoggerService] Error determining log directory: $e\n$s');
      directory = await getApplicationDocumentsDirectory();
      logPathSource = "Internal Documents (Emergency Fallback)";
    }

    // --- Check if a directory was obtained ---
    if (directory == null) {
      debugPrint(
        '[FileLoggerService] Could not obtain a valid directory for logging. Using console only.',
      );
      const errorMsg =
          'Could not obtain ANY valid directory for logging. Using console only.';
      logger.e(errorMsg);
      logNotifier.addLog(
        '[CRITICAL] $errorMsg',
      ); // Log critical error to notifier
      _isInitialized = true; // Mark as initialized, but file logging failed
      _fileOutputInitialized = false;
      return;
    }

    try {
      // Use the obtained directory path (either external or internal)
      _logFile = File(path.join(directory.path, 'app_log.txt'));
      final logFilePath = _logFile?.path ?? "Unknown Path";
      print(
        "[FileLoggerService] Attempting to log to: $logFilePath (Source: $logPathSource)",
      );
      logNotifier.addLog(
        "[INFO] Attempting to log to: $logFilePath (Source: $logPathSource)",
      );

      final fileOutput = FileOutput(
        logNotifier: logNotifier, // Pass notifier
        file: _logFile!,
      );
      await fileOutput.init(); // Wait for sink to initialize

      if (fileOutput._initSucceeded) {
        // Check success flag
        logger = Logger(
          printer: SimplePrinter(
            printTime: false,
            colors: false,
          ), // No time/color in file
          output: MultiOutput([
            // Log to both console and file/notifier
            ConsoleOutput(),
            fileOutput,
          ]),
          level: Level.verbose,
        );
        _fileOutputInitialized = true;
        print("[FileLoggerService] Switched to FileOutput successfully.");
        const initMsg =
            "-------------------- FileLoggerService Initialized --------------------";
        final pathMsg = "Logging to file: ${logFilePath}"; // Use variable
        final timeMsg = "App Start Time: ${DateTime.now()}";
        const separatorMsg =
            "-----------------------------------------------------------------------";

        logger.i(initMsg);
        logger.i(pathMsg);
        logger.i(timeMsg);
        logger.i(separatorMsg);

        // Also log initialization messages to the notifier
        logNotifier.addLog(initMsg);
        logNotifier.addLog(pathMsg);
        logNotifier.addLog(timeMsg);
        logNotifier.addLog(separatorMsg);
      } else {
        print(
          "[FileLoggerService] FileOutput sink initialization failed. Falling back to console.",
        );
        const errorMsg =
            "File sink initialization failed. Using console logging only.";
        // Keep the initial console logger setup earlier
        logger.e(errorMsg);
        logNotifier.addLog("[ERROR] $errorMsg"); // Log error to notifier
        _fileOutputInitialized = false;
      }

      _isInitialized = true;
      debugPrint(
        '[FileLoggerService] Initialization process complete. File output initialized: $_fileOutputInitialized',
      );
    } catch (e, s) {
      debugPrint(
        '[FileLoggerService] CRITICAL Error during file output setup: $e\n$s',
      );
      const errorMsg =
          'FileLoggerService critical initialization error during file setup';

      // Fixed: Logger will eventually be initialized in v/d/i methods even if file setup fails
      logNotifier.addLog('[CRITICAL] $errorMsg: $e');
      _isInitialized = true;
      _fileOutputInitialized = false;
    }
  }

  // Methods to log messages
  // Ensure logger is initialized before calling methods
  // Also directly add to notifier for redundancy
  /// Log trace/verbose message
  void v(dynamic message) {
    final msg = '[V] $message';
    logNotifier.addLog(msg); // Add directly to notifier
    if (_isInitialized) {
      logger.t(message); // Updated from .v to .t
    } else {
      debugPrint('[Log NOINIT] V: $message');
    }
  }

  /// Log debug message
  void d(dynamic message) {
    final msg = '[D] $message';
    logNotifier.addLog(msg); // Add directly to notifier
    if (_isInitialized) {
      logger.d(message);
    } else {
      debugPrint('[Log NOINIT] D: $message');
    }
  }

  /// Log info message
  void i(dynamic message) {
    final msg = '[I] $message';
    logNotifier.addLog(msg); // Add directly to notifier
    if (_isInitialized) {
      logger.i(message);
    } else {
      debugPrint('[Log NOINIT] I: $message');
    }
  }

  /// Log warning message
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final msg = '[W] $message ${error ?? ''} ${stackTrace ?? ''}';
    logNotifier.addLog(msg); // Add directly to notifier
    if (_isInitialized) {
      logger.w(message, error: error, stackTrace: stackTrace);
    } else {
      debugPrint('[Log NOINIT] W: $message');
    }
  }

  /// Log error message
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final msg = '[E] $message ${error ?? ''} ${stackTrace ?? ''}';
    logNotifier.addLog(msg); // Add directly to notifier
    if (_isInitialized) {
      logger.e(message, error: error, stackTrace: stackTrace);
    } else {
      debugPrint('[Log NOINIT] E: $message');
    }
  }

  /// Log fatal message
  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final msg = '[F] $message ${error ?? ''} ${stackTrace ?? ''}';
    logNotifier.addLog(msg); // Add directly to notifier
    if (_isInitialized) {
      logger.f(message, error: error, stackTrace: stackTrace);
    } else {
      debugPrint('[Log NOINIT] F: $message');
    }
  }

  /// Returns the current log file if initialized
  File? getLogFile() => _logFile;

  /// Share the log file using share_plus
  Future<void> shareLogFile() async {
    if (_logFile == null || !await _logFile!.exists()) {
      debugPrint('[FileLoggerService] Cannot share: Log file does not exist.');
      return;
    }

    try {
      final xFile = XFile(_logFile!.path);
      await Share.shareXFiles([xFile], text: 'MediSwitch App Logs');
    } catch (e) {
      debugPrint('[FileLoggerService] Error sharing log file: $e');
    }
  }

  Future<void> close() async {
    // Check if logger was ever successfully initialized with file output
    if (_isInitialized && _fileOutputInitialized) {
      logger.i("Closing FileLoggerService.");
      await logger.close();
    } else {
      print(
        "[FileLoggerService] Skipping logger close (was console only or failed init).",
      );
    }
    _isInitialized = false;
    _fileOutputInitialized = false;
    print("[FileLoggerService] Closed.");
  }
}
