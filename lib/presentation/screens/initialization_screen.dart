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
        final bool firstLaunchDone =
            prefs.getBool(_prefsKeyFirstLaunchDone) ?? false;

        _logger.i(
          "InitializationScreen: Flags - OnboardingDone: $onboardingComplete, FirstLaunchDone: $firstLaunchDone",
        );

        Widget nextScreen;

        if (!onboardingComplete) {
          _logger.i("InitializationScreen: Routing to OnboardingScreen.");
          // Mark seeding complete here because onboarding doesn't depend on it,
          // and if the user quits during onboarding, we don't want a deadlock later.
          localDataSource.markSeedingAsComplete();
          nextScreen = const OnboardingScreen();
        } else if (!firstLaunchDone) {
          _logger.i("InitializationScreen: Routing to SetupScreen.");
          // Seeding will be handled by SetupScreen. It will set the flag.
          nextScreen = const SetupScreen();
        } else {
          _logger.i("InitializationScreen: Routing to MainScreen.");
          // Seeding is already done (or should be), mark complete just in case.
          localDataSource.markSeedingAsComplete();
          nextScreen = const MainScreen();
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
