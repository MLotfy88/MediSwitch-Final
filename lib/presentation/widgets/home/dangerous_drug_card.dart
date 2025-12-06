import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/design_tokens.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';

enum DangerousRiskLevel { high, critical }

class DangerousDrugUIModel {
  final String id;
  final String name;
  final String nameAr;
  final String activeIngredient;
  final DangerousRiskLevel riskLevel;
  final int interactionCount;

  const DangerousDrugUIModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.activeIngredient,
    required this.riskLevel,
    required this.interactionCount,
  });
}

class DangerousDrugCard extends StatelessWidget {
  final DangerousDrugUIModel drug;
  final bool isRTL;
  final VoidCallback? onTap;

  const DangerousDrugCard({
    super.key,
    required this.drug,
    this.isRTL = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).appColors;
    final colorScheme = Theme.of(context).colorScheme;

    final isCritical = drug.riskLevel == DangerousRiskLevel.critical;

    // Colors based on risk level
    final bgColor = isCritical ? appColors.dangerSoft : appColors.warningSoft;
    final borderColor =
        isCritical
            ? appColors.dangerForeground.withValues(alpha: 0.3)
            : appColors.warningForeground.withValues(alpha: 0.3);
    final iconBgColor =
        isCritical
            ? appColors.dangerForeground.withValues(alpha: 0.2)
            : appColors.warningForeground.withValues(alpha: 0.2);
    final iconColor =
        isCritical ? appColors.dangerForeground : appColors.warningForeground;
    final textColor =
        isCritical ? appColors.dangerForeground : appColors.warningForeground;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.circular,
        child: Container(
          constraints: const BoxConstraints(minWidth: 140),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.circular,
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment:
                isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: AppRadius.circularSm,
                ),
                alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                child: Icon(
                  isCritical ? LucideIcons.skull : LucideIcons.alertTriangle,
                  color: iconColor,
                  size: 20,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Drug name
              Text(
                isRTL ? drug.nameAr : drug.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
              ),

              const SizedBox(height: 4),

              // Active ingredient
              Text(
                drug.activeIngredient,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
              ),

              const SizedBox(height: AppSpacing.sm),

              // Interaction count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 12, color: textColor),
                    const SizedBox(width: 4),
                    Text(
                      isRTL
                          ? '${drug.interactionCount} تفاعلات'
                          : '${drug.interactionCount} interactions',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
