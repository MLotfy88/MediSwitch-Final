import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';

class CategoryModel {
  final String id;
  final String name;
  final String nameAr;
  final IconData icon;
  final int drugCount;
  final String color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.icon,
    required this.drugCount,
    required this.color,
  });
}

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final bool isRTL;
  final VoidCallback? onTap;

  const CategoryCard({
    Key? key,
    required this.category,
    this.isRTL = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = _getStyle(category.color);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: style['bg'],
          borderRadius: BorderRadius.circular(16), // rounded-2xl
          border: Border.all(color: style['border']!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style['bg'],
                borderRadius: BorderRadius.circular(12), // rounded-xl
              ),
              child: Icon(category.icon, color: style['icon'], size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              isRTL ? category.nameAr : category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              isRTL
                  ? '${category.drugCount} دواء'
                  : '${category.drugCount} drugs',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> _getStyle(String color) {
    switch (color) {
      case 'red':
        return {
          'bg': AppColors.dangerSoft,
          'icon': AppColors.danger,
          'border': AppColors.danger.withOpacity(0.2),
        };
      case 'purple':
        return {
          'bg': AppColors.accent,
          'icon': AppColors.primary,
          'border': AppColors.primary.withOpacity(0.2),
        };
      case 'green':
        return {
          'bg': AppColors.successSoft,
          'icon': AppColors.success,
          'border': AppColors.success.withOpacity(0.2),
        };
      case 'orange':
        return {
          'bg': AppColors.warningSoft,
          'icon': AppColors.warning,
          'border': AppColors.warning.withOpacity(0.3),
        };
      case 'teal':
        return {
          'bg': AppColors.secondary.withOpacity(0.1),
          'icon': AppColors.secondary,
          'border': AppColors.secondary.withOpacity(0.2),
        };
      case 'blue':
      default:
        return {
          'bg': AppColors.infoSoft,
          'icon': AppColors.info,
          'border': AppColors.info.withOpacity(0.2),
        };
    }
  }
}
