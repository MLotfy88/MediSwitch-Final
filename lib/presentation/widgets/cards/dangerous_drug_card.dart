import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors.dart';

enum RiskLevel { critical, high }

class DangerousDrugCard extends StatelessWidget {
  final String id;
  final String name;
  final String activeIngredient;
  final RiskLevel riskLevel;
  final int interactionCount;
  final VoidCallback? onTap;

  const DangerousDrugCard({
    super.key,
    required this.id,
    required this.name,
    required this.activeIngredient,
    required this.riskLevel,
    required this.interactionCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine styles based on risk level
    final isCritical = riskLevel == RiskLevel.critical;

    final backgroundColor =
        isCritical
            ? AppColors.danger.withValues(alpha: 0.1)
            : AppColors.warningSoft;
    final borderColor =
        isCritical
            ? AppColors.danger.withValues(alpha: 0.3)
            : AppColors.warning.withValues(alpha: 0.3);

    final iconBg =
        isCritical
            ? AppColors.danger.withValues(alpha: 0.2)
            : AppColors.warning.withValues(alpha: 0.2);
    final iconColor = isCritical ? AppColors.danger : AppColors.warning;
    final iconData = isCritical ? LucideIcons.skull : LucideIcons.alertTriangle;

    final nameColor =
        isCritical
            ? AppColors.danger
            : const Color(0xFF4F3103); // Warning Foreground
    final badgeColor = isCritical ? AppColors.danger : const Color(0xFF4F3103);
    final badgeBg =
        isCritical
            ? AppColors.danger.withValues(alpha: 0.2)
            : AppColors.warning.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 140),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(iconData, size: 20, color: iconColor),
            ),
            const SizedBox(height: 12),

            // Name
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: nameColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Active Ingredient
            Text(
              activeIngredient,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Interaction Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, size: 12, color: badgeColor),
                  const SizedBox(width: 4),
                  Text(
                    '$interactionCount interactions',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
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
