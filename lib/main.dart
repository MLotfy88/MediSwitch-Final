import 'package:flutter/material.dart';
// --- Temporarily Comment Out All Imports ---
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
  // locator<SubscriptionProvider>().initialize();
  // --- End of Temporarily Disable ALL Setup ---

  // Run a minimal app directly
  runApp(
    MaterialApp(
      // Removed const
      title: 'MediSwitch (Minimal UI Test)',
      debugShowCheckedModeBanner: false,
      // Use a very basic theme
      themeMode: ThemeMode.system,
      theme: ThemeData.light(useMaterial3: true), // Removed const
      darkTheme: ThemeData.dark(useMaterial3: true), // Removed const
      // Directly show a simple screen, bypassing onboarding/main logic for now
      home: Scaffold(
        appBar: AppBar(title: const Text("Test Screen")), // Added const to Text
        body: const Center(
          child: Text("Basic MaterialApp Running!"),
        ), // Added const
      ),
    ),
  );
  // runApp(MyAppMinimal(homeWidget: initialScreen)); // Bypass MyAppMinimal
}

// --- MyAppMinimal and Providers are temporarily bypassed ---
/*
class MyAppMinimal extends StatelessWidget {
  final Widget homeWidget;

  const MyAppMinimal({super.key, required this.homeWidget});

  @override
  Widget build(BuildContext context) {
    // Only provide SettingsProvider for this test
    return ChangeNotifierProvider(
      create: (_) => locator<SettingsProvider>(),
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (!settingsProvider.isInitialized) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          return MaterialApp(
            title: 'MediSwitch (Minimal Test)',
            debugShowCheckedModeBanner: false,
            themeMode: settingsProvider.themeMode,
            theme: ThemeData.light(useMaterial3: true).copyWith(
               textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Noto Sans Arabic'),
            ),
            darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
               textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Noto Sans Arabic'),
            ),
            locale: settingsProvider.locale,
            home: homeWidget,
          );
        },
      ),
    );
  }
}
*/
