import 'package:flutter/material.dart';

import '../../core/constants/categories_data.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_colors_extension.dart';

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
    // Use the comprehensive helper from categories_data.dart
    final colorStyle = getCategoryColorStyle(
      colorKey,
      Theme.of(context).extension<AppColorsExtension>()!,
    );
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorStyle.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorStyle.border, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(iconData, size: 28, color: colorStyle.icon),
            const SizedBox(height: 12),
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
}
