import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../domain/entities/category_entity.dart';
import '../../theme/app_colors.dart';

class ModernCategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback? onTap;

  const ModernCategoryCard({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(category.color ?? 'blue');
    final iconData = _getIcon(category.icon ?? 'pill');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 88),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.borderColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.foreground.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(iconData, size: 24, color: colors.iconColor),
            ),
            const SizedBox(height: 8),
            // Category Name
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Drug Count
            Text(
              '${category.drugCount} drugs',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({Color bgColor, Color iconColor, Color borderColor}) _getColors(
    String colorName,
  ) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return (
          bgColor: AppColors.dangerSoft,
          iconColor: AppColors.danger,
          borderColor: AppColors.danger.withValues(alpha: 0.2),
        );
      case 'purple':
        return (
          bgColor: AppColors.accent,
          iconColor: AppColors.primary,
          borderColor: AppColors.primary.withValues(alpha: 0.2),
        );
      case 'teal':
        return (
          bgColor: AppColors.secondary.withValues(alpha: 0.1),
          iconColor: AppColors.secondary,
          borderColor: AppColors.secondary.withValues(alpha: 0.2),
        );
      case 'green':
        return (
          bgColor: AppColors.successSoft,
          iconColor: AppColors.success,
          borderColor: AppColors.success.withValues(alpha: 0.2),
        );
      case 'orange':
        return (
          bgColor: AppColors.warningSoft,
          iconColor: AppColors.warning,
          borderColor: AppColors.warning.withValues(alpha: 0.3),
        );
      case 'blue':
      default:
        return (
          bgColor: AppColors.infoSoft,
          iconColor: AppColors.info,
          borderColor: AppColors.info.withValues(alpha: 0.2),
        );
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'heart':
        return LucideIcons.heart;
      case 'brain':
        return LucideIcons.brain;
      case 'dental':
      case 'smile':
        return LucideIcons.smile;
      case 'baby':
        return LucideIcons.baby;
      case 'eye':
        return LucideIcons.eye;
      case 'bone':
        return LucideIcons.bone;
      default:
        return LucideIcons.pill;
    }
  }
}
