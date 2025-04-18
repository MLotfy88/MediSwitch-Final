import 'dart:collection';
import 'package:flutter/foundation.dart';

class LogNotifier extends ChangeNotifier {
  final int maxLogs;
  // Use a DoubleLinkedQueue for efficient addition/removal from both ends
  final Queue<String> _logs = DoubleLinkedQueue<String>();

  LogNotifier({this.maxLogs = 200}); // Keep the last 200 logs by default

  // Provide an unmodifiable view of the logs
  List<String> get logs => List.unmodifiable(_logs);

  void addLog(String log) {
    // --- DEBUG PRINT ---
    // This print statement will show up in the debug console (e.g., VS Code Debug Console or `flutter run` output)
    // every time a log message is supposed to be added to the viewer.
    print("[LogNotifier] addLog called: $log");
    // --- END DEBUG PRINT ---

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
