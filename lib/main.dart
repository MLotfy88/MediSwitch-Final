import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import Mobile Ads SDK
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'core/di/locator.dart';
import 'data/datasources/local/sqlite_local_data_source.dart'; // Import SqliteLocalDataSource for seeding
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
  // Initialize the Mobile Ads SDK
  MobileAds.instance.initialize();
  // Setup the locator before running the app
  await setupLocator(); // Re-enable locator setup

  // Check if onboarding is complete
  final prefs = await locator.getAsync<SharedPreferences>();
  final bool onboardingComplete =
      prefs.getBool(_prefsKeyOnboardingDone) ?? false;

  // Determine the initial screen
  final Widget initialScreen =
      onboardingComplete ? const MainScreen() : const OnboardingScreen();

  // Seed the database if needed after locator setup
  try {
    final localDataSource = locator<SqliteLocalDataSource>();
    await localDataSource.seedDatabaseFromAssetIfNeeded();
  } catch (e) {
    print("Error during post-locator seeding: $e");
    // Handle seeding error if necessary (e.g., show error screen)
  }

  // Initialize SubscriptionProvider asynchronously in the background
  // locator<SubscriptionProvider>().initialize(); // Keep disabled for now

  // Run the original app structure
  runApp(MyApp(homeWidget: initialScreen));
}

// Restore MyApp structure
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
        ChangeNotifierProvider(
          create: (_) => locator<SettingsProvider>(),
        ), // Keep SettingsProvider
        ChangeNotifierProvider(create: (_) => locator<AlternativesProvider>()),
        ChangeNotifierProvider(
          create: (_) => locator<DoseCalculatorProvider>(),
        ),
        // Temporarily disable InteractionProvider
        // ChangeNotifierProvider(create: (_) => locator<InteractionProvider>()),
        // Keep SubscriptionProvider commented out if disabled in locator
        // ChangeNotifierProvider(create: (_) => locator<SubscriptionProvider>()),
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
              // Light Theme
              brightness: Brightness.light,
              useMaterial3: true,
              fontFamily: 'Noto Sans Arabic', // Set default font
              colorScheme: ColorScheme.fromSeed(
                seedColor:
                    const HSLColor.fromAHSL(
                      1.0,
                      160,
                      0.78,
                      0.40,
                    ).toColor(), // Primary color from CSS --primary
                brightness: Brightness.light,
                background:
                    const HSLColor.fromAHSL(
                      1.0,
                      210,
                      0.40,
                      0.98,
                    ).toColor(), // --background
                onBackground:
                    const HSLColor.fromAHSL(
                      1.0,
                      222.2,
                      0.84,
                      0.049,
                    ).toColor(), // --foreground
                primary:
                    const HSLColor.fromAHSL(
                      1.0,
                      160,
                      0.78,
                      0.40,
                    ).toColor(), // --primary
                onPrimary:
                    const HSLColor.fromAHSL(
                      1.0,
                      210,
                      0.40,
                      0.98,
                    ).toColor(), // --primary-foreground
                secondary:
                    const HSLColor.fromAHSL(
                      1.0,
                      210,
                      0.40,
                      0.961,
                    ).toColor(), // --secondary
                onSecondary:
                    const HSLColor.fromAHSL(
                      1.0,
                      222.2,
                      0.474,
                      0.112,
                    ).toColor(), // --secondary-foreground
                surface:
                    const HSLColor.fromAHSL(
                      1.0,
                      0,
                      0,
                      1.0,
                    ).toColor(), // --card (white)
                onSurface:
                    const HSLColor.fromAHSL(
                      1.0,
                      222.2,
                      0.84,
                      0.049,
                    ).toColor(), // --card-foreground
                error:
                    const HSLColor.fromAHSL(
                      1.0,
                      0,
                      0.842,
                      0.602,
                    ).toColor(), // --destructive
                onError:
                    const HSLColor.fromAHSL(
                      1.0,
                      210,
                      0.40,
                      0.98,
                    ).toColor(), // --destructive-foreground
                tertiary: const Color(0xFF16BC88), // Custom Header Background
                onTertiary: Colors.white, // Custom Header Foreground
              ),
              cardTheme: CardTheme(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(
                    color:
                        const HSLColor.fromAHSL(
                          1.0,
                          214.3,
                          0.318,
                          0.914,
                        ).toColor(),
                  ), // --border
                ),
              ),
              appBarTheme: AppBarTheme(
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor:
                    HSLColor.fromAHSL(
                      1.0,
                      222.2,
                      0.84,
                      0.049,
                    ).toColor(), // Match foreground
              ),
              // Add more theme customizations...
            ),
            darkTheme: ThemeData(
              // Dark Theme
              brightness: Brightness.dark,
              useMaterial3: true,
              fontFamily: 'Noto Sans Arabic',
              colorScheme: ColorScheme.fromSeed(
                seedColor:
                    const HSLColor.fromAHSL(
                      1.0,
                      160,
                      0.78,
                      0.40,
                    ).toColor(), // Primary color
                brightness: Brightness.dark,
                background:
                    const HSLColor.fromAHSL(
                      1.0,
                      222.2,
                      0.22,
                      0.18,
                    ).toColor(), // --background dark
                onBackground:
                    const HSLColor.fromAHSL(
                      1.0,
                      210,
                      0.40,
                      0.98,
                    ).toColor(), // --foreground dark
                primary:
                    const HSLColor.fromAHSL(
                      1.0,
                      160,
                      0.78,
                      0.40,
                    ).toColor(), // --primary dark (same as light?)
                onPrimary:
                    const HSLColor.fromAHSL(
                      1.0,
                      210,
                      0.40,
                      0.98,
                    ).toColor(), // --primary-foreground dark
                secondary:
                    const HSLColor.fromAHSL(
                      1.0,
                      217.2,
                      0.326,
                      0.25,
                    ).toColor(), // --secondary dark
                onSecondary:
                    const HSLColor.fromAHSL(
                      1.0,
                      210,
                      0.40,
                      0.98,
                    ).toColor(), // --secondary-foreground dark
                surface:
                    const HSLColor.fromAHSL(
                      1.0,
                      222.2,
                      0.25,
                      0.14,
                    ).toColor(), // --card dark
                onSurface:
                    const HSLColor.fromAHSL(
                      1.0,
                      210,
                      0.40,
                      0.98,
                    ).toColor(), // --card-foreground dark
                error:
                    const HSLColor.fromAHSL(
                      1.0,
                      0,
                      0.70,
                      0.45,
                    ).toColor(), // --destructive dark
                onError:
                    const HSLColor.fromAHSL(
                      1.0,
                      210,
                      0.40,
                      0.98,
                    ).toColor(), // --destructive-foreground dark
                tertiary: const Color(
                  0xFF16BC88,
                ), // Custom Header Background (same for dark?)
                onTertiary:
                    Colors.white, // Custom Header Foreground (same for dark?)
              ),
              cardTheme: CardTheme(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(
                    color:
                        const HSLColor.fromAHSL(
                          1.0,
                          217.2,
                          0.326,
                          0.25,
                        ).toColor(),
                  ), // --border dark
                ),
                color:
                    const HSLColor.fromAHSL(
                      1.0,
                      222.2,
                      0.25,
                      0.14,
                    ).toColor(), // --card dark
              ),
              appBarTheme: AppBarTheme(
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor:
                    HSLColor.fromAHSL(
                      1.0,
                      210,
                      0.40,
                      0.98,
                    ).toColor(), // Match foreground dark
              ),
              // Add more theme customizations...
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
