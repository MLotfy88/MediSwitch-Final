import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';

/// Model class for drug interactions, extending the domain entity
class DrugInteractionModel extends DrugInteraction {
  /// Creates a DrugInteractionModel instance
  const DrugInteractionModel({
    super.id,
    required super.ingredient1,
    required super.ingredient2,
    required super.severity,
    super.effect,
    super.arabicEffect,
    super.recommendation,
    super.arabicRecommendation,
    super.managementText,
    super.mechanismText,
    super.riskLevel,
    super.ddinterId,
    super.alternativesA,
    super.alternativesB,
    super.source = 'DailyMed',
    super.type = 'pharmacodynamic',
    super.isPrimaryIngredient = true,
  });

  /// Creates a DrugInteractionModel from JSON data
  factory DrugInteractionModel.fromJson(Map<String, dynamic> json) {
    return DrugInteractionModel(
      id: json['id'] as int?,
      ingredient1: json['ingredient1'] as String? ?? '',
      ingredient2: json['ingredient2'] as String? ?? '',
      severity: json['severity'] as String? ?? 'Moderate',
      effect: json['effect'] as String?,
      arabicEffect: json['arabic_effect'] as String?,
      recommendation: json['recommendation'] as String?,
      arabicRecommendation: json['arabic_recommendation'] as String?,
      managementText: _decompress(json['management_text']),
      mechanismText: _decompress(json['mechanism_text']),
      riskLevel: json['risk_level'] as String?,
      ddinterId: json['ddinter_id'] as String? ?? json['ddinterId'] as String?,
      alternativesA: DrugInteraction.parseAlternatives(json['alternatives_a']),
      alternativesB: DrugInteraction.parseAlternatives(json['alternatives_b']),
      source: json['source'] as String? ?? 'DailyMed',
      type: json['type'] as String? ?? 'pharmacodynamic',
      isPrimaryIngredient:
          json['is_primary_ingredient'] == 1 ||
          json['is_primary_ingredient'] == true,
    );
  }

  // ZLIB Decompression Helper
  static String? _decompress(dynamic content) {
    if (content == null) return null;
    if (content is String) return content;
    if (content is List<int>) {
      try {
        return utf8.decode(ZLibDecoder().decodeBytes(content));
      } catch (e) {
        try {
          return utf8.decode(content, allowMalformed: true);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
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
      'management_text': managementText,
      'mechanism_text': mechanismText,
      'risk_level': riskLevel,
      'ddinter_id': ddinterId,
      'alternatives_a': alternativesA?.join(','),
      'alternatives_b': alternativesB?.join(','),
      'source': source,
      'type': type,
    };
  }

  /// Creates a DrugInteractionModel from a database map
  factory DrugInteractionModel.fromMap(Map<String, dynamic> map) {
    return DrugInteractionModel.fromJson(map);
  }

  /// Converts the model to a database map
  Map<String, dynamic> toMap() {
    return toJson();
  }
}
