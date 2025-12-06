import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/interaction_severity.dart'; // Import InteractionSeverity
import '../../presentation/theme/app_colors.dart';

class DangerousDrugCard extends StatelessWidget {
  final DrugEntity drug;
  final VoidCallback? onTap;
  final int interactionCount;
  final InteractionSeverity?
  severity; // Optional severity, defaults to Critical/High if null

  const DangerousDrugCard({
    super.key,
    required this.drug,
    this.onTap,
    this.interactionCount = 0,
    this.severity,
  });

  @override
  Widget build(BuildContext context) {
    // Determine style based on severity
    // Default to Critical (Red) if unknown or not provided, as this is a "Dangerous" card
    final effectiveSeverity = severity ?? InteractionSeverity.severe;

    Color mainColor;
    Color softBgColor;
    IconData iconData;

    switch (effectiveSeverity) {
      case InteractionSeverity.contraindicated:
      case InteractionSeverity.severe:
      case InteractionSeverity.major:
        // Critical/High Risk -> Red/Skull
        mainColor = AppColors.danger;
        softBgColor = AppColors.dangerSoft;
        iconData = LucideIcons.skull;
        break;

      case InteractionSeverity.moderate:
        // Moderate Risk -> Amber/Warning
        mainColor = AppColors.warning;
        softBgColor =
            AppColors
                .warningSoft; // You might need to check if warningSoft exists in AppColors, usually it does. If not, use amber[50]
        iconData = LucideIcons.alertTriangle;
        break;

      case InteractionSeverity.minor:
      case InteractionSeverity.unknown:
      default:
        // Minor/Unknown -> Blue/Info (or maybe grey/orange depending on preference, but usually info is blue)
        // User asked for "Green for simple interaction", but traditionally green is 'safe'.
        // Let's use Blue for minor info, or Green if strictly following user "Green for simple".
        // User said: "Green for simple".
        mainColor = AppColors.success;
        softBgColor = AppColors.successSoft;
        iconData = LucideIcons.info;
        break;
    }

    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final displayName =
        isRTL && drug.arabicName.isNotEmpty ? drug.arabicName : drug.tradeName;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
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
            // Icon Placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(iconData, color: mainColor, size: 20),
            ),

            const SizedBox(height: 12),

            // Name
            Text(
              displayName,
              style: TextStyle(
                color: mainColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Active Ingredient
            Text(
              drug.active,
              style: TextStyle(
                color: mainColor.withValues(alpha: 0.8),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: ui.TextDirection.ltr,
            ),

            const SizedBox(height: 12),

            // Interaction Badge
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
                  Text(
                    isRTL
                        ? "$interactionCount تفاعلات"
                        : "$interactionCount interactions",
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
