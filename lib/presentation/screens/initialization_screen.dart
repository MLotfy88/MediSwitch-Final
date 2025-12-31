import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/database_helper.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../data/datasources/local/sqlite_local_data_source.dart';
import '../../domain/repositories/interaction_repository.dart';
import '../../presentation/bloc/subscription_provider.dart';
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
      if (!mounted) return;

      _logger.i("InitializationScreen: Determining initial route...");
      try {
        final prefs = await locator.getAsync<SharedPreferences>();
        final bool onboardingComplete =
            prefs.getBool(_prefsKeyOnboardingDone) ?? false;

        _logger.i(
          "InitializationScreen: Flags - OnboardingDone: $onboardingComplete",
        );

        if (!onboardingComplete) {
          _logger.i("InitializationScreen: Fast Path -> OnboardingScreen.");
          // Trigger background priming but DON'T await it
          _backgroundPrime();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          }
          return;
        }

        // --- Safe Path: Full awaited initialization for MainScreen ---
        _logger.i("InitializationScreen: Safe Path -> Full Initialization.");
        final bool success = await _performFullInitialization();

        if (success && mounted) {
          _logger.i(
            "InitializationScreen: Initialization success -> MainScreen.",
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else if (mounted) {
          _logger.e(
            "InitializationScreen: Initialization failed. Showing error.",
          );
          // Error state is already updated in _performFullInitialization
        }
      } catch (e, s) {
        _logger.e(
          "InitializationScreen: Fatal Error in route determination",
          e,
          s,
        );
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = "خطأ في تشغيل التطبيق: $e";
          });
        }
      }
    });
  }

  /// Fire-and-forget background priming
  void _backgroundPrime() {
    Future.microtask(() async {
      _logger.i("InitializationScreen: Background priming started...");
      try {
        await _performFullInitialization(isBackground: true);
        _logger.i("InitializationScreen: Background priming finished.");
      } catch (e) {
        _logger.e(
          "InitializationScreen: Background priming failed (silently)",
          e,
        );
      }
    });
  }

  /// Encapsulates the heavy lifting of database seeding and preloading
  Future<bool> _performFullInitialization({bool isBackground = false}) async {
    try {
      // 0. Wait for DatabaseHelper to be ready (Critical check)
      if (!isBackground) {
        // Only log if foreground, to avoid spam/confusion
        _logger.i("InitializationScreen: Waiting for DatabaseHelper...");
      }
      await locator.isReady<DatabaseHelper>();

      final localDataSource = locator<SqliteLocalDataSource>();

      // 1. Consolidated Initialization (Handles medicines, interactions, and seeding signal)
      _logger.i("InitializationScreen: Running consolidated initialization...");
      await localDataSource.ensureDatabaseInitialized();

      // 3. Initialize Subscription
      _logger.i("InitializationScreen: Initializing SubscriptionProvider...");
      locator<SubscriptionProvider>().initialize();

      // 4. Preload Interactions
      _logger.i("InitializationScreen: Preloading interaction data...");
      try {
        await locator<InteractionRepository>().loadInteractionData();
      } catch (e) {
        _logger.e("InitializationScreen: Interaction preload failed", e);
        // Non-fatal if interactions fail to load, but we log it
      }

      return true;
    } catch (e, s) {
      _logger.e("InitializationScreen: Full initialization error", e, s);
      if (!isBackground) {
        _updateError("حدث خطأ أثناء تحميل البيانات: $e");
      }
      return false;
    }
  }

  void _updateError(String msg) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = msg;
      });
    }
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
