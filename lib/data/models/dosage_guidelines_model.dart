import 'dart:convert';

import 'package:archive/archive.dart';

import '../../domain/entities/dosage_guidelines.dart';

class DosageGuidelinesModel extends DosageGuidelines {
  const DosageGuidelinesModel({
    super.id,
    required super.medId,
    super.dailymedSetid,
    super.minDose,
    super.maxDose,
    super.frequency,
    super.duration,
    super.instructions,
    super.condition,
    super.source = 'Local',
    super.isPediatric = false,
    super.route,
    super.warnings,
    super.contraindications,
    super.adverseReactions,
    super.renalAdjustment,
    super.hepaticAdjustment,
    super.blackBoxWarning,
    super.overdoseManagement,
    super.pregnancyCategory,
    super.lactationInfo,
    super.specialPopulations,
  });

  factory DosageGuidelinesModel.fromJson(Map<String, dynamic> json) {
    return DosageGuidelinesModel(
      id: json['id'] as int?,
      medId: json['med_id'] as int? ?? 0,
      dailymedSetid: json['dailymed_setid'] as String?,
      minDose: (json['min_dose'] as num?)?.toDouble(),
      maxDose: (json['max_dose'] as num?)?.toDouble(),
      frequency: json['frequency'] as int?,
      duration: json['duration'] as int?,

      // Text Fields with Auto-Decompression
      instructions: _decompress(json['instructions']),
      condition: _decompress(json['condition']),
      warnings: _decompress(json['warnings']),
      contraindications: _decompress(json['contraindications']),
      adverseReactions: _decompress(json['adverse_reactions']),
      renalAdjustment: _decompress(json['renal_adjustment']),
      hepaticAdjustment: _decompress(json['hepatic_adjustment']),
      blackBoxWarning: _decompress(json['black_box_warning']),
      overdoseManagement: _decompress(json['overdose_management']),
      pregnancyCategory: _decompress(json['pregnancy_category']),
      lactationInfo: _decompress(json['lactation_info']),
      specialPopulations: _decompress(json['special_populations']),

      source: json['source'] as String? ?? 'DailyMed',
      isPediatric: json['is_pediatric'] == 1 || json['is_pediatric'] == true,
      route: json['route'] as String?,
    );
  }

  // ZLIB Decompression Helper
  static String? _decompress(dynamic content) {
    if (content == null) return null;
    if (content is String) return content; // Already parsed or plain text
    if (content is List<int>) {
      try {
        // Import archive package is needed at top of file
        // But for now assuming clean helper.
        // We need to add 'import 'package:archive/archive.dart';'
        return utf8.decode(ZLibDecoder().decodeBytes(content));
      } catch (e) {
        // Fallback if decompression fails (maybe plain bytes?)
        try {
          return utf8.decode(content, allowMalformed: true);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'med_id': medId,
      'dailymed_setid': dailymedSetid,
      'min_dose': minDose,
      'max_dose': maxDose,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions, // We keep it decompressed in memory
      'condition': condition,
      'source': source,
      'is_pediatric': isPediatric ? 1 : 0,
      'route': route,
      'warnings': warnings,
      'contraindications': contraindications,
      'adverse_reactions': adverseReactions,
      'renal_adjustment': renalAdjustment,
      'hepatic_adjustment': hepaticAdjustment,
      'black_box_warning': blackBoxWarning,
      'overdose_management': overdoseManagement,
      'pregnancy_category': pregnancyCategory,
      'lactation_info': lactationInfo,
      'special_populations': specialPopulations,
    };
  }

  factory DosageGuidelinesModel.fromMap(Map<String, dynamic> map) {
    return DosageGuidelinesModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}
