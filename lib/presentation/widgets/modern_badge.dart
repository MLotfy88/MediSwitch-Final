import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../presentation/theme/app_colors.dart';

enum BadgeVariant { newBadge, popular, priceDown, priceUp, interaction }

enum BadgeSize {
  sm, // 10px text
  md, // 12px text (default)
  lg, // 14px text
}

class ModernBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final BadgeSize size;

  const ModernBadge({
    super.key,
    required this.text,
    required this.variant,
    this.size = BadgeSize.md,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors and icon based on variant
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    switch (variant) {
      case BadgeVariant.newBadge:
        backgroundColor = AppColors.success;
        textColor = Colors.white;
        break;
      case BadgeVariant.popular:
        backgroundColor = AppColors.info;
        textColor = Colors.white;
        break;
      case BadgeVariant.priceDown:
        backgroundColor = AppColors.successSoft;
        textColor = AppColors.success;
        icon = LucideIcons.trendingDown;
        break;
      case BadgeVariant.priceUp:
        backgroundColor = AppColors.dangerSoft;
        textColor = AppColors.danger;
        icon = LucideIcons.trendingUp;
        break;
      case BadgeVariant.interaction:
        backgroundColor = AppColors.dangerSoft;
        textColor = AppColors.danger;
        icon = LucideIcons.alertTriangle;
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
        padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 2);
        break;
      case BadgeSize.md:
        fontSize = 12;
        iconSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        break;
      case BadgeSize.lg:
        fontSize = 14;
        iconSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999), // Rounded full
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: textColor),
            SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
