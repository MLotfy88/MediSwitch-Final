import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';

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
    // Determine colors and icon based on variant
    Color backgroundColor;
    Color textColor;
    Color? borderColor;
    IconData? displayIcon = icon;

    switch (variant) {
      // Default variants
      case BadgeVariant.defaultBadge:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        break;
      case BadgeVariant.secondary:
        backgroundColor = AppColors.secondary;
        textColor = Colors.white;
        break;
      case BadgeVariant.destructive:
        backgroundColor = AppColors.danger;
        textColor = Colors.white;
        break;
      case BadgeVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppColors.foreground;
        borderColor = AppColors.border;
        break;

      // Custom MediSwitch variants
      case BadgeVariant.newBadge:
        backgroundColor = AppColors.success;
        textColor = Colors.white;
        break;
      case BadgeVariant.popular:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        break;
      case BadgeVariant.danger:
        backgroundColor = AppColors.danger;
        textColor = Colors.white;
        break;
      case BadgeVariant.warning:
        backgroundColor = AppColors.warning;
        textColor = AppColors.warningForeground;
        break;
      case BadgeVariant.info:
        backgroundColor = AppColors.info;
        textColor = AppColors.infoSoft;
        break;
      case BadgeVariant.priceDown:
        backgroundColor = AppColors.successSoft;
        textColor = AppColors.success;
        displayIcon ??= LucideIcons.trendingDown;
        break;
      case BadgeVariant.priceUp:
        backgroundColor = AppColors.dangerSoft;
        textColor = AppColors.danger;
        displayIcon ??= LucideIcons.trendingUp;
        break;
      case BadgeVariant.interaction:
        backgroundColor = AppColors.dangerSoft;
        textColor = AppColors.danger;
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
      case BadgeSize.md:
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
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
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
              fontWeight: FontWeight.w600,
              color: textColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
