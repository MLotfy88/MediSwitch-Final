import 'package:flutter/material.dart';

/// Theme Extension for custom colors
/// Provides additional colors beyond Material 3 ColorScheme
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color dangerSoft;
  final Color successSoft;
  final Color warningSoft;
  final Color infoSoft;
  final Color accent;
  final Color mutedForeground;
  final Color dangerForeground;
  final Color successForeground;
  final Color warningForeground;
  final Color infoForeground;

  const AppColorsExtension({
    required this.dangerSoft,
    required this.successSoft,
    required this.warningSoft,
    required this.infoSoft,
    required this.accent,
    required this.mutedForeground,
    required this.dangerForeground,
    required this.successForeground,
    required this.warningForeground,
    required this.infoForeground,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? dangerSoft,
    Color? successSoft,
    Color? warningSoft,
    Color? infoSoft,
    Color? accent,
    Color? mutedForeground,
    Color? dangerForeground,
    Color? successForeground,
    Color? warningForeground,
    Color? infoForeground,
  }) {
    return AppColorsExtension(
      dangerSoft: dangerSoft ?? this.dangerSoft,
      successSoft: successSoft ?? this.successSoft,
      warningSoft: warningSoft ?? this.warningSoft,
      infoSoft: infoSoft ?? this.infoSoft,
      accent: accent ?? this.accent,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      dangerForeground: dangerForeground ?? this.dangerForeground,
      successForeground: successForeground ?? this.successForeground,
      warningForeground: warningForeground ?? this.warningForeground,
      infoForeground: infoForeground ?? this.infoForeground,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      dangerForeground:
          Color.lerp(dangerForeground, other.dangerForeground, t)!,
      successForeground:
          Color.lerp(successForeground, other.successForeground, t)!,
      warningForeground:
          Color.lerp(warningForeground, other.warningForeground, t)!,
      infoForeground: Color.lerp(infoForeground, other.infoForeground, t)!,
    );
  }

  // Light theme colors
  static const light = AppColorsExtension(
    dangerSoft: Color(0xFFFEF2F2), // danger/10
    successSoft: Color(0xFFF0FDF4), // success/10
    warningSoft: Color(0xFFFFFBEB), // warning/10
    infoSoft: Color(0xFFEFF6FF), // info/10
    accent: Color(0xFF8B5CF6), // purple-500
    mutedForeground: Color(0xFF71717A), // zinc-500
    dangerForeground: Color(0xFFDC2626), // red-600
    successForeground: Color(0xFF16A34A), // green-600
    warningForeground: Color(0xFFEA580C), // orange-600
    infoForeground: Color(0xFF2563EB), // blue-600
  );

  // Dark theme colors
  static const dark = AppColorsExtension(
    dangerSoft: Color(0xFF450A0A), // danger on dark
    successSoft: Color(0xFF052E16), // success on dark
    warningSoft: Color(0xFF431407), // warning on dark
    infoSoft: Color(0xFF172554), // info on dark
    accent: Color(0xFFA78BFA), // purple-400
    mutedForeground: Color(0xFFA1A1AA), // zinc-400
    dangerForeground: Color(0xFFEF4444), // red-500
    successForeground: Color(0xFF22C55E), // green-500
    warningForeground: Color(0xFFF97316), // orange-500
    infoForeground: Color(0xFF3B82F6), // blue-500
  );
}

/// Extension method to access custom colors easily
extension AppColorsExtensionGetter on ThemeData {
  AppColorsExtension get appColors =>
      extension<AppColorsExtension>() ?? AppColorsExtension.light;
}
