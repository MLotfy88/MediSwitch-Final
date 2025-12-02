import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for date formatting initialization
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/locator.dart';
import 'core/services/file_logger_service.dart';
import 'data/datasources/local/sqlite_local_data_source.dart';
import 'presentation/bloc/medicine_provider.dart';
import 'presentation/bloc/settings_provider.dart';
import 'presentation/bloc/alternatives_provider.dart';
import 'presentation/bloc/dose_calculator_provider.dart';
import 'presentation/bloc/interaction_provider.dart';
import 'presentation/bloc/subscription_provider.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/initialization_screen.dart'; // Import InitializationScreen
import 'package:flutter_localizations/flutter_localizations.dart'; // Added for localization
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Added for generated localizations
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

// Helper function to build ThemeData
// Helper function to build ThemeData
ThemeData _buildThemeData(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;

  // Define HSL colors based on brightness - IMPROVED CONTRAST
  final background =
      isDark
          ? const HSLColor.fromAHSL(1.0, 222.2, 0.22, 0.10) // Darker background (L=0.10)
          : const HSLColor.fromAHSL(1.0, 210, 0.20, 0.98); // Off-white background (L=0.98)
  final foreground =
      isDark
          ? const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98)
          : const HSLColor.fromAHSL(1.0, 222.2, 0.84, 0.049);
  final card =
      isDark
          ? const HSLColor.fromAHSL(1.0, 222.2, 0.25, 0.18) // Lighter card (L=0.18) for contrast
          : const HSLColor.fromAHSL(1.0, 0, 0, 1.0); // Pure white card
  final cardForeground =
      isDark
          ? const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98)
          : const HSLColor.fromAHSL(1.0, 222.2, 0.84, 0.049);
  final primary = const HSLColor.fromAHSL(
    1.0,
    160,
    0.78,
    0.40,
  ); // Same for both modes
  final primaryForeground = const HSLColor.fromAHSL(
    1.0,
    210,
    0.40,
    0.98,
  ); // Same for both modes
  final secondary =
      isDark
          ? const HSLColor.fromAHSL(1.0, 217.2, 0.326, 0.25)
          : const HSLColor.fromAHSL(1.0, 210, 0.40, 0.961);
  final secondaryForeground =
      isDark
          ? const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98)
          : const HSLColor.fromAHSL(1.0, 222.2, 0.474, 0.112);
  final muted =
      isDark
          ? const HSLColor.fromAHSL(1.0, 217.2, 0.326, 0.25)
          : const HSLColor.fromAHSL(1.0, 210, 0.40, 0.961);
  final mutedForeground =
      isDark
          ? const HSLColor.fromAHSL(
            1.0,
            215,
            0.25,
            0.70, // Slightly dimmer than main text
          )
          : const HSLColor.fromAHSL(
            1.0,
            215.4,
            0.16,
            0.40, // Slightly dimmer than main text
          );
  final accent =
      isDark
          ? const HSLColor.fromAHSL(1.0, 217.2, 0.326, 0.25)
          : const HSLColor.fromAHSL(1.0, 210, 0.40, 0.961);
  final accentForeground =
      isDark
          ? const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98)
          : const HSLColor.fromAHSL(1.0, 222.2, 0.47, 0.11);
  final destructive =
      isDark
          ? const HSLColor.fromAHSL(1.0, 0, 0.70, 0.45)
          : const HSLColor.fromAHSL(1.0, 0, 0.84, 0.60);
  final destructiveForeground = const HSLColor.fromAHSL(
    1.0,
    210,
    0.40,
    0.98,
  ); // Same for both modes
  final border =
      isDark
          ? const HSLColor.fromAHSL(1.0, 217.2, 0.326, 0.25)
          : const HSLColor.fromAHSL(1.0, 214.3, 0.31, 0.91);
  final input =
      isDark
          ? const HSLColor.fromAHSL(1.0, 217.2, 0.326, 0.25)
          : const HSLColor.fromAHSL(1.0, 214.3, 0.31, 0.91);
  final ring =
      isDark
          ? const HSLColor.fromAHSL(1.0, 212.7, 0.26, 0.83)
          : const HSLColor.fromAHSL(1.0, 160, 0.78, 0.40);
  final headerBackground = const Color(0xFF16BC88); // Fixed color for header

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: primary.toColor(),
    onPrimary: primaryForeground.toColor(),
    secondary: secondary.toColor(),
    onSecondary: secondaryForeground.toColor(),
    error: destructive.toColor(),
    onError: destructiveForeground.toColor(),
    background: background.toColor(),
    onBackground: foreground.toColor(),
    surface: card.toColor(), // Use card color for surface
    onSurface: cardForeground.toColor(), // Use card foreground for onSurface
    // Map other colors as needed, potentially using tertiary, surfaceVariant etc.
    surfaceVariant: muted.toColor(), // Example mapping
    onSurfaceVariant: mutedForeground.toColor(), // Example mapping
    outline: border.toColor(),
    shadow: Colors.black.withOpacity(0.1), // Default shadow
    inverseSurface: foreground.toColor(), // Example mapping
    onInverseSurface: background.toColor(), // Example mapping
    primaryContainer:
        primary
            .withLightness(primary.lightness * (isDark ? 1.2 : 0.9))
            .toColor(), // Example adjustment
    onPrimaryContainer: primaryForeground.toColor(),
    secondaryContainer:
        secondary
            .withLightness(secondary.lightness * (isDark ? 1.2 : 0.9))
            .toColor(), // Example adjustment
    onSecondaryContainer: secondaryForeground.toColor(),
    tertiary: headerBackground, // Use fixed header color for tertiary
    onTertiary: Colors.white, // Fixed white text on header
    errorContainer:
        destructive
            .withLightness(destructive.lightness * (isDark ? 1.2 : 0.9))
            .toColor(),
    onErrorContainer: destructiveForeground.toColor(),
    surfaceTint: primary.toColor(), // Often same as primary
  );

  // Define TextTheme based on Material 3 scale
  final textTheme = TextTheme(
    // Define styles as needed, inheriting from the base font family
    // Example: Adjusting bodyLarge for demonstration
    // bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
    // titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
    // labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.normal),
    // Add other styles if specific overrides are required
  ).apply(
    fontFamily: 'Noto Sans Arabic', // Ensure font family is applied
    bodyColor: colorScheme.onSurface, // Default text color
    displayColor: colorScheme.onSurface.withOpacity(
      0.8,
    ), // Slightly muted for display
  );

  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    fontFamily: 'Noto Sans Arabic', // Base font family
    colorScheme: colorScheme,
    textTheme: textTheme, // Apply the defined text theme
    scaffoldBackgroundColor: colorScheme.background,
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // --radius: 0.75rem ~ 12px
        side: BorderSide(
          color: colorScheme.outline,
        ), // Use outline color for border
      ),
      color: colorScheme.surface, // Use surface color for card background
      clipBehavior: Clip.antiAlias, // Good practice
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      // Use tertiary for the specific header background color
      backgroundColor: colorScheme.tertiary,
      foregroundColor: colorScheme.onTertiary, // White text on header
      iconTheme: IconThemeData(color: colorScheme.onTertiary),
      titleTextStyle: TextStyle(
        // Use the defined textTheme style if appropriate, or keep specific override
        // Example: style: textTheme.headlineSmall?.copyWith(color: colorScheme.onTertiary),
        color: colorScheme.onTertiary,
        fontSize: 20, // Keep specific override for AppBar title
        fontWeight: FontWeight.bold,
        fontFamily: 'Noto Sans Arabic', // Ensure font family if not inheriting
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(
        0.5,
      ), // Use muted/surfaceVariant for input background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0), // Match search bar radius
        borderSide: BorderSide.none, // No border by default
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 1.5,
        ), // Ring color on focus
      ),
      // Use textTheme style for hints if desired
      // Example: hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
      hintStyle: TextStyle(
        // Keep specific override for hint style
        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 10.0,
        horizontal: 16.0,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface, // Card color
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(
        0.7,
      ), // Muted foreground
      elevation: 8.0, // Add some elevation
      type: BottomNavigationBarType.fixed, // Ensure labels are always shown
      // Use textTheme styles for labels
      selectedLabelStyle: textTheme.labelMedium?.copyWith(
        // fontSize: 12, // Inherited from textTheme.labelMedium potentially
        fontWeight: FontWeight.w500, // Keep specific weight override
      ),
      unselectedLabelStyle: textTheme.labelMedium?.copyWith(
        // fontSize: 12, // Inherited from textTheme.labelMedium potentially
      ),
    ),
    // Add other component themes as needed (Buttons, Switches, etc.)
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color?>((
        Set<MaterialState> states,
      ) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.primary;
        }
        return null; // Use default
      }),
      trackColor: MaterialStateProperty.resolveWith<Color?>((
        Set<MaterialState> states,
      ) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.primary.withOpacity(0.5);
        }
        return null; // Use default
      }),
      trackOutlineColor: MaterialStateProperty.resolveWith<Color?>((
        Set<MaterialState> states,
      ) {
        return colorScheme.outline.withOpacity(0.5);
      }),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: colorScheme.secondary,
      textColor: colorScheme.onSecondary,
      smallSize: 6,
      largeSize: 16,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
  );
}

// Original MyApp structure
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
            theme: _buildThemeData(Brightness.light), // Use helper function
            darkTheme: _buildThemeData(Brightness.dark), // Use helper function
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
