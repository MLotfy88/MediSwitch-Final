import 'package:flutter/material.dart';

/// Application colors
class AppColors {
  // Medical Blue Primary Palette
  /// Primary color
  static const Color primary = Color(0xFF0D6EBC); // hsl(210, 90%, 45%)
  /// Primary light color
  static const Color primaryLight = Color(0xFF2D8FDB); // hsl(210, 85%, 55%)
  static const Color primaryDark = Color(0xFF0456A0); // hsl(210, 95%, 35%)
  static const Color primaryForeground = Colors.white;

  // Secondary - Teal Accent
  static const Color secondary = Color(0xFF2EB3B8); // hsl(185, 60%, 45%)
  static const Color secondaryForeground = Colors.white;

  // Background & Surface
  static const Color background = Color(0xFFF7F9FA); // hsl(210, 20%, 98%)
  static const Color foreground = Color(0xFF1C2530); // hsl(215, 25%, 15%)
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Colors.white;

  // Card
  static const Color card = Colors.white;
  static const Color cardForeground = Color(0xFF1C2530);

  // Muted
  static const Color muted = Color(0xFFEBEEF1); // hsl(210, 15%, 93%)
  static const Color mutedForeground = Color(0xFF6E7A89); // hsl(215, 15%, 50%)

  // Accent
  static const Color accent = Color(0xFFEEF3F8); // hsl(210, 30%, 95%)
  static const Color accentForeground = Color(0xFF0963AB); // hsl(210, 90%, 40%)

  // Semantic Colors
  static const Color danger = Color(0xFFDF4545); // hsl(0, 75%, 55%)
  static const Color dangerSoft = Color(0xFFFCEBEB); // hsl(0, 70%, 95%)
  static const Color dangerForeground = Colors.white;

  static const Color warning = Color(0xFFF79E0E); // hsl(38, 95%, 50%)
  static const Color warningSoft = Color(0xFFFEF6E6); // hsl(38, 90%, 95%)
  static const Color warningForeground = Color(0xFF4F3103);

  static const Color success = Color(0xFF2BA36F); // hsl(150, 60%, 42%)
  static const Color successSoft = Color(0xFFE8F7EF); // hsl(150, 55%, 94%)
  static const Color successForeground = Colors.white;

  static const Color info = Color(0xFF1AA3E6); // hsl(200, 80%, 50%)
  static const Color infoSoft = Color(0xFFE6F6FD); // hsl(200, 80%, 95%)

  static const Color border = Color(0xFFE3E8EC); // hsl(210, 20%, 90%)
  static const Color input = Color(0xFFE3E8EC);

  // Shadows
  /// Small shadow
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: const Color(
        0xFF0F172A,
      ).withValues(alpha: 0.04), // hsl(215 25% 15% / 0.04)
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: const Color(
        0xFF0F172A,
      ).withValues(alpha: 0.08), // hsl(215 25% 15% / 0.08)
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get shadowCard => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
      offset: const Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 1,
    ),
  ];
}
