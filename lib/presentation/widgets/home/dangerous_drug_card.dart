import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';

class DangerousDrugModel {
  final String id;
  final String name;
  final String activeIngredient;
  final String riskLevel; // 'high' | 'critical'
  final int interactionCount;

  DangerousDrugModel({
    required this.id,
    required this.name,
    required this.activeIngredient,
    required this.riskLevel,
    required this.interactionCount,
  });
}

class DangerousDrugCard extends StatelessWidget {
  final DangerousDrugModel drug;
  final bool isRTL;
  final VoidCallback? onTap;

  const DangerousDrugCard({
    Key? key,
    required this.drug,
    this.isRTL = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCritical = drug.riskLevel == 'critical';

    final bg =
        isCritical ? AppColors.danger.withOpacity(0.1) : AppColors.warningSoft;
    final border =
        isCritical
            ? AppColors.danger.withOpacity(0.3)
            : AppColors.warning.withOpacity(0.3);
    final iconBg =
        isCritical
            ? AppColors.danger.withOpacity(0.2)
            : AppColors.warning.withOpacity(0.2);
    final iconColor = isCritical ? AppColors.danger : AppColors.warning;
    final titleColor =
        isCritical ? AppColors.danger : const Color(0xFFF59E0B); // warning text

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140, // min-w-[140px]
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment:
              isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCritical ? LucideIcons.skull : LucideIcons.alertTriangle,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),

            // Name
            Text(
              drug.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
            ),

            // Active Ingredient
            Text(
              drug.activeIngredient,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 8),

            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.alertTriangle, size: 12, color: iconColor),
                  const SizedBox(width: 4),
                  Text(
                    isRTL
                        ? '${drug.interactionCount} تفاعلات'
                        : '${drug.interactionCount} interactions',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
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
