import 'dart:io';
import 'dart:convert'; // Import for Encoding and utf8
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  @override
  Future<void> init() async {
    // Make async
    _sink = file.openWrite(
      mode: overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
      encoding: encoding,
    );
  }

  @override
  void output(OutputEvent event) {
    _sink?.writeAll(event.lines, '\n');
    _sink?.writeln(); // Add an extra newline for separation
  }

  @override
  @override
  Future<void> destroy() async {
    // Make async
    await _sink?.flush();
    await _sink?.close();
  }
}

class FileLoggerService {
  late final Logger logger;
  File? _logFile;
  bool _isInitialized = false;

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

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDirectory = Directory(
        path.join(directory.path, 'logs'),
      ); // Use path.join

      if (!await logDirectory.exists()) {
        await logDirectory.create(recursive: true);
        print("Log directory created: ${logDirectory.path}");
      }

      _logFile = File(
        path.join(logDirectory.path, 'app_log.txt'),
      ); // Use path.join
      print("Log file path: ${_logFile?.path}");

      logger = Logger(
        // Customize printer for simple output
        printer: SimplePrinter(printTime: true, colors: false),
        output: FileOutput(file: _logFile!),
        // Set level to verbose to capture everything during debugging
        level: Level.verbose,
      );

      logger.i("FileLoggerService Initialized. Logging to: ${_logFile?.path}");
      _isInitialized = true;
    } catch (e) {
      print("Error initializing FileLoggerService: $e");
      // Fallback to console logger if file logging fails
      logger = Logger(printer: SimplePrinter(printTime: true));
      logger.e("File logging failed, falling back to console.", error: e);
      _isInitialized = false; // Mark as not initialized properly
    }
  }

  // Methods to log messages
  void v(dynamic message) => logger.v(message); // Verbose
  void d(dynamic message) => logger.d(message); // Debug
  void i(dynamic message) => logger.i(message); // Info
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logger.w(message, error: error, stackTrace: stackTrace); // Warning
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logger.e(message, error: error, stackTrace: stackTrace); // Error
  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logger.f(message, error: error, stackTrace: stackTrace); // Fatal

  Future<void> close() async {
    logger.i("Closing FileLoggerService.");
    await logger.close();
    _isInitialized = false;
  }
}

// Global instance accessor (optional, can also use DI)
// final fileLogger = FileLoggerService();
