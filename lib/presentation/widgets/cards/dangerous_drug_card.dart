import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';

import '../../theme/app_colors_extension.dart';

enum RiskLevel { critical, high }

class DangerousDrugCard extends StatelessWidget {
  final DrugEntity drug;
  final RiskLevel riskLevel;
  final int interactionCount;
  final VoidCallback? onTap;

  const DangerousDrugCard({
    super.key,
    required this.drug,
    required this.riskLevel,
    required this.interactionCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    // Determine styles based on risk level
    final isCritical = riskLevel == RiskLevel.critical;

    final backgroundColor =
        isCritical
            ? appColors.dangerSoft.withOpacity(0.1)
            : appColors.warningSoft; // React: bg-danger/10 vs warning-soft
    final borderColor =
        isCritical
            ? appColors.dangerSoft.withOpacity(0.3) // React: border-danger/30
            : appColors.warningSoft.withOpacity(
              0.3,
            ); // React: border-warning/30

    final iconBg =
        isCritical
            ? appColors.dangerSoft.withOpacity(0.2) // React: bg-danger/20
            : appColors.warningSoft.withOpacity(0.2); // React: bg-warning/20

    final iconColor =
        isCritical ? appColors.dangerForeground : appColors.warningForeground;

    final iconData = isCritical ? LucideIcons.skull : LucideIcons.alertTriangle;

    final textColor =
        isCritical ? appColors.dangerForeground : appColors.warningForeground;

    final badgeBg =
        isCritical
            ? appColors.dangerSoft.withOpacity(0.2)
            : appColors.warningSoft.withOpacity(0.2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:
            140, // React: min-w-[140px] -> Fixed width for horizontal list items often better
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16), // React: rounded-2xl
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12), // React: rounded-xl
              ),
              child: Icon(iconData, size: 20, color: iconColor),
            ),
            const SizedBox(height: 12),

            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug.tradeName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  drug.active,
                  style: TextStyle(
                    fontSize: 12,
                    color: appColors.mutedForeground,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Interaction Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999), // React: rounded-full
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, size: 10, color: iconColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$interactionCount interactions',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
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
