import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Re-enable provider
import 'package:shared_preferences/shared_preferences.dart'; // Re-enable SharedPreferences
import 'core/di/locator.dart'; // Re-enable locator
// import 'data/datasources/local/sqlite_local_data_source.dart'; // Keep disabled
import 'presentation/bloc/medicine_provider.dart'; // Keep disabled for now
import 'presentation/bloc/settings_provider.dart'; // Re-enable SettingsProvider
import 'presentation/bloc/alternatives_provider.dart'; // Keep disabled
import 'presentation/bloc/dose_calculator_provider.dart'; // Keep disabled
import 'presentation/bloc/interaction_provider.dart'; // Keep disabled
import 'presentation/bloc/subscription_provider.dart'; // Keep disabled
import 'presentation/screens/main_screen.dart'; // Re-enable MainScreen
import 'presentation/screens/onboarding_screen.dart'; // Re-enable OnboardingScreen

const String _prefsKeyOnboardingDone = 'onboarding_complete';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Setup only necessary parts for this test ---
  // We need SharedPreferences for SettingsProvider and onboarding check
  locator.registerSingletonAsync<SharedPreferences>(() async {
    return await SharedPreferences.getInstance();
  });
  // SettingsProvider needs SharedPreferences, register it
  locator.registerFactory(() => SettingsProvider());
  // Wait for SharedPreferences
  await locator.isReady<SharedPreferences>();
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

  // Run the app with only SettingsProvider
  runApp(MyAppMinimal(homeWidget: initialScreen));
}

// Minimal MyApp with only SettingsProvider
class MyAppMinimal extends StatelessWidget {
  final Widget homeWidget;

  const MyAppMinimal({super.key, required this.homeWidget});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Only provide SettingsProvider
        ChangeNotifierProvider(create: (_) => locator<SettingsProvider>()),
        // --- Other providers remain commented out ---
        // ChangeNotifierProvider(create: (_) => locator<MedicineProvider>()),
        // ChangeNotifierProvider(create: (_) => locator<AlternativesProvider>()),
        // ChangeNotifierProvider(create: (_) => locator<DoseCalculatorProvider>()),
        // ChangeNotifierProvider(create: (_) => locator<InteractionProvider>()),
        // ChangeNotifierProvider(create: (_) => locator<SubscriptionProvider>()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (!settingsProvider.isInitialized) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          // Build the app once settings are loaded
          // Use a basic theme for now, as the full theme depends on ColorScheme which might not be fully set up
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
            home:
                homeWidget, // Show the actual initial screen (Onboarding or Main)
          );
        },
      ),
    );
  }
}
