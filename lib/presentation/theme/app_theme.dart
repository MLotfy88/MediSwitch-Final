import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';

/// Application theme configuration
class AppTheme {
  /// Light theme data
  static ThemeData get light {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
    );

    return baseTheme.copyWith(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        onSecondary: AppColors.secondaryForeground,
        surface: AppColors.surface,
        onSurface: AppColors.foreground,
        error: AppColors.danger,
        onError: AppColors.dangerForeground,
        outline: AppColors.border,
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        bodyColor: AppColors.foreground,
        displayColor: AppColors.foreground,
        fontFamilyFallback: [GoogleFonts.cairo().fontFamily!],
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14), // .rounded-xl
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.mutedForeground),
      ),
      extensions: [AppColorsExtension.light],
    );
  }

  /// Dark theme data
  static ThemeData get dark {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF3B82F6), // HSL(210, 80%, 55%)
      scaffoldBackgroundColor: const Color(0xFF131720), // HSL(220, 25%, 10%)
    );

    const darkSurface = Color(0xFF1C212B); // HSL(220, 20%, 14%)
    const darkForeground = Color(0xFFE2E8F0); // HSL(210, 20%, 95%)

    return baseTheme.copyWith(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF3B82F6),
        onPrimary: Colors.white,
        secondary: Color(0xFF2EAEB7), // Keeping teal
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: darkForeground,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        outline: Color(0xFF2D3748), // Darker border
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        bodyColor: darkForeground,
        displayColor: darkForeground,
        fontFamilyFallback: [GoogleFonts.cairo().fontFamily!],
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF131720),
        foregroundColor: darkForeground,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2D3748), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        hintStyle: TextStyle(color: darkForeground.withValues(alpha: 0.5)),
      ),
      extensions: [AppColorsExtension.dark],
    );
  }
}
