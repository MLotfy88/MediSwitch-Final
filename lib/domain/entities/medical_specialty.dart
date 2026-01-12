import 'package:flutter/material.dart';

/// Medical specialties with their metadata
class MedicalSpecialty {
  final String id;
  final String nameEn;
  final String nameAr;
  final IconData icon;
  final Color color;
  final List<String> commonCategories;

  const MedicalSpecialty({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
    required this.color,
    required this.commonCategories,
  });

  /// List of all medical specialties
  static const List<MedicalSpecialty> all = [
    MedicalSpecialty(
      id: 'cardiology',
      nameEn: 'Cardiology',
      nameAr: 'أمراض القلب',
      icon: Icons.favorite,
      color: Color(0xFFDC2626),
      commonCategories: ['cardiovascular', 'antihypertensive', 'anticoagulant'],
    ),
    MedicalSpecialty(
      id: 'neurology',
      nameEn: 'Neurology',
      nameAr: 'المخ والأعصاب',
      icon: Icons.psychology,
      color: Color(0xFF7C3AED),
      commonCategories: ['neurological', 'anticonvulsant', 'analgesic'],
    ),
    MedicalSpecialty(
      id: 'endocrinology',
      nameEn: 'Endocrinology',
      nameAr: 'الغدد الصماء',
      icon: Icons.science,
      color: Color(0xFF0891B2),
      commonCategories: ['diabetes', 'hormonal', 'thyroid'],
    ),
    MedicalSpecialty(
      id: 'gastroenterology',
      nameEn: 'Gastroenterology',
      nameAr: 'الجهاز الهضمي',
      icon: Icons.local_hospital,
      color: Color(0xFFEA580C),
      commonCategories: ['gastrointestinal', 'antacid', 'laxative'],
    ),
    MedicalSpecialty(
      id: 'pulmonology',
      nameEn: 'Pulmonology',
      nameAr: 'أمراض الصدر',
      icon: Icons.air,
      color: Color(0xFF06B6D4),
      commonCategories: ['respiratory', 'bronchodilator', 'asthma'],
    ),
    MedicalSpecialty(
      id: 'nephrology',
      nameEn: 'Nephrology',
      nameAr: 'أمراض الكلى',
      icon: Icons.water_drop,
      color: Color(0xFF3B82F6),
      commonCategories: ['renal', 'diuretic', 'kidney'],
    ),
    MedicalSpecialty(
      id: 'rheumatology',
      nameEn: 'Rheumatology',
      nameAr: 'الروماتيزم',
      icon: Icons.accessibility_new,
      color: Color(0xFFF59E0B),
      commonCategories: ['rheumatic', 'anti-inflammatory', 'immunosuppressant'],
    ),
    MedicalSpecialty(
      id: 'infectious_disease',
      nameEn: 'Infectious Disease',
      nameAr: 'الأمراض المعدية',
      icon: Icons.biotech,
      color: Color(0xFF10B981),
      commonCategories: ['antibiotic', 'antiviral', 'antifungal'],
    ),
    MedicalSpecialty(
      id: 'oncology',
      nameEn: 'Oncology',
      nameAr: 'الأورام',
      icon: Icons.healing,
      color: Color(0xFFEC4899),
      commonCategories: ['chemotherapy', 'cancer', 'immunotherapy'],
    ),
    MedicalSpecialty(
      id: 'psychiatry',
      nameEn: 'Psychiatry',
      nameAr: 'الطب النفسي',
      icon: Icons.self_improvement,
      color: Color(0xFF8B5CF6),
      commonCategories: ['psychiatric', 'antidepressant', 'antipsychotic'],
    ),
    MedicalSpecialty(
      id: 'dermatology',
      nameEn: 'Dermatology',
      nameAr: 'الأمراض الجلدية',
      icon: Icons.face,
      color: Color(0xFFF97316),
      commonCategories: ['dermatological', 'topical', 'skin'],
    ),
    MedicalSpecialty(
      id: 'general_medicine',
      nameEn: 'General Medicine',
      nameAr: 'الطب العام',
      icon: Icons.medical_services,
      color: Color(0xFF6B7280),
      commonCategories: ['general', 'primary_care', 'common'],
    ),
  ];
}
