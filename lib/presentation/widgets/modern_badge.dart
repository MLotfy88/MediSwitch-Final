import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';

/// Badge variants matching design-refresh/docs/components/badge.md
enum BadgeVariant {
  // Default variants
  defaultBadge, // bg-primary, text-primary-foreground
  secondary, // bg-secondary, text-secondary-foreground
  destructive, // bg-destructive, text-destructive-foreground
  outline, // transparent, text-foreground, border visible
  // Custom MediSwitch variants
  newBadge, // bg-success, text-success-foreground (الأدوية الجديدة)
  popular, // bg-primary, text-primary-foreground (الأدوية الشائعة)
  danger, // bg-danger, text-danger-foreground (تحذيرات خطيرة)
  warning, // bg-warning, text-warning-foreground (تحذيرات متوسطة)
  info, // bg-info, text-info-soft (معلومات)
  priceDown, // bg-success-soft, text-success (انخفاض السعر)
  priceUp, // bg-danger-soft, text-danger (ارتفاع السعر)
  interaction, // bg-danger-soft, text-danger (تفاعل دوائي)
}

/// Badge sizes matching design-refresh/docs/components/badge.md
enum BadgeSize {
  sm, // px-2 py-0.5, text-[10px]
  md, // px-2.5 py-0.5, text-xs (default)
  lg, // px-3 py-1, text-sm
}

/// ModernBadge widget matching design-refresh/docs/components/badge.md
class ModernBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final BadgeSize size;
  final IconData? icon;

  const ModernBadge({
    super.key,
    required this.text,
    required this.variant,
    this.size = BadgeSize.md,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final isDark = theme.brightness == Brightness.dark;

    // Determine colors and icon based on variant
    Color backgroundColor;
    Color textColor;
    Color? borderColor;
    IconData? displayIcon = icon;
    FontWeight fontWeight = FontWeight.w600; // Default

    switch (variant) {
      // Default variants
      case BadgeVariant.defaultBadge:
        backgroundColor = theme.colorScheme.primary;
        textColor = theme.colorScheme.onPrimary;
        break;
      case BadgeVariant.secondary:
        backgroundColor = theme.colorScheme.secondary;
        textColor = theme.colorScheme.onSecondary;
        break;
      case BadgeVariant.destructive:
        backgroundColor = theme.colorScheme.error;
        textColor = theme.colorScheme.onError;
        break;
      case BadgeVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = theme.colorScheme.onSurface;
        borderColor = theme.colorScheme.outline;
        break;

      // Custom MediSwitch variants
      case BadgeVariant.newBadge:
        // bg-success (solid)
        backgroundColor = appColors.successForeground;
        // text-success-foreground (white usually)
        textColor = Colors.white;
        break;
      case BadgeVariant.popular:
        backgroundColor = theme.colorScheme.primary;
        textColor = theme.colorScheme.onPrimary;
        break;
      case BadgeVariant.danger:
        backgroundColor = appColors.dangerForeground; // Solid red
        textColor = Colors.white;
        break;
      case BadgeVariant.warning:
        backgroundColor = appColors.warningForeground; // Solid orange
        // Improved contrast: White is okay on dark orange (dark mode), but on light orange (if any) it might be weak.
        // warningForeground is usually vibrant/dark enough for white text.
        textColor = Colors.white;
        break;
      case BadgeVariant.info:
        backgroundColor = appColors.infoForeground; // Solid blue
        textColor = Colors.white;
        break;
      case BadgeVariant.priceDown:
        backgroundColor = appColors.successSoft;
        textColor = appColors.successForeground;
        // Ensure legible text on soft background
        if (!isDark) {
          // In light mode, soft background is light green, foreground is dark green.
          // OK as is.
        }
        fontWeight = FontWeight.bold; // 700
        displayIcon ??= LucideIcons.trendingDown;
        break;
      case BadgeVariant.priceUp:
        backgroundColor = appColors.dangerSoft;
        textColor = appColors.dangerForeground;
        fontWeight = FontWeight.bold; // 700
        displayIcon ??= LucideIcons.trendingUp;
        break;
      case BadgeVariant.interaction:
        backgroundColor = appColors.dangerSoft;
        textColor = appColors.dangerForeground;
        fontWeight = FontWeight.w600;
        // border-danger/30
        borderColor = appColors.dangerForeground.withValues(alpha: 0.3);
        displayIcon ??= LucideIcons.alertTriangle;
        break;
    }

    // Determine sizes
    double fontSize;
    double iconSize;
    EdgeInsets padding;

    switch (size) {
      case BadgeSize.sm:
        fontSize = 10;
        iconSize = 12;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2);
        break;
      case BadgeSize.md: // Default (px-2.5 py-0.5)
        fontSize = 12;
        iconSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 2);
        break;
      case BadgeSize.lg:
        fontSize = 14;
        iconSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999), // Rounded full
        border: borderColor != null ? Border.all(color: borderColor) : null,
        boxShadow: _getShadow(variant, isDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (displayIcon != null) ...[
            Icon(displayIcon, size: iconSize, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: textColor,
              height:
                  1.2, // Slightly increased height for better centering/readability
            ),
          ),
        ],
      ),
    );
  }

  /// Returns shadow based on variant and theme (shadow-sm)
  List<BoxShadow>? _getShadow(BadgeVariant variant, bool isDark) {
    // Outline usually has no shadow. Soft variants (price, interaction) usually no shadow in ShadCN.
    // Solid variants (new, popular, danger, warning) have shadow-sm.

    if (variant == BadgeVariant.outline ||
        variant == BadgeVariant.priceDown ||
        variant == BadgeVariant.priceUp ||
        variant == BadgeVariant.interaction ||
        variant == BadgeVariant.secondary ||
        variant == BadgeVariant.destructive) {
      // Secondary/Destructive might have shadow? Spec says secondary has nothing listed for shadow.
      return null;
    }

    // Default, New, Popular, Danger, Warning, Info have shadow-sm per spec.
    return [
      BoxShadow(
        color:
            isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];
  }
}
