import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/entities/high_risk_ingredient.dart';
import '../theme/app_colors.dart';

/// Card widget to display a high-risk active ingredient
class HighRiskIngredientCard extends StatelessWidget {
  final HighRiskIngredient ingredient;
  final VoidCallback? onTap;

  const HighRiskIngredientCard({
    super.key,
    required this.ingredient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine severity color based on severe count
    final bool isCritical = ingredient.severeCount >= 5;

    // Use more vibrant colors for dark mode visibility
    final Color mainColor =
        isCritical
            ? (isDark ? const Color(0xFFFF5252) : AppColors.danger)
            : (isDark ? const Color(0xFFFFD740) : AppColors.warning);

    final Color softBgColor =
        isCritical
            ? (isDark
                ? AppColors.danger.withValues(alpha: 0.15)
                : AppColors.dangerSoft)
            : (isDark
                ? AppColors.warning.withValues(alpha: 0.15)
                : AppColors.warningSoft);

    final iconData = isCritical ? LucideIcons.skull : LucideIcons.alertTriangle;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        // Increased width and removed restrictive height
        constraints: const BoxConstraints(minWidth: 160, maxWidth: 190),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor, // Use card color background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: mainColor.withValues(alpha: isDark ? 0.5 : 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: mainColor.withValues(alpha: 0.05),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            Container(
              width: 48, // Slightly larger
              height: 48,
              decoration: BoxDecoration(
                color: softBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(iconData, color: mainColor, size: 24),
            ),

            const SizedBox(height: 12),

            // Ingredient Name
            Text(
              ingredient.displayName,
              style: TextStyle(
                color:
                    isDark
                        ? theme.colorScheme.onSurface
                        : mainColor, // Better contrast in dark mode
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Danger Score Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: softBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isRTL
                        ? 'خطورة: ${ingredient.dangerScore}'
                        : 'Score: ${ingredient.dangerScore}',
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Interaction Count Badge
            Row(
              children: [
                Icon(
                  LucideIcons.alertTriangle,
                  size: 14,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isRTL
                        ? '${ingredient.severeCount} تفاعل شديد'
                        : '${ingredient.severeCount} severe interactions',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
