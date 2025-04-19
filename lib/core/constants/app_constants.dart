import 'package:flutter/material.dart'; // Needed for IconData if icons were here
import 'package:lucide_icons/lucide_icons.dart';

// Centralized map for category translations
// Updated based *only* on Downloads/categuries on 2025-04-19
// Keys are now EXACT English names from the file.
const Map<String, String> kCategoryTranslation = {
  'Anesthetics': 'التخدير',
  'Anti Infective': 'مضادات العدوى',
  'Anti Inflammatory': 'مضادات الالتهاب',
  'Baby Care': 'العناية بالطفل',
  'Cardiovascular': 'القلب والأوعية الدموية',
  'Cosmetics': 'مستحضرات التجميل',
  'Diabetes Care': 'العناية بمرضى السكري',
  'Diagnostics': 'التشخيص',
  'Digestive': 'الجهاز الهضمي',
  'Ear Care': 'العناية بالأذن',
  'Eye Care': 'العناية بالعيون',
  'Hematology': 'أمراض الدم',
  'Herbal Natural': 'أعشاب ومواد طبيعية',
  'Hormonal': 'الهرمونات',
  'Immunology': 'المناعة',
  'Medical Supplies': 'مستلزمات طبية',
  'Musculoskeletal': 'الجهاز العضلي الهيكلي',
  'Neurological': 'الجهاز العصبي',
  'Oncology': 'علاج الأورام',
  'Other': 'أخرى',
  'Pain Management': 'مسكنات الألم',
  'Personal Care': 'العناية الشخصية',
  'Reproductive Health': 'الصحة الإنجابية',
  'Respiratory': 'الجهاز التنفسي',
  'Skin Care': 'العناية بالبشرة',
  'Supplements': 'المكملات الغذائية',
  'Urology': 'المسالك البولية',
  'Vitamins': 'الفيتامينات',
};

// Centralized map for category icons (using CSV keys)
// Keys MUST remain normalized (lowercase_with_underscores)
// Updated icons for medical relevance on 2025-04-19
const Map<String, IconData> kCategoryIcons = {
  'anesthetics': LucideIcons.syringe, // More specific
  'anti_infective': LucideIcons.shieldCheck, // Keep
  'anti_inflammatory': LucideIcons.shieldOff, // Keep
  'baby_care': LucideIcons.baby, // Keep
  'cardiovascular': LucideIcons.heartPulse, // Keep
  'cosmetics': LucideIcons.gem, // Keep (less medical)
  'diabetes_care': LucideIcons.droplet, // Keep
  'diagnostics': LucideIcons.stethoscope, // Keep
  'digestive': LucideIcons.soup, // Keep (maybe ActivitySquare?)
  'ear_care': LucideIcons.ear, // Keep
  'eye_care': LucideIcons.eye, // Keep
  'hematology': LucideIcons.testTube2, // Keep
  'herbal_natural': LucideIcons.sprout, // Keep
  'hormonal': LucideIcons.atom, // Keep
  'immunology': LucideIcons.shield, // Keep
  'medical_supplies': LucideIcons.archive, // Use archive icon for supplies
  'musculoskeletal': LucideIcons.bone, // Keep
  'neurological': LucideIcons.brainCircuit, // Keep
  'oncology': LucideIcons.microscope, // Keep
  'other': LucideIcons.moreHorizontal, // Keep
  'pain_management': LucideIcons.pill, // Keep
  'personal_care': LucideIcons.bath, // Keep (less medical)
  'reproductive_health': LucideIcons.heartHandshake, // Keep
  'respiratory': LucideIcons.airVent, // Keep valid icon
  'skin_care': LucideIcons.sparkles, // Keep (less medical)
  'supplements': LucideIcons.packagePlus, // Keep
  'urology': LucideIcons.filter, // Keep (maybe Droplets?)
  'vitamins': LucideIcons.leaf, // Keep
  // Fallback
  'default': LucideIcons.tag,
};
