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
// const String _prefsKeyFirstLaunchDone = 'first_launch_done'; // No longer needed

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
          // Onboarding is complete, now check if the database actually has medicines
          _logger.i(
            "InitializationScreen: Onboarding complete. Checking if database has medicines...",
          );
          // Use the direct check against the database content
          final bool databaseHasMedicines =
              await localDataSource.hasMedicines();
          _logger.i(
            "InitializationScreen: Database has medicines: $databaseHasMedicines",
          );

          if (!databaseHasMedicines) {
            _logger.i(
              "InitializationScreen: Database is empty. Routing to SetupScreen for seeding.",
            );
            // Seeding will be handled by SetupScreen.
            nextScreen = const SetupScreen();
          } else {
            _logger.i(
              "InitializationScreen: Database already contains medicines. Routing to MainScreen.",
            );
            // Ensure seeding completer is marked complete for subsequent operations if needed
            // Although SetupScreen is skipped, other parts might await the completer.
            if (!localDataSource.isSeedingCompleted) {
              _logger.w(
                "InitializationScreen: Seeding completer was not marked complete, but DB has data. Marking complete now.",
              );
              localDataSource.markSeedingAsComplete();
            }
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
