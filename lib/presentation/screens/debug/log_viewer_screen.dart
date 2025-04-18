import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:provider/provider.dart'; // For listening to Notifier
import 'package:share_plus/share_plus.dart'; // For sharing logs
import '../../../core/di/locator.dart'; // To get LogNotifier
import '../../../core/services/log_notifier.dart'; // The Notifier class
import 'package:lucide_icons/lucide_icons.dart'; // For icons

class LogViewerScreen extends StatelessWidget {
  const LogViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use ChangeNotifierProvider to listen to LogNotifier updates
    return ChangeNotifierProvider.value(
      value: locator<LogNotifier>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('App Logs (Recent)'),
          actions: [
            // Clear Logs Button
            Consumer<LogNotifier>(
              builder: (context, notifier, child) {
                return IconButton(
                  icon: const Icon(LucideIcons.trash2),
                  tooltip: 'Clear Logs',
                  onPressed:
                      notifier.logs.isEmpty
                          ? null // Disable if no logs
                          : () {
                            notifier.clearLogs();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('In-memory logs cleared.'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                );
              },
            ),
            // Share Logs Button
            Consumer<LogNotifier>(
              builder: (context, notifier, child) {
                return IconButton(
                  icon: const Icon(LucideIcons.share2),
                  tooltip: 'Share Logs',
                  onPressed:
                      notifier.logs.isEmpty
                          ? null // Disable if no logs
                          : () async {
                            final logText = notifier.logs.join('\n');
                            await Share.share(
                              logText,
                              subject:
                                  'App Logs - ${DateTime.now().toIso8601String()}',
                            );
                          },
                );
              },
            ),
            // Copy Logs Button
            Consumer<LogNotifier>(
              builder: (context, notifier, child) {
                return IconButton(
                  icon: const Icon(LucideIcons.copy),
                  tooltip: 'Copy Logs',
                  onPressed:
                      notifier.logs.isEmpty
                          ? null // Disable if no logs
                          : () {
                            final logText = notifier.logs.join('\n');
                            Clipboard.setData(ClipboardData(text: logText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logs copied to clipboard!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                );
              },
            ),
          ],
        ),
        // Use Consumer to rebuild the list when logs change
        body: Consumer<LogNotifier>(
          builder: (context, notifier, child) {
            final logs = notifier.logs;
            if (logs.isEmpty) {
              return const Center(child: Text('No logs recorded yet.'));
            }
            // Display logs in a scrollable list, newest first
            return ListView.builder(
              reverse: true, // Show newest logs at the bottom (visually)
              itemCount: logs.length,
              itemBuilder: (context, index) {
                // Access logs in reverse order for display
                final logIndex = logs.length - 1 - index;
                final logEntry = logs[logIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    logEntry,
                    style: const TextStyle(
                      fontFamily:
                          'monospace', // Use monospace for better alignment
                      fontSize: 12.0,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
