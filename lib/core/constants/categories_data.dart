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
  // 1. Cardiovascular (القلب) - Priority 1
  CategoryData(
    id: 'cardiovascular',
    nameEn: 'Cardiovascular',
    nameAr: 'القلب والأوعية',
    shortNameEn: 'Cardio',
    shortNameAr: 'قلب',
    count: 741,
    icon: LucideIcons.heart,
    colorName: 'red',
  ),
  // 2. Anti Infective (مضادات) - Priority 2
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
  // 3. Psychiatric (المخ والأعصاب/النفسية) - Priority 3 - CHANGED to Blue
  CategoryData(
    id: 'psychiatric',
    nameEn: 'Psychiatric',
    nameAr: 'الأمراض النفسية',
    shortNameEn: 'Neuro',
    shortNameAr: 'نفسية',
    count: 534,
    icon: LucideIcons.brain,
    colorName: 'blue', // Changed from pink to blue as requested
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
    colorName: 'cyan',
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
    icon: LucideIcons.sun,
    colorName: 'orange',
  ),
  // 7. Respiratory
  CategoryData(
    id: 'respiratory',
    nameEn: 'Respiratory',
    nameAr: 'الجهاز التنفسي',
    shortNameEn: 'Resp.',
    shortNameAr: 'تنفسي',
    count: 398,
    icon: LucideIcons.wind,
    colorName: 'sky',
  ),
  // 8. Pain Relief
  CategoryData(
    id: 'pain_relief',
    nameEn: 'Pain Relief',
    nameAr: 'مسكنات',
    shortNameEn: 'Pain',
    shortNameAr: 'مسكنات',
    count: 564,
    icon: LucideIcons.zap,
    colorName: 'indigo',
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
    count: 11,
    icon: LucideIcons.activity,
    colorName: 'purple',
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
        background: appColors.dangerSoft,
        icon: appColors.dangerForeground,
        border: appColors.dangerForeground.withValues(alpha: 0.2),
      );
    case 'blue':
      return CategoryColorStyle(
        background: appColors.infoSoft, // Blue/Info
        icon: appColors.infoForeground,
        border: appColors.infoForeground.withValues(alpha: 0.2),
      );
    case 'purple':
      return CategoryColorStyle(
        background: appColors.accent,
        icon: appColors.infoForeground, // Using info/primary shade
        border: appColors.infoForeground.withValues(alpha: 0.2),
      );
    case 'green':
      return CategoryColorStyle(
        background: appColors.successSoft,
        icon: appColors.successForeground,
        border: appColors.successForeground.withValues(alpha: 0.2),
      );
    case 'orange':
      return CategoryColorStyle(
        background: appColors.warningSoft,
        icon: appColors.warningForeground,
        border: appColors.warningForeground.withValues(alpha: 0.3),
      );
    case 'teal':
      // Custom Teal-ish using Success/Secondary mix if needed, or just success
      return CategoryColorStyle(
        background: appColors.successSoft.withValues(alpha: 0.6),
        icon: appColors.successForeground,
        border: appColors.successForeground.withValues(alpha: 0.2),
      );
    case 'cyan':
      return CategoryColorStyle(
        background: appColors.infoSoft.withValues(alpha: 0.7),
        icon: appColors.infoForeground,
        border: appColors.infoForeground.withValues(alpha: 0.25),
      );
    case 'emerald':
      return CategoryColorStyle(
        background: appColors.successSoft,
        icon: appColors.successForeground,
        border: appColors.successForeground.withValues(alpha: 0.25),
      );
    case 'lime':
      return CategoryColorStyle(
        background: appColors.successSoft.withValues(alpha: 0.5),
        icon: appColors.successForeground,
        border: appColors.successForeground.withValues(alpha: 0.3),
      );
    case 'indigo':
      return CategoryColorStyle(
        background: appColors.accent,
        icon: appColors.infoForeground,
        border: appColors.infoForeground.withValues(alpha: 0.25),
      );
    case 'pink':
      return CategoryColorStyle(
        background: appColors.dangerSoft.withValues(alpha: 0.5),
        icon: appColors.dangerForeground,
        border: appColors.dangerForeground.withValues(alpha: 0.2),
      );
    case 'sky':
      return CategoryColorStyle(
        background: appColors.infoSoft.withValues(alpha: 0.5),
        icon: appColors.infoForeground,
        border: appColors.infoForeground.withValues(alpha: 0.2),
      );
    default:
      return CategoryColorStyle(
        background: appColors.infoSoft,
        icon: appColors.infoForeground,
        border: appColors.infoForeground.withValues(alpha: 0.2),
      );
  }
}
