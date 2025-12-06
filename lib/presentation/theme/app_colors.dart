import 'package:flutter/material.dart';

class AppColors {
  // Medical Blue Primary Palette
  static const Color primary = Color(0xFF0B73DA); // hsl(210, 90%, 45%)
  static const Color primaryLight = Color(
    0xFF4C9AFF,
  ); // hsl(210, 100%, 65%) - Tuned for light
  static const Color primaryDark = Color(0xFF074E96); // hsl(210, 95%, 35%)
  static const Color primaryForeground = Colors.white;

  // Secondary - Teal Accent
  static const Color secondary = Color(0xFF2EAEB7); // hsl(185, 60%, 45%)
  static const Color secondaryForeground = Colors.white;

  // Background & Surface
  static const Color background = Color(0xFFF8FAFC); // hsl(210, 20%, 98%)
  static const Color foreground = Color(0xFF1E293B); // hsl(215, 25%, 15%)
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Colors.white;

  // Card
  static const Color card = Colors.white;
  static const Color cardForeground = Color(0xFF1E293B);

  // Muted
  static const Color muted = Color(0xFFF1F5F9); // hsl(210, 40%, 96.1%)
  static const Color mutedForeground = Color(0xFF64748B); // hsl(215, 16%, 47%)

  // Accent
  static const Color accent = Color(0xFFF1F5F9); // hsl(210, 40%, 96.1%)
  static const Color accentForeground = Color(
    0xFF0F172A,
  ); // hsl(222, 47%, 11.2%)

  // Semantic Colors
  static const Color danger = Color(0xFFEF4444); // hsl(0, 84%, 60%)
  static const Color dangerSoft = Color(0xFFFEF2F2); // hsl(0, 85%, 97%)
  static const Color dangerForeground = Colors.white;

  static const Color warning = Color(0xFFF59E0B); // hsl(45, 93%, 47%)
  static const Color warningSoft = Color(0xFFFFFBEB); // hsl(45, 100%, 96%)
  static const Color warningForeground = Color(0xFFFFFBEB);

  static const Color success = Color(
    0xFF10B981,
  ); // hsl(161, 93%, 30%) - adjusted for contrast
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color successForeground = Colors.white;

  static const Color info = Color(0xFF0EA5E9); // hsl(199, 89%, 48%)
  static const Color infoSoft = Color(0xFFF0F9FF);

  static const Color border = Color(0xFFE2E8F0); // hsl(214, 32%, 91%)
  static const Color input = Color(0xFFE2E8F0);

  // Shadows
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: const Color(
        0xFF0F172A,
      ).withOpacity(0.04), // hsl(215 25% 15% / 0.04)
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: const Color(
        0xFF0F172A,
      ).withOpacity(0.08), // hsl(215 25% 15% / 0.08)
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get shadowCard => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.06),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: const Color(0xFFE2E8F0).withOpacity(0.8),
      offset: const Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 1,
    ),
  ];
}
