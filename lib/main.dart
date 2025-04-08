import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/locator.dart'; // Import the locator
import 'presentation/bloc/medicine_provider.dart';
import 'presentation/bloc/settings_provider.dart';
import 'presentation/bloc/alternatives_provider.dart'; // Import for global provider
import 'presentation/bloc/dose_calculator_provider.dart'; // Import for global provider
import 'presentation/bloc/interaction_provider.dart'; // Import for global provider
import 'presentation/screens/main_screen.dart';

// Make main async
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Setup the locator before running the app
  await setupLocator();
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // No longer need to accept use cases via constructor
  const MyApp({super.key});

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
            home: const MainScreen(), // Ensure MainScreen is correctly imported
          );
        },
      ),
    );
  }
}
