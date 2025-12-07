import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Added for generated localizations
import 'package:flutter_localizations/flutter_localizations.dart'; // Added for localization
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for date formatting initialization
import 'package:provider/provider.dart';

import 'core/di/locator.dart';
import 'core/services/file_logger_service.dart';
import 'domain/repositories/interaction_repository.dart'; // Import InteractionRepository interface
import 'presentation/bloc/ad_config_provider.dart';
import 'presentation/bloc/alternatives_provider.dart';
import 'presentation/bloc/dose_calculator_provider.dart';
import 'presentation/bloc/interaction_provider.dart';
import 'presentation/bloc/medicine_provider.dart';
import 'presentation/bloc/settings_provider.dart';
import 'presentation/bloc/subscription_provider.dart';
import 'presentation/screens/initialization_screen.dart'; // Import InitializationScreen
import 'presentation/theme/app_theme.dart';
// Remove unused imports
// import 'presentation/screens/onboarding_screen.dart';
// import 'presentation/screens/setup_screen.dart';
// import 'presentation/screens/main_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'data/datasources/local/sqlite_local_data_source.dart';

// Keys moved to InitializationScreen
// const String _prefsKeyOnboardingDone = 'onboarding_complete';
// const String _prefsKeyFirstLaunchDone = 'first_launch_done';

Future<void> main() async {
  // --- Early Log Attempt 1 ---
  // Try initializing a temporary logger *before* locator setup
  // This helps if locator setup itself fails silently.
  final earlyLogger = FileLoggerService();
  await earlyLogger.initialize(); // Initialize it immediately
  earlyLogger.i("main: >>> ENTERING main() <<<");
  // --- End Early Log Attempt 1 ---

  WidgetsFlutterBinding.ensureInitialized();
  FileLoggerService? logger; // Keep this for later use after locator setup

  try {
    // Initialize date formatting for the default locale
    await initializeDateFormatting(
      'en',
      null,
    ); // Explicitly initialize for 'en' locale
    // Log after initialization attempt (using early logger as locator isn't ready yet)
    earlyLogger.i("main: Date formatting initialized.");
    await setupLocator();
    // Assign the fully initialized logger from the locator
    // The instance in the locator should be the same as earlyLogger if setup succeeded
    logger = locator<FileLoggerService>();
    logger.i("main: Locator setup complete. Logger obtained.");
    logger.i("main: Starting application setup...");

    logger.i("main: Initializing Mobile Ads SDK...");
    MobileAds.instance.initialize();
    logger.i("main: Mobile Ads SDK initialized.");

    // REMOVED: Routing logic moved to InitializationScreen
    // logger.i("main: Checking onboarding status...");
    // final prefs = await locator.getAsync<SharedPreferences>();
    // final bool onboardingComplete =
    //     prefs.getBool(_prefsKeyOnboardingDone) ?? false;
    // logger.i("main: Onboarding complete: $onboardingComplete");
    // final bool firstLaunchDone =
    //     prefs.getBool(_prefsKeyFirstLaunchDone) ?? false;
    // logger.i("main: First launch done: $firstLaunchDone");
    // Widget initialScreen;
    // if (!onboardingComplete) {
    //   logger.i("main: Routing to OnboardingScreen.");
    //   initialScreen = const OnboardingScreen();
    //   locator<SqliteLocalDataSource>().markSeedingAsComplete();
    // } else if (!firstLaunchDone) {
    //   logger.i("main: First launch after onboarding. Routing to SetupScreen.");
    //   initialScreen = const SetupScreen();
    //   // REMOVED: Premature setting of first launch flag
    //   // await prefs.setBool(_prefsKeyFirstLaunchDone, true);
    //   // logger.i("main: Set first launch flag to true.");
    // } else {
    //   logger.i("main: Subsequent launch. Routing to MainScreen.");
    //   initialScreen = const MainScreen();
    //   logger.i("main: Marking seeding as complete for non-first launch.");
    //   locator<SqliteLocalDataSource>().markSeedingAsComplete();
    // }
    // logger.i("main: Initial screen determined: ${initialScreen.runtimeType}");

    // REMOVED: Seeding logic is now handled by SetupScreen.
    // // logger.i("main: Attempting database seeding if needed...");
    // // try {
    //   final localDataSource = locator<SqliteLocalDataSource>();
    //   await localDataSource.seedDatabaseFromAssetIfNeeded();
    //   logger.i("main: Database seeding check complete.");
    // } catch (e, s) {
    //   logger.e("main: Error during post-locator seeding", e, s);
    // }

    logger.i("main: Initializing SubscriptionProvider asynchronously...");
    locator<SubscriptionProvider>().initialize();

    logger.i("main: Preloading interaction data...");
    try {
      await locator<InteractionRepository>().loadInteractionData();
      logger.i("main: Interaction data loaded successfully.");
    } catch (e, s) {
      logger.e("main: Failed to load interaction data", e, s);
    }

    logger.i("main: Setup complete. Preparing to run MyApp...");
    // Always start with InitializationScreen, which handles the routing logic.
    logger.i("main: Setting InitializationScreen as initial route.");
    logger.i("main: >>> CALLING runApp() NOW <<<");
    runApp(const MyApp(homeWidget: InitializationScreen()));
    // Note: Logs after runApp might not execute if runApp itself fails critically
    logger.i(
      "main: runApp called successfully (or at least the call was made).",
    );
  } catch (e, stackTrace) {
    final errorMsg = "FATAL ERROR in main";
    print("$errorMsg: $e\n$stackTrace");
    logger?.f(errorMsg, e, stackTrace);
    runApp(ErrorMaterialApp(error: e, stackTrace: stackTrace));
  }
}

class MyApp extends StatelessWidget {
  final Widget homeWidget;

  const MyApp({super.key, required this.homeWidget});

  @override
  Widget build(BuildContext context) {
    final logger = locator<FileLoggerService>();
    logger.i("MyApp: Building widget tree...");
    return MultiProvider(
      providers: [
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
        ChangeNotifierProvider(
          create: (_) {
            logger.d("MyApp: Creating AdConfigProvider...");
            return locator<AdConfigProvider>();
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          logger.d(
            "MyApp: Consumer<SettingsProvider> builder running. Initialized: ${settingsProvider.isInitialized}",
          );
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
          return MaterialApp(
            title: 'MediSwitch',
            debugShowCheckedModeBanner: false,
            themeMode: settingsProvider.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            locale: settingsProvider.locale,
            // Added localization delegates and supported locales
            localizationsDelegates: const [
              AppLocalizations.delegate, // Generated delegate
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ar'), // Arabic
            ],
            home: homeWidget,
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
