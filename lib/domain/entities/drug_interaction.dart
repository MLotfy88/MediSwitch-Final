// lib/domain/entities/drug_interaction.dart

import 'package:equatable/equatable.dart';

import 'disease_interaction.dart';
import 'interaction_severity.dart'; // Import the enum

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
  final String? managementText; // New: Clinical Advice
  final String? mechanismText; // New: Mechanism
  final String? riskLevel; // New: DDInter Risk Level
  final String? ddinterId; // New: Link to DDInter DB
  final List<String>? alternativesA; // New
  final List<String>? alternativesB; // New
  final String source;
  final String type;
  final bool isPrimaryIngredient;

  const DrugInteraction({
    this.id,
    required this.ingredient1,
    required this.ingredient2,
    required this.severity,
    this.effect,
    this.arabicEffect,
    this.recommendation,
    this.arabicRecommendation,
    this.managementText,
    this.mechanismText,
    this.riskLevel,
    this.ddinterId,
    this.alternativesA,
    this.alternativesB,
    this.source = 'DailyMed',
    this.type = 'pharmacodynamic',
    this.isPrimaryIngredient = true,
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
      managementText: json['management_text'] as String?,
      mechanismText: json['mechanism_text'] as String?,
      alternativesA: DrugInteraction.parseAlternatives(json['alternatives_a']),
      alternativesB: DrugInteraction.parseAlternatives(json['alternatives_b']),
      source: json['source'] as String? ?? 'DailyMed',
      type: json['type'] as String? ?? 'pharmacodynamic',
    );
  }

  /// Creates a DrugInteraction from a DiseaseInteraction for UI compatibility.
  factory DrugInteraction.fromDisease(DiseaseInteraction disease) {
    return DrugInteraction(
      id: -1, // Dummy ID
      ingredient1: disease.tradeName,
      ingredient2: disease.diseaseName,
      severity: disease.severity,
      effect: disease.interactionText,
      source: disease.source,
      type: 'disease',
    );
  }

  static List<String>? parseAlternatives(dynamic val) {
    if (val == null) return null;
    if (val is String && val.isNotEmpty) {
      // Very basic parse assuming ["Item 1", "Item 2"] format from JSON
      final cleaned = val.replaceAll(RegExp(r'[\[\]"]'), '');
      if (cleaned.isEmpty) return null;
      return cleaned
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return null;
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
      'management_text': managementText,
      'mechanism_text': mechanismText,
      'alternatives_a': alternativesA,
      'alternatives_b': alternativesB,
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
    managementText,
    mechanismText,
    riskLevel,
    ddinterId,
    source,
    type,
  ];
}
