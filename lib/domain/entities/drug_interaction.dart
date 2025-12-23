// lib/domain/entities/drug_interaction.dart

import 'package:equatable/equatable.dart';

import 'interaction_severity.dart'; // Import the enum
import 'interaction_type.dart'; // Import the enum

// نموذج التفاعل الدوائي في طبقة المجال
class DrugInteraction extends Equatable {
  final int? id;
  final String ingredient1;
  final String ingredient2;
  final String severity;
  final String? effect;
  final String? arabicEffect;
  final String? recommendation;
  final String? arabicRecommendation;
  final String source;
  final String type;

  const DrugInteraction({
    this.id,
    required this.ingredient1,
    required this.ingredient2,
    required this.severity,
    this.effect,
    this.arabicEffect,
    this.recommendation,
    this.arabicRecommendation,
    this.source = 'DailyMed',
    this.type = 'pharmacodynamic',
  });

  // Factory constructor to create an instance from JSON
  factory DrugInteraction.fromJson(Map<String, dynamic> json) {
    return DrugInteraction(
      id: json['id'] as int?,
      ingredient1: json['ingredient1'] as String? ?? '',
      ingredient2: json['ingredient2'] as String? ?? '',
      severity: json['severity'] as String? ?? 'Moderate',
      effect: json['effect'] as String?,
      arabicEffect: json['arabic_effect'] as String?,
      recommendation: json['recommendation'] as String?,
      arabicRecommendation: json['arabic_recommendation'] as String?,
      source: json['source'] as String? ?? 'DailyMed',
      type: json['type'] as String? ?? 'pharmacodynamic',
    );
  }

  // Method to convert instance back to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredient1': ingredient1,
      'ingredient2': ingredient2,
      'severity': severity,
      'effect': effect,
      'arabic_effect': arabicEffect,
      'recommendation': recommendation,
      'arabic_recommendation': arabicRecommendation,
      'source': source,
      'type': type,
    };
  }

  InteractionSeverity get severityEnum {
    switch (severity.toLowerCase()) {
      case 'contraindicated':
        return InteractionSeverity.contraindicated;
      case 'severe':
        return InteractionSeverity.severe;
      case 'major':
        return InteractionSeverity.major;
      case 'moderate':
        return InteractionSeverity.moderate;
      case 'minor':
        return InteractionSeverity.minor;
      default:
        return InteractionSeverity.unknown;
    }
  }

  @override
  List<Object?> get props => [
    id,
    ingredient1,
    ingredient2,
    severity,
    effect,
    arabicEffect,
    recommendation,
    arabicRecommendation,
    source,
    type,
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
