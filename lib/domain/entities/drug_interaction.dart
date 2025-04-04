// lib/domain/entities/drug_interaction.dart

import 'package:equatable/equatable.dart';

// مستوى شدة التفاعل
enum InteractionSeverity {
  minor, // منخفض
  moderate, // متوسط
  major, // عالي
  severe, // شديد الخطورة
  contraindicated, // مضاد استطباب
  unknown, // غير معروف (للتعامل مع حالات غير متوقعة)
}

// نوع التفاعل
enum InteractionType {
  pharmacokinetic, // حركية الدواء
  pharmacodynamic, // ديناميكية الدواء
  therapeutic, // علاجي
  unknown, // غير معروف
}

// نموذج التفاعل الدوائي في طبقة المجال
class DrugInteraction extends Equatable {
  final String ingredient1; // المكون النشط الأول (اسم موحد)
  final String ingredient2; // المكون النشط الثاني (اسم موحد)
  final InteractionSeverity severity; // شدة التفاعل
  final InteractionType type; // نوع التفاعل
  final String effect; // تأثير التفاعل (يفضل بالإنجليزية لسهولة المعالجة)
  final String arabicEffect; // تأثير التفاعل باللغة العربية (للعرض)
  final String recommendation; // التوصية (يفضل بالإنجليزية)
  final String arabicRecommendation; // التوصية باللغة العربية (للعرض)

  const DrugInteraction({
    required this.ingredient1,
    required this.ingredient2,
    required this.severity,
    this.type = InteractionType.unknown,
    required this.effect,
    this.arabicEffect = '',
    required this.recommendation,
    this.arabicRecommendation = '',
  });

  @override
  List<Object?> get props => [
    ingredient1,
    ingredient2,
    severity,
    type,
    effect,
    arabicEffect,
    recommendation,
    arabicRecommendation,
  ];
}
