import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';

class DangerousDrugCard extends StatelessWidget {
  final DrugEntity drug;
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
    // Determine risk level based on some logic or default to high for 'Popular' items if we are reusing this card.
    // Since we are using this for 'Popular' / 'Common' drugs now, we can remove the 'Critical' styling logic
    // or adapt it. Let's adapt it to be just a nice card for 'Popular' drugs.

    // For now, let's treat everything as 'high' (warning color) which looks good,
    // or randomly assign for variety if we want to simulate risk (not recommended for real app).
    // Better: Use a neutral 'Info' or 'Primary' style since these are 'Popular' drugs now, not necessarily 'Dangerous'.

    // Style for Popular drugs (Warning/Orange theme)
    final appColors = Theme.of(context).appColors;
    final colorScheme = Theme.of(context).colorScheme;

    final bg = appColors.warningSoft;
    final border = appColors.warningForeground.withOpacity(0.3);
    final iconBg = appColors.warningForeground.withOpacity(0.2);
    final iconColor = appColors.warningForeground;
    final titleColor = const Color(0xFFF59E0B); // warning text

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
                LucideIcons.star, // Changed icon to star for popular
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),

            // Name
            Text(
              isRTL ? drug.arabicName : drug.tradeName,
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
              drug.active,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: appColors.mutedForeground),
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
                  Icon(LucideIcons.star, size: 12, color: iconColor),
                  const SizedBox(width: 4),
                  Text(
                    isRTL ? 'شائع' : 'Popular',
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
