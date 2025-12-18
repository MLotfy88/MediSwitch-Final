import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';

class CategoryData {
  final String id;
  final String nameEn;
  final String nameAr;
  final String
  shortNameEn; // Abbreviated English name for consistent card sizes
  final String shortNameAr; // Abbreviated Arabic name for consistent card sizes
  final int count;
  final IconData icon;
  final String colorName;

  const CategoryData({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.shortNameEn,
    required this.shortNameAr,
    required this.count,
    required this.icon,
    required this.colorName,
  });
}

// القاموس الرئيسي للفئات بناءً على بيانات قاعدة البيانات مع تحسين الأيقونات
final List<CategoryData> kAllCategories = [
  // 1. Cardiovascular (القلب)
  CategoryData(
    id: 'cardiovascular',
    nameEn: 'Cardiovascular',
    nameAr: 'القلب والأوعية',
    shortNameEn: 'Cardio',
    shortNameAr: 'قلب',
    count: 741,
    icon: LucideIcons.heartPulse,
    colorName: 'rose',
  ),
  // 2. Anti Infective (مضادات)
  CategoryData(
    id: 'anti_infective',
    nameEn: 'Anti Infective',
    nameAr: 'مضادات العدوى',
    shortNameEn: 'Anti Inf.',
    shortNameAr: 'مضادات',
    count: 1468,
    icon: LucideIcons.bug,
    colorName: 'teal',
  ),
  // 3. Psychiatric (المخ والأعصاب/النفسية)
  CategoryData(
    id: 'psychiatric',
    nameEn: 'Psychiatric',
    nameAr: 'الأمراض النفسية',
    shortNameEn: 'Psych',
    shortNameAr: 'نفسية',
    count: 534,
    icon: LucideIcons.brain,
    colorName: 'violet',
  ),
  // 4. General
  CategoryData(
    id: 'general',
    nameEn: 'General',
    nameAr: 'عام',
    shortNameEn: 'General',
    shortNameAr: 'عام',
    count: 17009,
    icon: LucideIcons.stethoscope,
    colorName: 'slate',
  ),
  // 5. Nutrition
  CategoryData(
    id: 'nutrition',
    nameEn: 'Nutrition',
    nameAr: 'التغذية',
    shortNameEn: 'Nutrition',
    shortNameAr: 'تغذية',
    count: 3219,
    icon: LucideIcons.apple,
    colorName: 'lime',
  ),
  // 6. Dermatology
  CategoryData(
    id: 'dermatology',
    nameEn: 'Dermatology',
    nameAr: 'الجلدية',
    shortNameEn: 'Derma',
    shortNameAr: 'جلدية',
    count: 1280,
    icon: Icons.face, // Skin/Face
    colorName: 'amber',
  ),
  // 7. Respiratory
  CategoryData(
    id: 'respiratory',
    nameEn: 'Respiratory',
    nameAr: 'الجهاز التنفسي',
    shortNameEn: 'Resp.',
    shortNameAr: 'تنفسي',
    count: 398,
    icon: Icons.air, // Air/Breath
    colorName: 'cyan',
  ),
  // 8. Pain Relief
  CategoryData(
    id: 'pain_relief',
    nameEn: 'Pain Relief',
    nameAr: 'مسكنات',
    shortNameEn: 'Pain',
    shortNameAr: 'مسكنات',
    count: 564,
    icon: Icons.healing, // Bandage/Medication
    colorName: 'red',
  ),
  // 9. Immunology
  CategoryData(
    id: 'immunology',
    nameEn: 'Immunology',
    nameAr: 'المناعة',
    shortNameEn: 'Immune',
    shortNameAr: 'مناعة',
    count: 276,
    icon: LucideIcons.shieldCheck,
    colorName: 'emerald',
  ),
  // 10. Endocrinology
  CategoryData(
    id: 'endocrinology',
    nameEn: 'Endocrinology',
    nameAr: 'الغدد الصماء',
    shortNameEn: 'Endo',
    shortNameAr: 'غدد',
    count: 0,
    icon: Icons.science, // Lab/Hormones
    colorName: 'purple',
  ),
  // 11. Gastroenterology
  CategoryData(
    id: 'gastroenterology',
    nameEn: 'Gastroenterology',
    nameAr: 'الجهاز الهضمي',
    shortNameEn: 'GIT',
    shortNameAr: 'هضمي',
    count: 0,
    icon: Icons.spa, // Wellness/Digestion
    colorName: 'orange',
  ),
  // 12. Neurology
  CategoryData(
    id: 'neurology',
    nameEn: 'Neurology',
    nameAr: 'المخ والأعصاب',
    shortNameEn: 'Neuro',
    shortNameAr: 'أعصاب',
    count: 0,
    icon: LucideIcons.brainCircuit,
    colorName: 'indigo',
  ),
  // 13. Urology
  CategoryData(
    id: 'urology',
    nameEn: 'Urology',
    nameAr: 'المسالك البولية',
    shortNameEn: 'Uro',
    shortNameAr: 'مسالك',
    count: 0,
    icon: LucideIcons.droplets,
    colorName: 'sky',
  ),
  // 14. Ophthalmology
  CategoryData(
    id: 'ophthalmology',
    nameEn: 'Ophthalmology',
    nameAr: 'العيون',
    shortNameEn: 'Eye',
    shortNameAr: 'عيون',
    count: 0,
    icon: LucideIcons.eye,
    colorName: 'blue',
  ),
  // 15. Gynecology
  CategoryData(
    id: 'gynecology',
    nameEn: 'Gynecology',
    nameAr: 'النساء والتوليد',
    shortNameEn: 'Gyna',
    shortNameAr: 'نساء',
    count: 0,
    icon: Icons.pregnant_woman,
    colorName: 'pink',
  ),
  // 16. Orthopedics
  CategoryData(
    id: 'orthopedics',
    nameEn: 'Orthopedics',
    nameAr: 'العظام',
    shortNameEn: 'Ortho',
    shortNameAr: 'عظام',
    count: 0,
    icon: LucideIcons.bone,
    colorName: 'stone',
  ),
  // 17. Hematology
  CategoryData(
    id: 'hematology',
    nameEn: 'Hematology',
    nameAr: 'أماض الدم',
    shortNameEn: 'Blood',
    shortNameAr: 'دم',
    count: 0,
    icon: Icons.bloodtype,
    colorName: 'crimson',
  ),
  // 18. Oncology
  CategoryData(
    id: 'oncology',
    nameEn: 'Oncology',
    nameAr: 'الأورام',
    shortNameEn: 'Onco',
    shortNameAr: 'أورام',
    count: 0,
    icon: LucideIcons.microscope,
    colorName: 'fuchsia',
  ),
];

class CategoryColorStyle {
  final Color background;
  final Color icon;
  final Color border;

  CategoryColorStyle({
    required this.background,
    required this.icon,
    required this.border,
  });
}

CategoryColorStyle getCategoryColorStyle(
  String colorName,
  AppColorsExtension appColors,
) {
  switch (colorName) {
    case 'red':
      return CategoryColorStyle(
        background: appColors.dangerSoft.withValues(alpha: 0.4),
        icon: appColors.dangerForeground,
        border: appColors.dangerForeground.withValues(alpha: 0.2),
      );
    case 'rose':
      return CategoryColorStyle(
        background: Colors.pink.shade100.withValues(alpha: 0.4),
        icon: Colors.pink.shade700,
        border: Colors.pink.shade700.withValues(alpha: 0.2),
      );
    case 'blue':
      return CategoryColorStyle(
        background: appColors.infoSoft.withValues(alpha: 0.4),
        icon: appColors.infoForeground,
        border: appColors.infoForeground.withValues(alpha: 0.2),
      );
    case 'sky':
      return CategoryColorStyle(
        background: Colors.lightBlue.shade100.withValues(alpha: 0.4),
        icon: Colors.lightBlue.shade700,
        border: Colors.lightBlue.shade700.withValues(alpha: 0.2),
      );
    case 'cyan':
      return CategoryColorStyle(
        background: Colors.cyan.shade100.withValues(alpha: 0.4),
        icon: Colors.cyan.shade700,
        border: Colors.cyan.shade700.withValues(alpha: 0.2),
      );
    case 'teal':
      return CategoryColorStyle(
        background: appColors.successSoft.withValues(alpha: 0.4),
        icon: appColors.successForeground,
        border: appColors.successForeground.withValues(alpha: 0.2),
      );
    case 'emerald':
      return CategoryColorStyle(
        background: Colors.green.shade100.withValues(alpha: 0.4),
        icon: Colors.green.shade700,
        border: Colors.green.shade700.withValues(alpha: 0.2),
      );
    case 'green':
      return CategoryColorStyle(
        background: Colors.green.shade50.withValues(alpha: 0.4),
        icon: Colors.green.shade800,
        border: Colors.green.shade800.withValues(alpha: 0.2),
      );
    case 'lime':
      return CategoryColorStyle(
        background: Colors.lime.shade100.withValues(alpha: 0.4),
        icon: Colors.lime.shade800,
        border: Colors.lime.shade800.withValues(alpha: 0.2),
      );
    case 'amber':
      return CategoryColorStyle(
        background: Colors.amber.shade100.withValues(alpha: 0.4),
        icon: Colors.amber.shade800,
        border: Colors.amber.shade800.withValues(alpha: 0.2),
      );
    case 'orange':
      return CategoryColorStyle(
        background: appColors.warningSoft.withValues(alpha: 0.4),
        icon: appColors.warningForeground,
        border: appColors.warningForeground.withValues(alpha: 0.3),
      );
    case 'purple':
      return CategoryColorStyle(
        background: appColors.accent.withValues(alpha: 0.5),
        icon: appColors.infoForeground,
        border: appColors.infoForeground.withValues(alpha: 0.2),
      );
    case 'violet':
      return CategoryColorStyle(
        background: Colors.deepPurple.shade100.withValues(alpha: 0.4),
        icon: Colors.deepPurple.shade700,
        border: Colors.deepPurple.shade700.withValues(alpha: 0.2),
      );
    case 'indigo':
      return CategoryColorStyle(
        background: Colors.indigo.shade100.withValues(alpha: 0.4),
        icon: Colors.indigo.shade700,
        border: Colors.indigo.shade700.withValues(alpha: 0.2),
      );
    case 'pink':
      return CategoryColorStyle(
        background: Colors.pinkAccent.shade100.withValues(alpha: 0.4),
        icon: Colors.pinkAccent.shade700,
        border: Colors.pinkAccent.shade700.withValues(alpha: 0.2),
      );
    case 'fuchsia':
      return CategoryColorStyle(
        background: Colors.purpleAccent.shade100.withValues(alpha: 0.4),
        icon: Colors.purpleAccent.shade700,
        border: Colors.purpleAccent.shade700.withValues(alpha: 0.2),
      );
    case 'slate':
      return CategoryColorStyle(
        background: Colors.blueGrey.shade100.withValues(alpha: 0.4),
        icon: Colors.blueGrey.shade700,
        border: Colors.blueGrey.shade700.withValues(alpha: 0.2),
      );
    case 'stone':
      return CategoryColorStyle(
        background: Colors.brown.shade100.withValues(alpha: 0.4),
        icon: Colors.brown.shade700,
        border: Colors.brown.shade700.withValues(alpha: 0.2),
      );
    case 'crimson':
      return CategoryColorStyle(
        background: Colors.red.shade100.withValues(alpha: 0.4),
        icon: Colors.red.shade900,
        border: Colors.red.shade900.withValues(alpha: 0.2),
      );
    default:
      return CategoryColorStyle(
        background: appColors.infoSoft.withValues(alpha: 0.4),
        icon: appColors.infoForeground,
        border: appColors.infoForeground.withValues(alpha: 0.2),
      );
  }
}
