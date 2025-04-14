import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import Mobile Ads SDK
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'core/di/locator.dart';
import 'core/services/file_logger_service.dart'; // Import FileLoggerService
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
  WidgetsFlutterBinding.ensureInitialized();
  FileLoggerService? logger; // Make logger nullable initially

  try {
    // Initialize locator first as it now includes logger init.
    await setupLocator(); // Use the full locator setup
    logger = locator<FileLoggerService>();
    logger.i("main: Starting application setup...");

    // Initialize Mobile Ads SDK
    logger.i("main: Initializing Mobile Ads SDK...");
    MobileAds.instance.initialize(); // Re-enable Mobile Ads initialization
    logger.i("main: Mobile Ads SDK initialized.");

    // Check if onboarding is complete
    logger.i("main: Checking onboarding status...");
    final prefs = await locator.getAsync<SharedPreferences>();
    final bool onboardingComplete =
        prefs.getBool(_prefsKeyOnboardingDone) ?? false;
    logger.i("main: Onboarding complete: $onboardingComplete");

    // Determine the initial screen
    final Widget initialScreen =
        onboardingComplete ? const MainScreen() : const OnboardingScreen();
    logger.i("main: Initial screen determined: ${initialScreen.runtimeType}");

    // Seed the database if needed after locator setup
    logger.i("main: Attempting database seeding if needed...");
    try {
      final localDataSource = locator<SqliteLocalDataSource>();
      await localDataSource
          .seedDatabaseFromAssetIfNeeded(); // Re-enable seeding
      logger.i("main: Database seeding check complete.");
    } catch (e, s) {
      logger.e(
        "main: Error during post-locator seeding",
        e,
        s,
      ); // Correct parameters
      // Handle seeding error if necessary (e.g., show error screen or default data)
    }

    // Initialize SubscriptionProvider asynchronously in the background
    logger.i("main: Initializing SubscriptionProvider asynchronously...");
    locator<SubscriptionProvider>().initialize(); // Re-enable initialization

    // Run the original app structure
    logger.i("main: Running MyApp...");
    runApp(MyApp(homeWidget: initialScreen)); // Use original MyApp
    logger.i("main: runApp called successfully.");
  } catch (e, stackTrace) {
    // Log any top-level errors that occur before or during runApp
    final errorMsg = "FATAL ERROR in main";
    print("$errorMsg: $e\n$stackTrace"); // Print to console as fallback
    // Try logging to file if logger initialized, otherwise this might fail too
    logger?.f(errorMsg, e, stackTrace); // Use correct parameters and null check
    // Ensure the app closes or shows an error screen if possible
    runApp(
      ErrorMaterialApp(error: e, stackTrace: stackTrace),
    ); // Show error screen
  }
}

// Original MyApp structure
class MyApp extends StatelessWidget {
  final Widget homeWidget; // Add field to hold the initial widget

  const MyApp({super.key, required this.homeWidget});

  @override
  Widget build(BuildContext context) {
    final logger = locator<FileLoggerService>();
    logger.i("MyApp: Building widget tree...");
    // Wrap with MultiProvider to provide multiple providers
    return MultiProvider(
      providers: [
        // Provide all necessary Providers using the locator
        ChangeNotifierProvider(
          create: (_) {
            logger.d("MyApp: Creating MedicineProvider...");
            return locator<MedicineProvider>();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            logger.d("MyApp: Creating SettingsProvider...");
            return locator<SettingsProvider>();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            logger.d("MyApp: Creating AlternativesProvider...");
            return locator<AlternativesProvider>();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            logger.d("MyApp: Creating DoseCalculatorProvider...");
            return locator<DoseCalculatorProvider>();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            logger.d("MyApp: Creating InteractionProvider...");
            return locator<InteractionProvider>();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            logger.d("MyApp: Creating SubscriptionProvider...");
            return locator<SubscriptionProvider>();
          },
        ),
      ],
      // Consumer is needed here to access SettingsProvider for theme/locale
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          logger.d(
            "MyApp: Consumer<SettingsProvider> builder running. Initialized: ${settingsProvider.isInitialized}",
          );
          // Show loading indicator until settings are loaded
          if (!settingsProvider.isInitialized) {
            logger.v(
              "MyApp: SettingsProvider not initialized, showing loading indicator.",
            );
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          logger.v(
            "MyApp: SettingsProvider initialized, building main MaterialApp.",
          );
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

// Simple error screen to display if main fails catastrophically
class ErrorMaterialApp extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  const ErrorMaterialApp({super.key, required this.error, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Application failed to start.\nError: $error\n\nStackTrace: $stackTrace',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
  }
}
