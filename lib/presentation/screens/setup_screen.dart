import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../data/datasources/local/sqlite_local_data_source.dart';
import 'main_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final FileLoggerService _logger = locator<FileLoggerService>();
  final SqliteLocalDataSource _localDataSource =
      locator<SqliteLocalDataSource>();

  bool _isSeeding = true;
  String? _error;
  bool _seedingWasPerformed = false;

  @override
  void initState() {
    super.initState();
    _logger.i("SetupScreen: initState called. Starting initial seeding...");
    _performSeeding();
  }

  Future<void> _performSeeding() async {
    setState(() {
      _isSeeding = true;
      _error = null;
    });

    try {
      final stopwatch = Stopwatch()..start();
      // Call the renamed method. It returns true if seeding was attempted and successful.
      final bool seedingSuccessful =
          await _localDataSource.performInitialSeeding();
      _seedingWasPerformed =
          seedingSuccessful; // Keep track for potential future use? (Currently unused)
      stopwatch.stop();
      _logger.i(
        "SetupScreen: Seeding process finished. Seeding attempt successful?: $seedingSuccessful. Duration: ${stopwatch.elapsedMilliseconds}ms",
      );

      // If seeding attempt was successful, navigate away.
      // If it failed, an error should be shown (handled in catch block).
      if (seedingSuccessful && mounted) {
        // Only navigate if seeding was successful
        _navigateToMainApp();
      } else if (!seedingSuccessful && mounted) {
        // If seeding failed but didn't throw an exception (e.g., empty CSV parse)
        // Show a generic error, as the catch block might not have been hit.
        setState(() {
          _isSeeding = false;
          _error =
              "فشل إعداد قاعدة البيانات الأولية.\nلم يتم العثور على بيانات للتحميل.";
        });
      }
    } catch (e, s) {
      // Catch exceptions thrown by performInitialSeeding
      _logger.e("SetupScreen: Error during initial seeding", e, s);
      if (mounted) {
        setState(() {
          _isSeeding = false;
          _error =
              "فشل إعداد قاعدة البيانات الأولية.\nيرجى التحقق من مساحة التخزين والمحاولة مرة أخرى.\n\nتفاصيل الخطأ: $e";
        });
      }
    } finally {
      // Ensure loading state is false if seeding finished or errored
      if (mounted && _isSeeding) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
  }

  Future<void> _navigateToMainApp() async {
    _logger.i(
      "SetupScreen: Seeding complete. Navigating to MainScreen...",
    ); // Removed flag setting log
    // No longer need to set the first_launch_done flag here.
    // InitializationScreen now checks seeding status directly.

    // _logger.i("SetupScreen: Navigating to MainScreen..."); // Log kept below
    // Replace the current route with MainScreen so the user can't navigate back to setup
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.d(
      "SetupScreen: Building widget. isSeeding: $_isSeeding, error: $_error",
    );
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child:
              _isSeeding
                  ? _buildLoadingWidget(context)
                  : _error != null
                  ? _buildErrorWidget(context, _error!)
                  : _buildLoadingWidget(
                    context,
                  ), // Should ideally navigate away before showing this
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'جارٍ تحضير التطبيق للاستخدام الأول...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'قد تستغرق هذه العملية بضع دقائق. شكراً لصبرك.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, String errorMsg) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.serverCrash,
          size: 64,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 24),
        Text(
          'حدث خطأ أثناء الإعداد الأولي',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          errorMsg,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(LucideIcons.refreshCw),
          label: const Text('إعادة المحاولة'),
          onPressed: _performSeeding, // Retry the seeding process
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ],
    );
  }
}
