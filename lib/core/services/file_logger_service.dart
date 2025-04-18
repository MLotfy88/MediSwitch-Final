import 'dart:io';
import 'dart:convert'; // Import for Encoding and utf8
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
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
    if (!_initSucceeded || _sink == null) {
      // Don't print every line if sink failed, just log the attempt once maybe
      // print("[FileOutput] Attempted to write but sink is not initialized. Lines: ${event.lines}");
      return;
    }
    try {
      final timestamp = DateFormat(
        'HH:mm:ss.SSS',
      ).format(DateTime.now()); // Add timestamp
      for (var line in event.lines) {
        final formattedLine = '[$timestamp] $line'; // Format line once
        _sink?.writeln(formattedLine); // Write to file sink
        logNotifier.addLog(formattedLine); // Add to in-memory notifier
      }
    } catch (e) {
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
    try {
      // Try documents directory first
      if (Platform.isAndroid || Platform.isIOS) {
        print("[FileLoggerService] Getting application documents directory...");
        directory = await getApplicationDocumentsDirectory();
        print(
          "[FileLoggerService] Documents directory path: ${directory.path}",
        );
      } else {
        print(
          "[FileLoggerService] Platform not Android/iOS, skipping documents directory.",
        );
      }
    } catch (e, s) {
      print("[FileLoggerService] Error getting documents directory: $e\n$s");
      directory = null; // Fallback if error occurs
    }

    // Fallback to external storage if documents directory failed or not available
    // Note: External storage might require specific permissions on newer Android versions.
    // Let's avoid external storage for now due to permission complexities.
    // if (directory == null && Platform.isAndroid) {
    //   try {
    //     print("[FileLoggerService] Falling back to external storage directory...");
    //     directory = await getExternalStorageDirectory(); // Might be null if unavailable
    //     print("[FileLoggerService] External storage directory path: ${directory?.path}");
    //   } catch (e, s) {
    //     print("[FileLoggerService] Error getting external storage directory: $e\n$s");
    //     directory = null;
    //   }
    // }

    if (directory == null) {
      print(
        "[FileLoggerService] Could not obtain a valid directory for logging. Using console only.",
      );
      final errorMsg = "Could not obtain log directory. Using console logging.";
      logger.e(errorMsg);
      logNotifier.addLog("[ERROR] $errorMsg"); // Log error to notifier
      _isInitialized = true; // Mark as initialized, but file logging failed
      _fileOutputInitialized = false;
      return;
    }

    try {
      // Use documents directory path
      _logFile = File(path.join(directory.path, 'app_log.txt'));
      print("[FileLoggerService] Attempting to log to: ${_logFile?.path}");

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
          output: fileOutput,
          level: Level.verbose,
        );
        _fileOutputInitialized = true;
        print("[FileLoggerService] Switched to FileOutput successfully.");
        const initMsg =
            "-------------------- FileLoggerService Initialized --------------------";
        final pathMsg = "Logging to: ${_logFile?.path}";
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
            "File sink initialization failed. Using console logging.";
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
      final errorMsg = "FileLoggerService critical initialization error";
      logger.e(errorMsg, error: e, stackTrace: s);
      logNotifier.addLog("[CRITICAL] $errorMsg: $e"); // Log critical error
      _isInitialized = true;
      _fileOutputInitialized = false;
    }
  }

  // Methods to log messages
  void v(dynamic message) => logger.v(message);
  void d(dynamic message) => logger.d(message);
  void i(dynamic message) => logger.i(message);
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logger.w(message, error: error, stackTrace: stackTrace);
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logger.e(message, error: error, stackTrace: stackTrace);
  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logger.f(message, error: error, stackTrace: stackTrace);

  Future<void> close() async {
    logger.i("Closing FileLoggerService.");
    await logger.close();
    _isInitialized = false;
    _fileOutputInitialized = false;
    print("[FileLoggerService] Closed.");
  }
}
