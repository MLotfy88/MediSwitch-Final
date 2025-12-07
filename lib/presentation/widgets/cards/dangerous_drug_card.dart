import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors_extension.dart';

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
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final isDark = theme.brightness == Brightness.dark;

    // Determine styles based on risk level
    final isCritical = riskLevel == RiskLevel.critical;

    final backgroundColor =
        isCritical ? appColors.dangerSoft : appColors.warningSoft;
    final borderColor =
        isCritical
            ? appColors.dangerForeground.withValues(alpha: 0.3)
            : appColors.warningForeground.withValues(alpha: 0.3);

    final iconBg =
        isCritical
            ? appColors.dangerForeground.withValues(alpha: 0.2)
            : appColors.warningForeground.withValues(alpha: 0.2);
    final iconColor =
        isCritical ? appColors.dangerForeground : appColors.warningForeground;
    final iconData = isCritical ? LucideIcons.skull : LucideIcons.alertTriangle;

    final nameColor =
        isCritical ? appColors.dangerForeground : appColors.warningForeground;
    final badgeColor =
        isCritical ? appColors.dangerForeground : appColors.warningForeground;
    final badgeBg =
        isCritical
            ? appColors.dangerForeground.withValues(alpha: 0.2)
            : appColors.warningForeground.withValues(alpha: 0.2);

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
              style: TextStyle(fontSize: 12, color: appColors.mutedForeground),
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
