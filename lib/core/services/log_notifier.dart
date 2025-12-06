import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Notifier for logs
class LogNotifier extends ChangeNotifier {
  /// Maximum number of logs to keep
  final int maxLogs;
  // Use a DoubleLinkedQueue for efficient addition/removal from both ends
  final Queue<String> _logs = DoubleLinkedQueue<String>();

  /// Constructor
  LogNotifier({this.maxLogs = 200}); // Keep the last 200 logs by default

  /// List of logs
  List<String> get logs => List.unmodifiable(_logs);

  /// Adds a new log message
  void addLog(String log) {
    if (_logs.length >= maxLogs) {
      _logs.removeFirst(); // Remove the oldest log if capacity is reached
    }
    _logs.addLast(log);
    notifyListeners(); // Notify UI listeners about the change
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
