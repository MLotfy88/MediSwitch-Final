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
/// Map of category keys to their corresponding icons.
final Map<String, IconData> kCategoryIcons = {
  'anesthetics': LucideIcons.syringe,
  'anti_infective': LucideIcons.shieldCheck,
  'anti_inflammatory': LucideIcons.flame,
  'baby_care': LucideIcons.baby,
  'cardiovascular': LucideIcons.heartPulse,
  'cosmetics': LucideIcons.sparkles,
  'diabetes_care': LucideIcons.droplet,
  'diagnostics': LucideIcons.stethoscope,
  'digestive': LucideIcons.utensils,
  'ear_care': LucideIcons.ear,
  'eye_care': LucideIcons.eye,
  'hematology': LucideIcons.testTube2,
  'herbal_natural': LucideIcons.leaf,
  'hormonal': LucideIcons.dna,
  'immunology': LucideIcons.shield,
  'medical_supplies': LucideIcons.briefcase, // Changed from briefcaseMedical
  'musculoskeletal': LucideIcons.activity,
  'neurological': LucideIcons.brainCircuit,
  'oncology': LucideIcons.microscope,
  'other': LucideIcons.moreHorizontal,
  'pain_management': LucideIcons.pill,
  'personal_care': LucideIcons.user,
  'reproductive_health': LucideIcons.heartHandshake,
  'respiratory': LucideIcons.airVent,
  'skin_care': LucideIcons.sun,
  'supplements': LucideIcons.apple,
  'urology': LucideIcons.droplets,
  'vitamins': LucideIcons.citrus,
  // Fallback
  'default': LucideIcons.tag,
};
