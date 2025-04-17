import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../data/datasources/local/sqlite_local_data_source.dart';
import 'onboarding_screen.dart';
import 'setup_screen.dart';
import 'main_screen.dart';

// Keys from main.dart (consider moving to a shared constants file)
const String _prefsKeyOnboardingDone = 'onboarding_complete';
const String _prefsKeyFirstLaunchDone = 'first_launch_done';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  final FileLoggerService _logger = locator<FileLoggerService>();

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
        // Remove firstLaunchDone check, rely on database seeded status instead
        // final bool firstLaunchDone =
        //     prefs.getBool(_prefsKeyFirstLaunchDone) ?? false;

        _logger.i(
          "InitializationScreen: Flags - OnboardingDone: $onboardingComplete",
        );

        Widget nextScreen;

        if (!onboardingComplete) {
          _logger.i("InitializationScreen: Routing to OnboardingScreen.");
          // DO NOT mark seeding complete here. Let SetupScreen handle it.
          // localDataSource.markSeedingAsComplete();
          nextScreen = const OnboardingScreen();
        } else {
          // Onboarding is complete, now check the first launch flag
          _logger.i(
            "InitializationScreen: Onboarding complete. Checking first launch flag...",
          );
          final bool firstLaunchDone =
              prefs.getBool(_prefsKeyFirstLaunchDone) ?? false;
          _logger.i(
            "InitializationScreen: First launch flag status: $firstLaunchDone",
          );

          if (!firstLaunchDone) {
            _logger.i(
              "InitializationScreen: First launch not done. Routing to SetupScreen.",
            );
            // Seeding will be handled by SetupScreen, which will set the flag.
            nextScreen = const SetupScreen();
          } else {
            _logger.i(
              "InitializationScreen: First launch already done. Routing to MainScreen.",
            );
            // Ensure seeding completer is marked done for subsequent launches
            // in case SetupScreen was somehow skipped or failed previously.
            localDataSource.markSeedingAsComplete();
            nextScreen = const MainScreen();
          }
        }

        if (mounted) {
          // Check again before navigating
          _logger.i(
            "InitializationScreen: Navigating to ${nextScreen.runtimeType}",
          );
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => nextScreen));
        }
      } catch (e, s) {
        _logger.e("InitializationScreen: Error determining route", e, s);
        // Optionally show an error screen here
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error initializing app: $e")));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.d("InitializationScreen: Building loading indicator UI.");
    // Show a simple loading indicator while determining the route
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
