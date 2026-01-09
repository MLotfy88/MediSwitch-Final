import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:mediswitch/domain/entities/disease_interaction.dart';

class DiseaseInteractionModel extends DiseaseInteraction {
  const DiseaseInteractionModel({
    required int medId,
    required String tradeName,
    required String diseaseName,
    required String interactionText,
    required String severity,
    String source = 'DDInter',
  }) : super(
         medId: medId,
         tradeName: tradeName,
         diseaseName: diseaseName,
         interactionText: interactionText,
         severity: severity,
         source: source,
       );

  factory DiseaseInteractionModel.fromJson(Map<String, dynamic> json) {
    return DiseaseInteractionModel(
      medId: json['med_id'] as int? ?? 0,
      tradeName: json['trade_name'] as String? ?? '',
      diseaseName: json['disease_name'] as String? ?? 'Unknown Disease',
      interactionText: _decompress(json['interaction_text']) ?? '',
      severity: json['severity'] as String? ?? 'Major',
      source: json['source'] as String? ?? 'DDInter',
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

  Map<String, dynamic> toMap() {
    return {
      'med_id': medId,
      'trade_name': tradeName,
      'disease_name': diseaseName,
      'interaction_text': interactionText,
      'severity': severity,
      'source': source,
    };
  }

  factory DiseaseInteractionModel.fromMap(Map<String, dynamic> map) {
    return DiseaseInteractionModel(
      medId: map['med_id'] as int? ?? 0,
      tradeName: map['trade_name'] as String? ?? '',
      diseaseName: map['disease_name'] as String? ?? '',
      interactionText: map['interaction_text'] as String? ?? '',
      severity: map['severity'] as String? ?? 'Major',
      source: map['source'] as String? ?? 'DDInter',
    );
  }
}
