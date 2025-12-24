import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../data/datasources/local/sqlite_local_data_source.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';

// Keys from main.dart (consider moving to a shared constants file)
const String _prefsKeyOnboardingDone = 'onboarding_complete';
// const String _prefsKeyFirstLaunchDone = 'first_launch_done'; // No longer needed

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  final FileLoggerService _logger = locator<FileLoggerService>();
  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _logger.i("InitializationScreen: initState called.");
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    // Ensure widgets are built before navigating
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return; // Check if widget is still mounted

      _logger.i("InitializationScreen: Determining initial route...");
      try {
        final prefs = await locator.getAsync<SharedPreferences>();
        final localDataSource = locator<SqliteLocalDataSource>();

        final bool onboardingComplete =
            prefs.getBool(_prefsKeyOnboardingDone) ?? false;

        _logger.i(
          "InitializationScreen: Flags - OnboardingDone: $onboardingComplete",
        );

        Widget? nextScreen; // Make nullable

        if (!onboardingComplete) {
          _logger.i("InitializationScreen: Routing to OnboardingScreen.");
          nextScreen = const OnboardingScreen();
        } else {
          // Onboarding is complete, check database.
          _logger.i(
            "InitializationScreen: Onboarding complete. Checking if database has medicines...",
          );
          final bool databaseHasMedicines =
              await localDataSource.hasMedicines();
          _logger.i(
            "InitializationScreen: Database has medicines: $databaseHasMedicines",
          );

          if (!databaseHasMedicines) {
            _logger.i(
              "InitializationScreen: Database is empty. Attempting seeding directly...",
            );
            // Show seeding indicator (optional, could update state here)
            // setState(() { _statusMessage = "Seeding database..."; });

            final bool seedingSuccessful =
                await localDataSource.performInitialSeeding();

            if (seedingSuccessful) {
              _logger.i(
                "InitializationScreen: Seeding successful. Routing to MainScreen.",
              );
              nextScreen = const MainScreen();
            } else {
              _logger.e(
                "InitializationScreen: Seeding FAILED. Halting navigation.",
              );
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage =
                      "فشل في تهيئة قاعدة البيانات. تأكد من وجود الملفات المطلوبة.";
                });
              }
              // Throw an error to be caught below, preventing navigation.
              throw Exception("Database seeding failed.");
            }
          } else {
            _logger.i(
              "InitializationScreen: Database already contains medicines. Routing to MainScreen.",
            );
            // Ensure completer is marked if needed (though less critical now)
            if (!localDataSource.isSeedingCompleted) {
              _logger.w(
                "InitializationScreen: Seeding completer was not marked complete, but DB has data. Marking complete now.",
              );
              localDataSource.markSeedingAsComplete();
            }
            nextScreen = const MainScreen();
          }
        }

        // Only navigate if a next screen was determined successfully
        if (nextScreen != null && mounted) {
          _logger.i(
            "InitializationScreen: Navigating to ${nextScreen.runtimeType}",
          );
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => nextScreen!));
        } else if (nextScreen == null) {
          _logger.w(
            "InitializationScreen: No next screen determined (likely due to seeding error). Staying on loading/error screen.",
          );
          // Optionally update state to show a persistent error message here
          // setState(() { _showError = true; _errorMessage = "Failed to initialize database."; });
        }
      } catch (e, s) {
        _logger.e("InitializationScreen: Error determining route", e, s);
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = "خطأ في تشغيل التطبيق: $e";
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  "عذراً، حدث خطأ أثناء التشغيل",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _errorMessage = "";
                        });
                        _determineInitialRoute();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("إعادة المحاولة"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _logger.shareLogFile(),
                      icon: const Icon(Icons.share),
                      label: const Text("مشاركة السجلات"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    _logger.d("InitializationScreen: Building loading indicator UI.");
    // Show a simple loading indicator while determining the route
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
