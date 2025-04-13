import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Re-enable provider
import 'package:shared_preferences/shared_preferences.dart'; // Re-enable SharedPreferences
import 'core/di/locator.dart'; // Re-enable locator
// import 'data/datasources/local/sqlite_local_data_source.dart'; // Keep disabled
import 'presentation/bloc/medicine_provider.dart'; // Re-enable MedicineProvider
import 'presentation/bloc/settings_provider.dart'; // Re-enable SettingsProvider
// import 'presentation/bloc/alternatives_provider.dart'; // Keep disabled
// import 'presentation/bloc/dose_calculator_provider.dart'; // Keep disabled
// import 'presentation/bloc/interaction_provider.dart'; // Keep disabled
// import 'presentation/bloc/subscription_provider.dart'; // Keep disabled
import 'presentation/screens/main_screen.dart'; // Re-enable MainScreen
import 'presentation/screens/onboarding_screen.dart'; // Re-enable OnboardingScreen

const String _prefsKeyOnboardingDone = 'onboarding_complete';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Setup only necessary parts for this test ---
  // We need SharedPreferences for SettingsProvider and onboarding check
  // Also need dependencies for MedicineProvider
  await setupLocator(); // Use the partially re-enabled locator

  // --- End of minimal setup ---

  // Check if onboarding is complete (needs SharedPreferences)
  final prefs = await locator.getAsync<SharedPreferences>();
  final bool onboardingComplete =
      prefs.getBool(_prefsKeyOnboardingDone) ?? false;

  // Determine the initial screen
  final Widget initialScreen =
      onboardingComplete ? const MainScreen() : const OnboardingScreen();

  // --- Seeding remains disabled ---
  print("INFO: Database seeding is temporarily disabled for testing.");

  // --- Subscription init remains disabled ---
  // locator<SubscriptionProvider>().initialize();

  // Run the app with SettingsProvider and MedicineProvider
  runApp(MyAppMinimal(homeWidget: initialScreen));
}

// Restore MyAppMinimal structure
class MyAppMinimal extends StatelessWidget {
  final Widget homeWidget;

  const MyAppMinimal({super.key, required this.homeWidget});

  @override
  Widget build(BuildContext context) {
    // Provide SettingsProvider and MedicineProvider
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => locator<SettingsProvider>()),
        ChangeNotifierProvider(
          create: (_) => locator<MedicineProvider>(),
        ), // Re-enable MedicineProvider
        // --- Other providers remain commented out ---
        // ChangeNotifierProvider(create: (_) => locator<AlternativesProvider>()),
        // ChangeNotifierProvider(create: (_) => locator<DoseCalculatorProvider>()),
        // ChangeNotifierProvider(create: (_) => locator<InteractionProvider>()),
        // ChangeNotifierProvider(create: (_) => locator<SubscriptionProvider>()),
      ],
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
            title: 'MediSwitch (MedicineProvider Test)', // Updated title
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
            home: homeWidget, // Show OnboardingScreen or MainScreen
          );
        },
      ),
    );
  }
}
