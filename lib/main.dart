import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
import 'presentation/screens/onboarding_screen.dart';

const String _prefsKeyOnboardingDone = 'onboarding_complete';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FileLoggerService? logger;

  try {
    await setupLocator();
    logger = locator<FileLoggerService>();
    logger.i("main: Starting application setup...");

    logger.i("main: Initializing Mobile Ads SDK...");
    MobileAds.instance.initialize();
    logger.i("main: Mobile Ads SDK initialized.");

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
    print("$errorMsg: $e\n$stackTrace");
    logger?.f(errorMsg, e, stackTrace);
    runApp(ErrorMaterialApp(error: e, stackTrace: stackTrace));
  }
}

// Helper function to build ThemeData
ThemeData _buildThemeData(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;

  // Define HSL colors based on brightness
  final background =
      isDark
          ? const HSLColor.fromAHSL(1.0, 222.2, 0.22, 0.18)
          : const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98);
  final foreground =
      isDark
          ? const HSLColor.fromAHSL(1.0, 210, 0.40, 0.98)
          : const HSLColor.fromAHSL(1.0, 222.2, 0.84, 0.049);
  final card =
      isDark
          ? const HSLColor.fromAHSL(1.0, 222.2, 0.25, 0.14)
          : const HSLColor.fromAHSL(1.0, 0, 0, 1.0);
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
          ? const HSLColor.fromAHSL(1.0, 215, 0.25, 0.70)
          : const HSLColor.fromAHSL(1.0, 215.4, 0.16, 0.46);
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

  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    fontFamily: 'Noto Sans Arabic',
    colorScheme: colorScheme,
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
        color: colorScheme.onTertiary,
        fontSize: 20, // Adjust as needed
        fontWeight: FontWeight.bold,
        fontFamily: 'Noto Sans Arabic',
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
      hintStyle: TextStyle(
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
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
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
            // TODO: Add localization delegates and supported locales
            // localizationsDelegates: [ ... ],
            // supportedLocales: [ const Locale('en'), const Locale('ar'), ],
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
