import 'package:flutter/material.dart';

import '../../presentation/theme/app_colors.dart';

class CategoryCard extends StatelessWidget {
  final String name;
  final IconData iconData;
  final int drugCount;
  final String colorKey;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.name,
    required this.iconData,
    required this.drugCount,
    required this.colorKey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Map color keys to Color objects matches src/components/drugs/CategoryCard.tsx
    final colors = _getColorMap(context, colorKey);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16), // rounded-2xl
      child: Container(
        width: 100, // min-w-[88px] + padding, fixed width for horizontal list
        padding: const EdgeInsets.all(16), // p-4
        decoration: BoxDecoration(
          color: colors['bg'],
          borderRadius: BorderRadius.circular(16), // rounded-2xl
          border: Border.all(color: colors['border']!, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(iconData, size: 28, color: colors['icon']),
            const SizedBox(height: 12), // Increased gap
            // Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                overflow: TextOverflow.ellipsis,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),

            const SizedBox(height: 4),

            // Count
            Text(
              '$drugCount ${isRTL ? "دواء" : "drugs"}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.mutedForeground.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> _getColorMap(BuildContext context, String key) {
    // Reference mapping:
    // red: bg-danger-soft, icon-danger, border-danger/20
    // blue: bg-info-soft, icon-info, border-info/20
    // purple: bg-accent, icon-primary, border-primary/20
    // green: bg-success-soft, icon-success, border-success/20
    // orange: bg-warning-soft, icon-warning, border-warning/30
    // teal: bg-secondary/10, icon-secondary, border-secondary/20

    switch (key) {
      case 'red':
        return {
          'bg': AppColors.dangerSoft,
          'icon': AppColors.danger,
          'border': AppColors.danger.withValues(alpha: 0.2),
        };
      case 'blue':
        return {
          'bg': AppColors.infoSoft,
          'icon': AppColors.info,
          'border': AppColors.info.withValues(alpha: 0.2),
        };
      case 'purple':
        return {
          // bg-accent in tailwind config is 210 30% 95% -> Color(0xFFF1F5F9)
          'bg': AppColors.accent,
          'icon': AppColors.primary,
          'border': AppColors.primary.withValues(alpha: 0.2),
        };
      case 'green':
        return {
          'bg': AppColors.successSoft,
          'icon': AppColors.success,
          'border': AppColors.success.withValues(alpha: 0.2),
        };
      case 'orange':
        return {
          'bg': AppColors.warningSoft,
          'icon': AppColors.warning,
          'border': AppColors.warning.withValues(alpha: 0.3),
        };
      case 'teal':
        return {
          'bg': AppColors.secondary.withValues(alpha: 0.1),
          'icon': AppColors.secondary,
          'border': AppColors.secondary.withValues(alpha: 0.2),
        };
      default: // Default to blue
        return {
          'bg': AppColors.infoSoft,
          'icon': AppColors.info,
          'border': AppColors.info.withValues(alpha: 0.2),
        };
    }
  }
}
