import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:mediswitch/domain/entities/dosage_guidelines.dart';

/// Model class for DosageGuidelines with JSON parsing logic.
class DosageGuidelinesModel extends DosageGuidelines {
  /// Default constructor for DosageGuidelinesModel.
  const DosageGuidelinesModel({
    required super.medId,
    super.id,
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
    super.ncbiIndications,
    super.ncbiAdministration,
    super.ncbiMonitoring,
    super.ncbiMechanism,
    super.structuredDosage,
  });

  /// Factory constructor to create a [DosageGuidelinesModel] from a JSON map.
  /// Handles both API (WikEM/NCBI) keys and Local DB keys.
  factory DosageGuidelinesModel.fromJson(Map<String, dynamic> json) {
    return DosageGuidelinesModel(
      id: json['id'] as int?,
      medId: (json['med_id'] as int?) ?? 0,
      dailymedSetid: json['dailymed_setid'] as String?,

      // Map WikEM columns to standard fields (API ?? Local)
      minDose:
          ((json['wikem_min_dose'] ?? json['min_dose']) as num?)?.toDouble(),
      maxDose:
          ((json['wikem_max_dose'] ?? json['max_dose']) as num?)?.toDouble(),
      frequency: (json['wikem_frequency'] ?? json['frequency']) as int?,
      duration: json['duration'] as int?,

      instructions: _decompress(
        json['wikem_instructions'] ?? json['instructions'],
      ),
      condition:
          (json['wikem_patient_category'] ?? json['condition']) as String?,

      source: (json['source'] as String?) ?? 'Hybrid',

      // Pediatric check - handle API string 'Pediatric' vs Local int boolean 1
      isPediatric:
          (json['wikem_patient_category'] == 'Pediatric') ||
          (json['is_pediatric'] == 1) ||
          (json['is_pediatric'] == true),

      route: (json['wikem_route'] ?? json['route']) as String?,

      // Map NCBI columns to Rich Data Fields (cleaned) (API ?? Local)
      contraindications: _cleanCitations(
        _decompress(
          json['ncbi_contraindications'] ?? json['contraindications'],
        ),
      ),
      adverseReactions: _cleanCitations(
        _decompress(json['ncbi_adverse_effects'] ?? json['adverse_reactions']),
      ),
      overdoseManagement: _cleanCitations(
        _decompress(json['ncbi_toxicity'] ?? json['overdose_management']),
      ),

      // Map NCBI Specific Fields (cleaned)
      ncbiIndications: _cleanCitations(
        _decompress(json['ncbi_indications'] ?? json['ncbi_indications']),
      ),

      ncbiAdministration: _cleanCitations(
        _decompress(json['ncbi_administration'] ?? json['ncbi_administration']),
      ),
      ncbiMonitoring: _cleanCitations(
        _decompress(json['ncbi_monitoring'] ?? json['ncbi_monitoring']),
      ),
      ncbiMechanism: _cleanCitations(
        _decompress(json['ncbi_mechanism'] ?? json['ncbi_mechanism']),
      ),

      // Rich fields existing in DB but not API directly (mapped manually)
      warnings: _decompress(json['warnings']),
      renalAdjustment: _decompress(json['renal_adjustment']),
      hepaticAdjustment: _decompress(json['hepatic_adjustment']),
      blackBoxWarning: _decompress(json['black_box_warning']),
      pregnancyCategory: _decompress(json['pregnancy_category']),
      lactationInfo: _decompress(json['lactation_info']),
      specialPopulations: _decompress(json['special_populations']),

      // Use WikEM BLOB for structured view
      structuredDosage: _parseStructuredDosage(json),
    );
  }

  /// Factory constructor alias for [fromJson].
  factory DosageGuidelinesModel.fromMap(Map<String, dynamic> map) {
    return DosageGuidelinesModel.fromJson(map);
  }

  /// Converts the model instance to a JSON map.
  Map<String, dynamic> toMap() => toJson();

  /// Converts the model instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'med_id': medId,
      'dailymed_setid': dailymedSetid,
      'min_dose': minDose,
      'max_dose': maxDose,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
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
      'ncbi_indications': ncbiIndications,
      'ncbi_administration': ncbiAdministration,
      'ncbi_monitoring': ncbiMonitoring,
      'ncbi_mechanism': ncbiMechanism,
    };
  }

  /// Parses the structured dosage blob from varied sources
  static List<int>? _parseStructuredDosage(Map<String, dynamic> json) {
    var blob = json['wikem_json_blob'] ?? json['structured_dosage'];

    if (blob == null) return null;

    if (blob is List) {
      return blob.cast<int>();
    } else if (blob is String) {
      try {
        return base64Decode(blob);
      } catch (e) {
        debugPrint('Error decoding base64 structured dosage: $e');
        return null;
      }
    }
    return null;
  }

  /// Helper to decompress ZLIB data if needed - Recursive support
  static String? _decompress(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;

    if (data is List) {
      try {
        final bytes = data.cast<int>();
        if (bytes.isEmpty) return null;

        final decoded = const ZLibDecoder().decodeBytes(bytes);
        // Recursive check for nested compression
        if (decoded.length >= 2 &&
            decoded[0] == 0x78 &&
            (decoded[1] == 0x9C || decoded[1] == 0x01 || decoded[1] == 0xDA)) {
          return _decompress(decoded);
        }
        return utf8.decode(decoded);
      } on Exception catch (e) {
        debugPrint('Error decompressing dosage field: $e');
        return null;
      }
    }
    return null;
  }

  /// Remove citation markers like [1], [17], [3] from text
  static String? _cleanCitations(String? text) {
    if (text == null || text.isEmpty) return text;
    // Remove [number] patterns
    return text.replaceAll(RegExp(r'\[\d+\]'), '').trim();
  }
}
