import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../domain/entities/category_entity.dart';
import '../../theme/app_colors_extension.dart';

class ModernCategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback? onTap;

  const ModernCategoryCard({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appColors = theme.appColors;
    final colors = _getColors(context, category.color ?? 'blue');
    final iconData = _getIcon(category.icon ?? 'pill');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 88),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.borderColor),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: isDark ? 0.2 : 0.04),
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Drug Count
            Text(
              '${category.drugCount} drugs',
              style: TextStyle(fontSize: 10, color: appColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }

  ({Color bgColor, Color iconColor, Color borderColor}) _getColors(
    BuildContext context,
    String colorName,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appColors = theme.appColors;

    switch (colorName.toLowerCase()) {
      case 'red':
        return (
          bgColor: appColors.dangerSoft,
          iconColor: appColors.dangerForeground,
          borderColor: appColors.dangerForeground.withValues(alpha: 0.2),
        );
      case 'purple':
        return (
          bgColor: appColors.accent.withValues(alpha: isDark ? 0.2 : 0.1),
          iconColor: appColors.accent,
          borderColor: appColors.accent.withValues(alpha: 0.2),
        );
      case 'teal':
        return (
          bgColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
          iconColor: theme.colorScheme.secondary,
          borderColor: theme.colorScheme.secondary.withValues(alpha: 0.2),
        );
      case 'green':
        return (
          bgColor: appColors.successSoft,
          iconColor: appColors.successForeground,
          borderColor: appColors.successForeground.withValues(alpha: 0.2),
        );
      case 'orange':
        return (
          bgColor: appColors.warningSoft,
          iconColor: appColors.warningForeground,
          borderColor: appColors.warningForeground.withValues(alpha: 0.3),
        );
      case 'blue':
      default:
        return (
          bgColor: appColors.infoSoft,
          iconColor: appColors.infoForeground,
          borderColor: appColors.infoForeground.withValues(alpha: 0.2),
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
