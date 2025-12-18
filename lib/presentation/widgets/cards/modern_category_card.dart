import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../domain/entities/category_entity.dart';
import '../../theme/app_colors_extension.dart';

/// Modern Category Card matching Quick Tools button styling EXACTLY
/// Uses BOLD (Filled) custom SVG icons from healthicons.org for body organs
class ModernCategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback? onTap;

  const ModernCategoryCard({required this.category, super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    final mainColor = _getCategoryColor(category.id, appColors);
    final iconPath = _getCategoryIconPath(category.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 88),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: mainColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: mainColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(mainColor, BlendMode.srcIn),
                  // HealthIcons Filled style can sometimes be very dense,
                  // but BlendMode.srcIn handles the coloring well.
                ),
              ),
            ),
            const SizedBox(height: 8),
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
            Text(
              '${category.drugCount} drugs',
              style: TextStyle(fontSize: 10, color: appColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoryId, AppColorsExtension appColors) {
    switch (categoryId.toLowerCase()) {
      case 'cardiovascular':
        return Colors.pink.shade600;
      case 'psychiatric':
        return Colors.indigo.shade600;
      case 'neurology':
        return Colors.deepPurple.shade600;
      case 'dental':
        return Colors.teal.shade600;
      case 'pediatric':
        return appColors.successForeground;
      case 'gynecology':
        return Colors.pink.shade400;
      case 'ophthalmology':
        return appColors.infoForeground;
      case 'orthopedics':
        return Colors.brown.shade600;
      case 'anti_infective':
        return Colors.teal.shade700;
      case 'dermatology':
        return Colors.amber.shade700;
      case 'nutrition':
        return Colors.lime.shade700;
      case 'respiratory':
        return Colors.cyan.shade600;
      case 'gastroenterology':
        return appColors.warningForeground;
      case 'pain_relief':
        return appColors.dangerForeground;
      case 'immunology':
        return Colors.green.shade600;
      case 'endocrinology':
        return Colors.purple.shade600;
      case 'urology':
        return Colors.lightBlue.shade600;
      case 'hematology':
        return Colors.red.shade800;
      case 'oncology':
        return Colors.redAccent.shade700;
      case 'general':
      default:
        return Colors.blueGrey.shade600;
    }
  }

  /// Get SVG icon path for each medical specialty
  /// Using FILLED/BOLD SVGs from healthicons.org for distinct body organ icons
  String _getCategoryIconPath(String categoryId) {
    const basePath = 'assets/icons/medical/';
    switch (categoryId.toLowerCase()) {
      case 'cardiovascular':
        return '${basePath}heart.svg'; // ❤️ Heart
      case 'psychiatric':
        return '${basePath}head.svg'; // 👤 Head (Mental Health) - Unique
      case 'neurology':
        return '${basePath}brain.svg'; // 🧠 Brain - Unique
      case 'dental':
        return '${basePath}tooth.svg'; // 🦷 Tooth
      case 'pediatric':
        return '${basePath}baby.svg'; // 👶 Baby
      case 'gynecology':
        return '${basePath}gyna.svg'; // 🤰 Female Repro - Unique
      case 'ophthalmology':
        return '${basePath}eye.svg'; // 👁️ Eye
      case 'orthopedics':
        return '${basePath}bone.svg'; // 🦴 Bone
      case 'anti_infective':
        return '${basePath}virus.svg'; // 🦠 Virus
      case 'dermatology':
        return '${basePath}arm.svg'; // 💪 Arm/Skin - Unique
      case 'nutrition':
        return '${basePath}nutrition.svg'; // 🍎 Nutrition
      case 'respiratory':
        return '${basePath}lungs.svg'; // 🫁 Lungs
      case 'gastroenterology':
        return '${basePath}intestine.svg'; // 🥨 Intestine - Unique
      case 'pain_relief':
        return '${basePath}medicines.svg'; // 💊 Medicines
      case 'immunology':
        return '${basePath}virus.svg'; // Immunity fallback
      case 'endocrinology':
        return '${basePath}thyroid.svg'; // 🦋 Thyroid - Unique
      case 'urology':
        return '${basePath}kidneys.svg'; // 🫘 Kidneys
      case 'hematology':
        return '${basePath}blood.svg'; // 🩸 Blood
      case 'oncology':
        return '${basePath}tumour.svg'; // 🎗️ Tumour - Unique
      case 'general':
      default:
        return '${basePath}stethoscope.svg'; // 🩺 Stethoscope
    }
  }
}
