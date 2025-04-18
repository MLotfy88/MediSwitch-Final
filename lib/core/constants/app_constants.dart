import 'package:flutter/material.dart'; // Needed for IconData if icons were here
import 'package:lucide_icons/lucide_icons.dart';

// Centralized map for category translations
const Map<String, String> kCategoryTranslation = {
  'anti_inflammatory': 'مضادات الالتهاب',
  'cold_respiratory': 'أدوية البرد والجهاز التنفسي',
  'cosmetics': 'مستحضرات تجميل',
  'digestive': 'أدوية الجهاز الهضمي',
  'pain_management': 'مسكنات الألم',
  'personal_care': 'عناية شخصية',
  'probiotics': 'بروبيوتيك',
  'skin_care': 'عناية بالبشرة',
  'soothing': 'ملطفات',
  'supplements': 'مكملات غذائية',
  'vitamins': 'فيتامينات',
  // Add 'other' or any missing categories if needed
  'other': 'أخرى', // Added 'other' category
};

// Centralized map for category icons (using CSV keys)
const Map<String, IconData> kCategoryIcons = {
  'anti_inflammatory': LucideIcons.shieldOff,
  'cold_respiratory': LucideIcons.wind,
  'cosmetics': LucideIcons.gem,
  'digestive': LucideIcons.soup,
  'pain_management': LucideIcons.pill,
  'personal_care': LucideIcons.bath,
  'probiotics': LucideIcons.flaskConical,
  'skin_care': LucideIcons.sparkles,
  'soothing': LucideIcons.feather,
  'supplements': LucideIcons.packagePlus,
  'vitamins': LucideIcons.leaf,
  'default': LucideIcons.tag, // Fallback icon
  'other': LucideIcons.moreHorizontal, // Added icon for 'other'
};
