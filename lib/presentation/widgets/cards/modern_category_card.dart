import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/categories_data.dart';
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

    // Use shared logic for colors
    final style = getCategoryColorStyle(category.color ?? 'blue', appColors);

    // Use shared logic or local fallback for icon if Entity icon string is passed
    // But CategoryData has IconData. The Entity has String.
    // MedicineProvider maps String icon name.
    // We can keep a local helper or rely on the provider mapping correctly.
    // Given the provider maps 'brain' -> 'brain' string, we need to map string to IconData here.
    final iconData = _getIcon(category.icon ?? 'pill');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 88),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: style.border),
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
                color: style.background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(iconData, size: 24, color: style.icon),
            ),
            const SizedBox(height: 8),
            // Category Name - Use short name for consistent card sizes
            Text(
              category.shortName ?? category.name,
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

  IconData _getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'heart':
        return LucideIcons.heart;
      case 'heartpulse':
        return LucideIcons.heartPulse;
      case 'brain':
      case 'psychiatric':
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
      case 'bug':
        return LucideIcons.bug;
      case 'shield':
      case 'shieldcheck':
        return LucideIcons.shieldCheck;
      case 'sun':
      case 'dermatology':
        return LucideIcons.sun;
      case 'activity':
      case 'endocrinology':
        return LucideIcons.activity;
      case 'stethoscope':
      case 'general':
        return LucideIcons.stethoscope;
      case 'apple':
      case 'nutrition':
        return LucideIcons.apple;
      case 'zap':
      case 'pain':
        return LucideIcons.zap;
      case 'wind':
      case 'respiratory':
        return LucideIcons.wind;
      default:
        if (iconName.contains('infect')) return LucideIcons.bug;
        return LucideIcons.pill;
    }
  }
}
