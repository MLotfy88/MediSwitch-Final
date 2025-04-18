import 'dart:io';
import 'dart:convert'; // Import for Encoding and utf8
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'package:intl/intl.dart'; // Import intl for DateFormat
import 'package:path/path.dart' as path; // Import path package
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'log_notifier.dart'; // Import the new LogNotifier

// --- FileOutput Class (Handles writing to the file sink) ---
class FileOutput extends LogOutput {
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
    print("[FileOutput] Initializing sink for file: ${file.path}");
    try {
      // Ensure directory exists
      if (!await file.parent.exists()) {
        print(
          "[FileOutput] Log directory does not exist, creating: ${file.parent.path}",
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
      print(
        "[FileOutput] CRITICAL Error opening sink: $e\n$s",
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
      print("[FileOutput] Error writing to sink: $e");
      // Maybe try to close and reopen sink? Or just stop logging.
      _initSucceeded = false;
    }
  }

  @override
  Future<void> destroy() async {
    print("[FileOutput] Destroying sink...");
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
      print("[FileOutput] Error closing sink: $e");
    }
    _sink = null;
    _initSucceeded = false;
  }
}

// --- FileLoggerService Class (Manages the logger instance) ---
class FileLoggerService {
  final LogNotifier logNotifier = LogNotifier(); // Create LogNotifier instance
  late Logger logger;
  File? _logFile;
  bool _isInitialized = false;
  bool _fileOutputInitialized = false;

  // Private constructor
  FileLoggerService._();

  // Singleton instance
  static final FileLoggerService _instance = FileLoggerService._();

  // Factory constructor to return the singleton instance
  factory FileLoggerService() {
    return _instance;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    print("[FileLoggerService] Initializing...");

    // Default to console logger initially
    logger = Logger(printer: SimplePrinter(printTime: true, colors: true));

    Directory? directory;
    String logPathSource = "Unknown";

    // --- Determine Log Directory ---
    try {
      if (Platform.isAndroid) {
        logNotifier.addLog("[INFO] Checking storage permission (Android)...");
        print("[FileLoggerService] Checking storage permission (Android)...");
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          logNotifier.addLog("[INFO] Requesting storage permission...");
          print("[FileLoggerService] Requesting storage permission...");
          status = await Permission.storage.request();
        }

        if (status.isGranted) {
          logNotifier.addLog("[INFO] Storage permission granted.");
          print("[FileLoggerService] Storage permission granted.");
          Directory? externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            directory = Directory(
              path.join(externalDir.path, 'MediSwitchLogs'),
            );
            logPathSource = "External Storage (App Specific)";
            print(
              "[FileLoggerService] Target external directory: ${directory.path}",
            );
            if (!await directory.exists()) {
              print("[FileLoggerService] Creating external log directory...");
              await directory.create(recursive: true);
            }
          } else {
            logNotifier.addLog(
              "[WARN] getExternalStorageDirectory returned null.",
            );
            print(
              "[FileLoggerService] getExternalStorageDirectory returned null.",
            );
          }
        } else {
          logNotifier.addLog("[WARN] Storage permission denied.");
          print("[FileLoggerService] Storage permission denied.");
        }
      } else if (Platform.isIOS) {
        // On iOS, use Application Support Directory
        print(
          "[FileLoggerService] Getting application support directory (iOS)...",
        );
        directory = await getApplicationSupportDirectory();
        logPathSource = "Application Support (iOS)";
        print(
          "[FileLoggerService] Using application support directory: ${directory.path}",
        );
      }

      // Fallback to internal documents directory if external/support failed or not applicable
      if (directory == null) {
        logNotifier.addLog(
          "[INFO] Falling back to internal documents directory.",
        );
        print(
          "[FileLoggerService] Falling back to internal documents directory.",
        );
        directory = await getApplicationDocumentsDirectory();
        logPathSource = "Internal Documents";
        print(
          "[FileLoggerService] Using internal documents directory: ${directory.path}",
        );
      }
    } catch (e, s) {
      print(
        "[FileLoggerService] CRITICAL Error determining log directory: $e\n$s",
      );
      logNotifier.addLog("[CRITICAL] Error determining log directory: $e");
      directory = null; // Ensure directory is null on error
    }

    // --- Check if a directory was obtained ---
    if (directory == null) {
      print(
        "[FileLoggerService] Could not obtain a valid directory for logging. Using console only.",
      );
      final errorMsg =
          "Could not obtain ANY valid directory for logging. Using console only.";
      logger.e(errorMsg);
      logNotifier.addLog(
        "[CRITICAL] $errorMsg",
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
      print(
        "[FileLoggerService] Initialization process complete. File output initialized: $_fileOutputInitialized",
      );
    } catch (e, s) {
      print(
        "[FileLoggerService] CRITICAL Error during file output setup: $e\n$s",
      );
      final errorMsg =
          "FileLoggerService critical initialization error during file setup";
      // Ensure logger exists before calling methods on it
      // Check if logger is initialized before using it for the error itself
      if (_isInitialized && logger != null) {
        logger.e(errorMsg, error: e, stackTrace: s);
      } else {
        print(
          "[FileLoggerService] Logger not available to log critical setup error.",
        );
      }
      logNotifier.addLog("[CRITICAL] $errorMsg: $e"); // Log critical error
      _isInitialized = true;
      _fileOutputInitialized = false;
    }
  }

  // Methods to log messages
  // Ensure logger is initialized before calling methods
  // Also directly add to notifier for redundancy
  void v(dynamic message) {
    final String msg = "[V] $message";
    logNotifier.addLog(msg); // Add directly to notifier
    if (_isInitialized)
      logger.v(message);
    else
      print("[Log NOINIT] V: $message");
  }

  void d(dynamic message) {
    final String msg = "[D] $message";
    logNotifier.addLog(msg); // Add directly to notifier
    if (_isInitialized)
      logger.d(message);
    else
      print("[Log NOINIT] D: $message");
  }

  void i(dynamic message) {
    final String msg = "[I] $message";
    logNotifier.addLog(msg); // Add directly to notifier
    if (_isInitialized)
      logger.i(message);
    else
      print("[Log NOINIT] I: $message");
  }

  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final String msg = "[W] $message ${error ?? ''} ${stackTrace ?? ''}";
    logNotifier.addLog(msg); // Add directly to notifier
    if (_isInitialized)
      logger.w(message, error: error, stackTrace: stackTrace);
    else
      print("[Log NOINIT] W: $message");
  }

  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final String msg = "[E] $message ${error ?? ''} ${stackTrace ?? ''}";
    logNotifier.addLog(msg); // Add directly to notifier
    if (_isInitialized)
      logger.e(message, error: error, stackTrace: stackTrace);
    else
      print("[Log NOINIT] E: $message");
  }

  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final String msg = "[F] $message ${error ?? ''} ${stackTrace ?? ''}";
    logNotifier.addLog(msg); // Add directly to notifier
    if (_isInitialized)
      logger.f(message, error: error, stackTrace: stackTrace);
    else
      print("[Log NOINIT] F: $message");
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
