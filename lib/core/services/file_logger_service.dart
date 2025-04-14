import 'dart:io';
import 'dart:convert'; // Import for Encoding and utf8
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path; // Import path package

// --- FileOutput Class (Handles writing to the file sink) ---
class FileOutput extends LogOutput {
  final File file;
  final bool overrideExisting;
  final Encoding encoding;
  IOSink? _sink;

  FileOutput({
    required this.file,
    this.overrideExisting = false,
    this.encoding = utf8,
  });

  @override
  Future<void> init() async {
    // Make async
    print(
      "[FileOutput] Initializing sink for file: ${file.path}",
    ); // Console print for init
    try {
      _sink = file.openWrite(
        mode: overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
        encoding: encoding,
      );
      print("[FileOutput] Sink opened successfully.");
    } catch (e) {
      print("[FileOutput] Error opening sink: $e"); // Console print for error
      _sink = null; // Ensure sink is null if opening failed
    }
  }

  @override
  void output(OutputEvent event) {
    if (_sink == null) {
      print(
        "[FileOutput] Attempted to write but sink is null. Lines: ${event.lines}",
      );
      return; // Don't attempt to write if sink failed to open
    }
    try {
      _sink?.writeAll(event.lines, '\n');
      _sink?.writeln(); // Add an extra newline for separation
    } catch (e) {
      print("[FileOutput] Error writing to sink: $e");
    }
  }

  @override
  Future<void> destroy() async {
    // Make async
    print("[FileOutput] Destroying sink...");
    try {
      await _sink?.flush();
      await _sink?.close();
      print("[FileOutput] Sink flushed and closed.");
    } catch (e) {
      print("[FileOutput] Error closing sink: $e");
    }
    _sink = null;
  }
}

// --- FileLoggerService Class (Manages the logger instance) ---
class FileLoggerService {
  late Logger logger; // Make non-final to allow fallback
  File? _logFile;
  bool _isInitialized = false;
  bool _fileOutputInitialized =
      false; // Track if file output specifically worked

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
    print("[FileLoggerService] Initializing..."); // Console print

    // Default to console logger initially
    logger = Logger(
      printer: SimplePrinter(printTime: true, colors: true),
    ); // Use colors for console

    try {
      print("[FileLoggerService] Getting application documents directory...");
      final directory = await getApplicationDocumentsDirectory();
      print(
        "[FileLoggerService] Documents directory path: ${directory.path}",
      ); // Console print path

      // Try writing directly to the documents directory first
      _logFile = File(path.join(directory.path, 'app_log.txt'));
      print("[FileLoggerService] Attempting to log to: ${_logFile?.path}");

      final fileOutput = FileOutput(file: _logFile!);
      await fileOutput.init(); // Wait for sink to initialize

      // Check if sink was actually opened in FileOutput.init()
      if (fileOutput._sink != null) {
        logger = Logger(
          printer: SimplePrinter(
            printTime: true,
            colors: false,
          ), // No colors for file
          output: fileOutput,
          level: Level.verbose,
        );
        _fileOutputInitialized = true;
        print("[FileLoggerService] Switched to FileOutput successfully.");
        logger.i(
          "FileLoggerService Initialized. Logging to: ${_logFile?.path}",
        );
      } else {
        print(
          "[FileLoggerService] FileOutput sink initialization failed. Falling back to console.",
        );
        // logger remains the console logger
        logger.e("File sink initialization failed. Using console logging.");
        _fileOutputInitialized = false;
      }

      _isInitialized = true;
      print(
        "[FileLoggerService] Initialization process complete. File output initialized: $_fileOutputInitialized",
      );
    } catch (e, s) {
      print("[FileLoggerService] CRITICAL Error during initialization: $e\n$s");
      // logger remains the console logger
      logger.e(
        "FileLoggerService critical initialization error",
        error: e,
        stackTrace: s,
      );
      _isInitialized =
          true; // Mark as initialized even on error, but file output failed
      _fileOutputInitialized = false;
    }
  }

  // Methods to log messages (delegate to the current logger instance)
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
    await logger.close(); // This will call destroy on FileOutput if it exists
    _isInitialized = false;
    _fileOutputInitialized = false;
    print("[FileLoggerService] Closed.");
  }
}
