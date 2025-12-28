import '../../domain/entities/drug_interaction.dart';

class DrugInteractionModel extends DrugInteraction {
  const DrugInteractionModel({
    super.id,
    required super.ingredient1,
    required super.ingredient2,
    required super.severity,
    super.effect,
    super.arabicEffect,
    super.recommendation,
    super.arabicRecommendation,
    super.source = 'DailyMed',
    super.type = 'pharmacodynamic',
    super.isPrimaryIngredient = true,
  });

  factory DrugInteractionModel.fromJson(Map<String, dynamic> json) {
    // Note: isPrimaryIngredient is usually calculated at runtime, defaulting to true or reading if present
    return DrugInteractionModel(
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
      isPrimaryIngredient:
          (json['is_primary_ingredient'] == 1 ||
                  json['is_primary_ingredient'] == true)
              ? true
              : true, // Default to true if not specified, logic in repo handles setting it
    );
  }

  @override
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

  // Database Helpers
  factory DrugInteractionModel.fromMap(Map<String, dynamic> map) {
    return DrugInteractionModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}
