import 'package:flutter/material.dart';

/// Theme Extension for custom colors
/// Provides additional colors beyond Material 3 ColorScheme
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color dangerSoft;
  final Color successSoft;
  final Color warningSoft;
  final Color infoSoft;
  final Color accent;
  final Color muted;
  final Color border;
  final Color mutedForeground;
  final Color dangerForeground;
  final Color successForeground;
  final Color warningForeground;
  final Color infoForeground;

  // Shadows
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;
  final List<BoxShadow> shadowCard;

  const AppColorsExtension({
    required this.dangerSoft,
    required this.successSoft,
    required this.warningSoft,
    required this.infoSoft,
    required this.accent,
    required this.muted,
    required this.border,
    required this.mutedForeground,
    required this.dangerForeground,
    required this.successForeground,
    required this.warningForeground,
    required this.infoForeground,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.shadowCard,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? dangerSoft,
    Color? successSoft,
    Color? warningSoft,
    Color? infoSoft,
    Color? accent,
    Color? muted,
    Color? border,
    Color? mutedForeground,
    Color? dangerForeground,
    Color? successForeground,
    Color? warningForeground,
    Color? infoForeground,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
    List<BoxShadow>? shadowCard,
  }) {
    return AppColorsExtension(
      dangerSoft: dangerSoft ?? this.dangerSoft,
      successSoft: successSoft ?? this.successSoft,
      warningSoft: warningSoft ?? this.warningSoft,
      infoSoft: infoSoft ?? this.infoSoft,
      accent: accent ?? this.accent,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      dangerForeground: dangerForeground ?? this.dangerForeground,
      successForeground: successForeground ?? this.successForeground,
      warningForeground: warningForeground ?? this.warningForeground,
      infoForeground: infoForeground ?? this.infoForeground,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
      shadowCard: shadowCard ?? this.shadowCard,
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
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      dangerForeground:
          Color.lerp(dangerForeground, other.dangerForeground, t)!,
      successForeground:
          Color.lerp(successForeground, other.successForeground, t)!,
      warningForeground:
          Color.lerp(warningForeground, other.warningForeground, t)!,
      infoForeground: Color.lerp(infoForeground, other.infoForeground, t)!,
      shadowSm: BoxShadow.lerpList(shadowSm, other.shadowSm, t)!,
      shadowMd: BoxShadow.lerpList(shadowMd, other.shadowMd, t)!,
      shadowLg: BoxShadow.lerpList(shadowLg, other.shadowLg, t)!,
      shadowCard: BoxShadow.lerpList(shadowCard, other.shadowCard, t)!,
    );
  }

  // Light theme colors & Shadows
  static const light = AppColorsExtension(
    dangerSoft: Color(0xFFFEF2F2),
    successSoft: Color(0xFFF0FDF4),
    warningSoft: Color(0xFFFFFBEB),
    infoSoft: Color(0xFFEFF6FF),
    accent: Color(0xFFEFF6FF), // Approximate light accent
    muted: Color(0xFFEBEEF1), // hsl(210, 15%, 93%)
    border: Color(0xFFE3E8EC), // hsl(210, 20%, 90%)
    mutedForeground: Color(0xFF71717A),
    dangerForeground: Color(0xFFDC2626),
    successForeground: Color(0xFF16A34A),
    warningForeground: Color(0xFFEA580C),
    infoForeground: Color(0xFF2563EB),
    shadowSm: [
      BoxShadow(
        color: Color(0x0A0F172A), // hsl(215 25% 15% / 0.04)
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
    ],
    shadowMd: [
      BoxShadow(
        color: Color(0x140F172A), // hsl(215 25% 15% / 0.08)
        offset: Offset(0, 4),
        blurRadius: 12,
        spreadRadius: -2,
      ),
    ],
    shadowLg: [
      BoxShadow(
        color: Color(0x1E0F172A), // hsl(215 25% 15% / 0.12)
        offset: Offset(0, 12),
        blurRadius: 32,
        spreadRadius: -4,
      ),
    ],
    shadowCard: [
      BoxShadow(
        color: Color(0x0F0F172A), // hsl(215 25% 15% / 0.06)
        offset: Offset(0, 2),
        blurRadius: 8,
        spreadRadius: -2,
      ),
      BoxShadow(
        color: Color(0xCCE3E8EC), // hsl(210 20% 90% / 0.8)
        offset: Offset(0, 0),
        blurRadius: 0,
        spreadRadius: 1,
      ),
    ],
  );

  // Dark theme colors & Shadows
  static const dark = AppColorsExtension(
    dangerSoft: Color(0xFF450A0A),
    successSoft: Color(0xFF052E16),
    warningSoft: Color(0xFF431407),
    infoSoft: Color(0xFF172554),
    accent: Color(0xFF1E293B), // Approximate dark accent
    muted: Color(0xFF2B323B), // hsl(220, 15%, 20%) - Estimated from context
    border: Color(0xFF374151), // hsl(220, 15%, 22%)
    mutedForeground: Color(0xFFA1A1AA),
    dangerForeground: Color(0xFFEF4444),
    successForeground: Color(0xFF22C55E),
    warningForeground: Color(0xFFF97316),
    infoForeground: Color(0xFF3B82F6),
    shadowSm: [
      BoxShadow(
        color: Color(0x33000000), // hsl(0 0% 0% / 0.2)
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
    ],
    shadowMd: [
      BoxShadow(
        color: Color(0x4C000000), // hsl(0 0% 0% / 0.3)
        offset: Offset(0, 4),
        blurRadius: 12,
        spreadRadius: -2,
      ),
    ],
    shadowLg: [
      BoxShadow(
        color: Color(0x66000000), // hsl(0 0% 0% / 0.4)
        offset: Offset(0, 12),
        blurRadius: 32,
        spreadRadius: -4,
      ),
    ],
    shadowCard: [
      BoxShadow(
        color: Color(0x33000000), // hsl(0 0% 0% / 0.2)
        offset: Offset(0, 2),
        blurRadius: 8,
        spreadRadius: -2,
      ),
      BoxShadow(
        color: Color(0xFF303642), // hsl(220 15% 22%)
        offset: Offset(0, 0),
        blurRadius: 0,
        spreadRadius: 1,
      ),
    ],
  );
}

/// Extension method to access custom colors easily
extension AppColorsExtensionGetter on ThemeData {
  AppColorsExtension get appColors =>
      extension<AppColorsExtension>() ?? AppColorsExtension.light;
}
