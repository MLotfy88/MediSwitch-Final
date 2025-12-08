import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    // Determine severity color based on severe count
    final bool isCritical = ingredient.severeCount >= 5;
    final mainColor = isCritical ? AppColors.danger : AppColors.warning;
    final softBgColor =
        isCritical ? AppColors.dangerSoft : AppColors.warningSoft;
    final iconData = isCritical ? LucideIcons.skull : LucideIcons.alertTriangle;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minWidth: 150, maxWidth: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: softBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mainColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(iconData, color: mainColor, size: 20),
            ),

            const SizedBox(height: 12),

            // Ingredient Name
            Text(
              ingredient.displayName,
              style: TextStyle(
                color: mainColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Danger Score Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isRTL
                    ? 'خطورة: ${ingredient.dangerScore}'
                    : 'Score: ${ingredient.dangerScore}',
                style: TextStyle(
                  color: mainColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Interaction Count Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, size: 12, color: mainColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      isRTL
                          ? '${ingredient.severeCount} شديد'
                          : '${ingredient.severeCount} severe',
                      style: TextStyle(
                        color: mainColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
