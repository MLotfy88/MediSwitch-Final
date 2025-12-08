import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';

class CategoryData {
  final String id;
  final String nameEn;
  final String nameAr;
  final int count;
  final IconData icon;
  final String colorName;

  const CategoryData({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.count,
    required this.icon,
    required this.colorName,
  });
}

// القاموس الرئيسي للفئات بناءً على بيانات قاعدة البيانات مع تحسين الأيقونات
final List<CategoryData> kAllCategories = [
  CategoryData(
    id: 'anti_infective',
    nameEn: 'Anti Infective',
    nameAr: 'مضادات العدوى',
    count: 1468,
    icon: LucideIcons.bug, // محاربة العدوى/البكتيريا
    colorName: 'teal',
  ),
  CategoryData(
    id: 'cardiovascular',
    nameEn: 'Cardiovascular',
    nameAr: 'القلب والأوعية',
    count: 741,
    icon: LucideIcons.heart, // Heart كما في التصميم المرجعي
    colorName: 'red',
  ),
  CategoryData(
    id: 'dermatology',
    nameEn: 'Dermatology',
    nameAr: 'الجلدية',
    count: 1280,
    icon: LucideIcons.sun, // الشمس/البشرة والحروق
    colorName: 'orange',
  ),
  CategoryData(
    id: 'endocrinology',
    nameEn: 'Endocrinology',
    nameAr: 'الغدد الصماء',
    count: 11,
    icon: LucideIcons.activity, // النشاط الحيوي/الهرمونات
    colorName: 'purple',
  ),
  CategoryData(
    id: 'general',
    nameEn: 'General',
    nameAr: 'عام',
    count: 17009,
    icon: LucideIcons.stethoscope, // السماعة الطبية - رمز عام
    colorName: 'blue',
  ),
  CategoryData(
    id: 'immunology',
    nameEn: 'Immunology',
    nameAr: 'المناعة',
    count: 276,
    icon: LucideIcons.shieldCheck, // الدرع - رمز المناعة والحماية
    colorName: 'green',
  ),
  CategoryData(
    id: 'nutrition',
    nameEn: 'Nutrition',
    nameAr: 'التغذية',
    count: 3219,
    icon: LucideIcons.apple, // التفاحة - رمز التغذية والصحة
    colorName: 'green',
  ),
  CategoryData(
    id: 'pain_relief',
    nameEn: 'Pain Relief',
    nameAr: 'مسكنات',
    count: 564,
    icon: LucideIcons.zap, // البرق - ترمز للألم أو تسكينه السريع
    colorName: 'blue',
  ),
  CategoryData(
    id: 'psychiatric',
    nameEn: 'Psychiatric',
    nameAr: 'الأمراض النفسية',
    count: 534,
    icon: LucideIcons.brain, // الدماغ - رمز الصحة النفسية
    colorName: 'purple',
  ),
  CategoryData(
    id: 'respiratory',
    nameEn: 'Respiratory',
    nameAr: 'الجهاز التنفسي',
    count: 398,
    icon: LucideIcons.wind, // الهواء/الرياح - رمز التنفس
    colorName: 'blue',
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
        background: appColors.infoSoft,
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
    default:
      return CategoryColorStyle(
        background: appColors.infoSoft,
        icon: appColors.infoForeground,
        border: appColors.infoForeground.withValues(alpha: 0.2),
      );
  }
}
