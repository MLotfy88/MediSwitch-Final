import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'core/di/locator.dart';
import 'presentation/bloc/medicine_provider.dart';
import 'presentation/bloc/settings_provider.dart';
import 'presentation/bloc/alternatives_provider.dart';
import 'presentation/bloc/dose_calculator_provider.dart';
import 'presentation/bloc/interaction_provider.dart';
import 'presentation/bloc/subscription_provider.dart'; // Import Subscription Provider
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/onboarding_screen.dart';

// Define the key here or move to a shared constants file
const String _prefsKeyOnboardingDone = 'onboarding_complete';

// Make main async
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Setup the locator before running the app
  await setupLocator();

  // Check if onboarding is complete
  final prefs = await locator.getAsync<SharedPreferences>();
  final bool onboardingComplete =
      prefs.getBool(_prefsKeyOnboardingDone) ?? false;

  // Determine the initial screen
  final Widget initialScreen =
      onboardingComplete ? const MainScreen() : const OnboardingScreen();

  // Run the app, passing the initial screen
  runApp(MyApp(homeWidget: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget homeWidget; // Add field to hold the initial widget

  const MyApp({super.key, required this.homeWidget});

  @override
  Widget build(BuildContext context) {
    // Wrap with MultiProvider to provide multiple providers
    return MultiProvider(
      providers: [
        // Provide Providers using the locator
        ChangeNotifierProvider(create: (_) => locator<MedicineProvider>()),
        ChangeNotifierProvider(create: (_) => locator<SettingsProvider>()),
        ChangeNotifierProvider(create: (_) => locator<AlternativesProvider>()),
        ChangeNotifierProvider(
          create: (_) => locator<DoseCalculatorProvider>(),
        ),
        ChangeNotifierProvider(create: (_) => locator<InteractionProvider>()),
        ChangeNotifierProvider(
          create: (_) => locator<SubscriptionProvider>(),
        ), // Provide SubscriptionProvider
      ],
      // Consumer is needed here to access SettingsProvider for theme/locale
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          // Show loading indicator until settings are loaded
          if (!settingsProvider.isInitialized) {
            // Return a simple loading screen
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          // Build the app once settings are loaded
          return MaterialApp(
            title: 'MediSwitch',
            debugShowCheckedModeBanner: false,
            themeMode:
                settingsProvider.themeMode, // Use themeMode from provider
            theme: ThemeData(
              // Define light theme
              // Use colorSchemeSeed for easier Material 3 theming
              colorSchemeSeed: Colors.blue,
              brightness: Brightness.light,
              fontFamily: 'Arial', // Consider Noto Sans Arabic
              useMaterial3: true,
              // Add other light theme customizations if needed
            ),
            darkTheme: ThemeData(
              // Define dark theme
              colorSchemeSeed: Colors.blue,
              brightness: Brightness.dark, // Set brightness to dark
              fontFamily: 'Arial', // Consider Noto Sans Arabic
              useMaterial3: true,
              // Add other dark theme customizations if needed
            ),
            locale: settingsProvider.locale, // Use locale from provider
            // TODO: Add localization delegates and supported locales
            // localizationsDelegates: [ ... ],
            // supportedLocales: [ const Locale('en'), const Locale('ar'), ],
            home: homeWidget, // Use the determined initial screen
          );
        },
      ),
    );
  }
}
