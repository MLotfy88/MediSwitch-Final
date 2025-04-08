// lib/domain/entities/drug_interaction.dart

import 'package:equatable/equatable.dart';

import 'interaction_severity.dart'; // Import the enum
import 'interaction_type.dart'; // Import the enum

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

  // Factory constructor to create an instance from JSON
  factory DrugInteraction.fromJson(Map<String, dynamic> json) {
    return DrugInteraction(
      ingredient1: json['ingredient1'] as String? ?? '',
      ingredient2: json['ingredient2'] as String? ?? '',
      severity: _parseSeverity(json['severity'] as String? ?? ''),
      type: _parseInteractionType(json['type'] as String? ?? ''),
      effect: json['effect'] as String? ?? '',
      arabicEffect: json['arabic_effect'] as String? ?? '', // Match JSON key
      recommendation: json['recommendation'] as String? ?? '',
      arabicRecommendation:
          json['arabic_recommendation'] as String? ?? '', // Match JSON key
    );
  }

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

// Helper function to parse InteractionSeverity from string safely
InteractionSeverity _parseSeverity(String severityString) {
  return InteractionSeverity.values.firstWhere(
    (e) =>
        e.toString().split('.').last.toLowerCase() ==
        severityString.toLowerCase(),
    orElse: () => InteractionSeverity.unknown, // Default if not found
  );
}

// Helper function to parse InteractionType from string safely
InteractionType _parseInteractionType(String typeString) {
  return InteractionType.values.firstWhere(
    (e) =>
        e.toString().split('.').last.toLowerCase() == typeString.toLowerCase(),
    orElse: () => InteractionType.unknown, // Default if not found
  );
}
