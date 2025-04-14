import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/locator.dart';
import 'core/services/file_logger_service.dart'; // Import FileLoggerService
import 'data/datasources/local/sqlite_local_data_source.dart';
import 'presentation/bloc/medicine_provider.dart';
import 'presentation/bloc/settings_provider.dart';
import 'presentation/bloc/alternatives_provider.dart';
import 'presentation/bloc/dose_calculator_provider.dart';
import 'presentation/bloc/interaction_provider.dart';
import 'presentation/bloc/subscription_provider.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/onboarding_screen.dart';

const String _prefsKeyOnboardingDone = 'onboarding_complete';

Future<void> main() async {
  FileLoggerService? logger; // Make nullable initially

  try {
    // Initialize Flutter binding first
    WidgetsFlutterBinding.ensureInitialized();
    print("main: WidgetsFlutterBinding initialized."); // Console print

    // Initialize Logger immediately after binding
    logger = FileLoggerService();
    await logger.initialize(); // Initialize file logger
    logger.i("main: FileLoggerService initialized.");

    // Register the initialized logger instance immediately (optional but good practice)
    // This assumes locator itself doesn't depend on async logger init
    if (!locator.isRegistered<FileLoggerService>()) {
      locator.registerSingleton<FileLoggerService>(logger);
      logger.i("main: FileLoggerService registered in locator.");
    }

    logger.i("main: Initializing Mobile Ads SDK...");
    MobileAds.instance.initialize();
    logger.i("main: Mobile Ads SDK initialized.");

    logger.i("main: Calling setupLocator...");
    await setupLocator(); // Setup other dependencies (will use registered logger)
    logger.i("main: setupLocator finished.");

    logger.i("main: Checking onboarding status...");
    final prefs = await locator.getAsync<SharedPreferences>();
    final bool onboardingComplete =
        prefs.getBool(_prefsKeyOnboardingDone) ?? false;
    logger.i("main: Onboarding complete: $onboardingComplete");

    final Widget initialScreen =
        onboardingComplete ? const MainScreen() : const OnboardingScreen();
    logger.i("main: Initial screen determined: ${initialScreen.runtimeType}");

    logger.i("main: Attempting database seeding if needed...");
    try {
      final localDataSource = locator<SqliteLocalDataSource>();
      await localDataSource.seedDatabaseFromAssetIfNeeded();
      logger.i("main: Database seeding check complete.");
    } catch (e, s) {
      logger.e("main: Error during post-locator seeding", e, s);
    }

    logger.i("main: Initializing SubscriptionProvider asynchronously...");
    locator<SubscriptionProvider>().initialize();

    logger.i("main: Running MyApp...");
    runApp(MyApp(homeWidget: initialScreen));
    logger.i("main: runApp called successfully.");
  } catch (e, stackTrace) {
    final errorMsg = "FATAL ERROR in main";
    print("$errorMsg: $e\n$stackTrace"); // Console fallback
    // Try logging to file
    logger?.f(errorMsg, e, stackTrace);
    // Ensure the app closes or shows an error screen if possible
    runApp(
      ErrorMaterialApp(error: e, stackTrace: stackTrace),
    ); // Show error screen
  }
}

// Original MyApp structure (ensure all providers are re-enabled here)
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
            theme: ThemeData(
              brightness: Brightness.light,
              useMaterial3: true,
              fontFamily: 'Noto Sans Arabic',
              colorScheme: ColorScheme.fromSeed(
                seedColor:
                    const HSLColor.fromAHSL(1.0, 160, 0.78, 0.40).toColor(),
                brightness: Brightness.light,
                background:
                    const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98).toColor(),
                onBackground:
                    const HSLColor.fromAHSL(1.0, 222.2, 0.84, 0.049).toColor(),
                primary:
                    const HSLColor.fromAHSL(1.0, 160, 0.78, 0.40).toColor(),
                onPrimary:
                    const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98).toColor(),
                secondary:
                    const HSLColor.fromAHSL(1.0, 210, 0.40, 0.961).toColor(),
                onSecondary:
                    const HSLColor.fromAHSL(1.0, 222.2, 0.474, 0.112).toColor(),
                surface: const HSLColor.fromAHSL(1.0, 0, 0, 1.0).toColor(),
                onSurface:
                    const HSLColor.fromAHSL(1.0, 222.2, 0.84, 0.049).toColor(),
                error: const HSLColor.fromAHSL(1.0, 0, 0.842, 0.602).toColor(),
                onError:
                    const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98).toColor(),
                tertiary: const Color(0xFF16BC88),
                onTertiary: Colors.white,
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
                  ),
                ),
              ),
              appBarTheme: AppBarTheme(
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor:
                    HSLColor.fromAHSL(1.0, 222.2, 0.84, 0.049).toColor(),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              useMaterial3: true,
              fontFamily: 'Noto Sans Arabic',
              colorScheme: ColorScheme.fromSeed(
                seedColor:
                    const HSLColor.fromAHSL(1.0, 160, 0.78, 0.40).toColor(),
                brightness: Brightness.dark,
                background:
                    const HSLColor.fromAHSL(1.0, 222.2, 0.22, 0.18).toColor(),
                onBackground:
                    const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98).toColor(),
                primary:
                    const HSLColor.fromAHSL(1.0, 160, 0.78, 0.40).toColor(),
                onPrimary:
                    const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98).toColor(),
                secondary:
                    const HSLColor.fromAHSL(1.0, 217.2, 0.326, 0.25).toColor(),
                onSecondary:
                    const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98).toColor(),
                surface:
                    const HSLColor.fromAHSL(1.0, 222.2, 0.25, 0.14).toColor(),
                onSurface:
                    const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98).toColor(),
                error: const HSLColor.fromAHSL(1.0, 0, 0.70, 0.45).toColor(),
                onError:
                    const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98).toColor(),
                tertiary: const Color(0xFF16BC88),
                onTertiary: Colors.white,
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
                  ),
                ),
                color:
                    const HSLColor.fromAHSL(1.0, 222.2, 0.25, 0.14).toColor(),
              ),
              appBarTheme: AppBarTheme(
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor:
                    HSLColor.fromAHSL(1.0, 210, 0.40, 0.98).toColor(),
              ),
            ),
            locale: settingsProvider.locale,
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
