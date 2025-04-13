import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Re-enable provider
import 'package:shared_preferences/shared_preferences.dart'; // Re-enable SharedPreferences
import 'core/di/locator.dart'; // Re-enable locator
// import 'data/datasources/local/sqlite_local_data_source.dart'; // Keep disabled
// import 'presentation/bloc/medicine_provider.dart'; // Keep disabled for now
import 'presentation/bloc/settings_provider.dart'; // Re-enable SettingsProvider
// import 'presentation/bloc/alternatives_provider.dart'; // Keep disabled
// import 'presentation/bloc/dose_calculator_provider.dart'; // Keep disabled
// import 'presentation/bloc/interaction_provider.dart'; // Keep disabled
// import 'presentation/bloc/subscription_provider.dart'; // Keep disabled
import 'presentation/screens/main_screen.dart'; // Keep disabled for now
import 'presentation/screens/onboarding_screen.dart'; // Keep disabled for now

const String _prefsKeyOnboardingDone = 'onboarding_complete';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Setup only necessary parts for this test ---
  locator.registerSingletonAsync<SharedPreferences>(() async {
    return await SharedPreferences.getInstance();
  });
  locator.registerFactory(() => SettingsProvider());
  await locator.isReady<SharedPreferences>();
  // --- End of minimal setup ---

  // --- Temporarily bypass onboarding/main screen logic ---
  // final prefs = await locator.getAsync<SharedPreferences>();
  // final bool onboardingComplete = prefs.getBool(_prefsKeyOnboardingDone) ?? false;
  // final Widget initialScreen = onboardingComplete ? const MainScreen() : const OnboardingScreen();
  final Widget testScreen = Scaffold(
    // Removed const from variable declaration
    appBar: AppBar(
      title: const Text("Minimal Home Test"),
    ), // Removed const from AppBar, added to Text
    body: Center(child: Text("MyAppMinimal Running with Test Screen")),
  );
  // --- End of bypass ---

  // --- Seeding remains disabled ---
  print("INFO: Database seeding is temporarily disabled for testing.");

  // --- Subscription init remains disabled ---
  // locator<SubscriptionProvider>().initialize();

  // Run the app with only SettingsProvider and the simple test screen
  runApp(
    MyAppMinimal(homeWidget: testScreen),
  ); // Use MyAppMinimal with testScreen
}

// Restore MyAppMinimal structure
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
          // Show loading indicator until settings are loaded
          if (!settingsProvider.isInitialized) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          // Build the app once settings are loaded
          // Use a basic theme for now
          return MaterialApp(
            title: 'MediSwitch (Minimal Test)',
            debugShowCheckedModeBanner: false,
            themeMode: settingsProvider.themeMode,
            theme: ThemeData.light(useMaterial3: true).copyWith(
              textTheme: ThemeData.light().textTheme.apply(
                fontFamily: 'Noto Sans Arabic',
              ),
            ),
            darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
              textTheme: ThemeData.dark().textTheme.apply(
                fontFamily: 'Noto Sans Arabic',
              ),
            ),
            locale: settingsProvider.locale,
            home: homeWidget, // Use the passed simple test screen
          );
        },
      ),
    );
  }
}
