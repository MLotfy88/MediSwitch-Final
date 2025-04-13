import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'core/di/locator.dart';
// import 'data/datasources/local/sqlite_local_data_source.dart';
// import 'presentation/bloc/medicine_provider.dart';
// import 'presentation/bloc/settings_provider.dart';
// import 'presentation/bloc/alternatives_provider.dart';
// import 'presentation/bloc/dose_calculator_provider.dart';
// import 'presentation/bloc/interaction_provider.dart';
// import 'presentation/bloc/subscription_provider.dart';
// import 'presentation/screens/main_screen.dart';
// import 'presentation/screens/onboarding_screen.dart';

// const String _prefsKeyOnboardingDone = 'onboarding_complete';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Temporarily Disable ALL Setup ---
  // await setupLocator();
  // final prefs = await locator.getAsync<SharedPreferences>();
  // final bool onboardingComplete = prefs.getBool(_prefsKeyOnboardingDone) ?? false;
  // final Widget initialScreen = onboardingComplete ? const MainScreen() : const OnboardingScreen();
  // try {
  //   final localDataSource = locator<SqliteLocalDataSource>();
  //   await localDataSource.seedDatabaseFromAssetIfNeeded();
  // } catch (e) {
  //   print("Error during post-locator seeding: $e");
  // }
  // --- End of Temporarily Disable ALL Setup ---

  // Run a minimal app directly
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            'Minimal App Running!',
            textDirection: TextDirection.ltr, // Ensure text direction is set
          ),
        ),
      ),
    ),
  );
  // runApp(MyApp(homeWidget: initialScreen)); // Original runApp commented out
}

// --- MyApp and Providers are temporarily bypassed ---
/*
class MyApp extends StatelessWidget {
  final Widget homeWidget;

  const MyApp({super.key, required this.homeWidget});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ... providers ...
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (!settingsProvider.isInitialized) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          return MaterialApp(
             // ... theme, locale, etc. ...
            home: homeWidget,
          );
        },
      ),
    );
  }
}
*/
