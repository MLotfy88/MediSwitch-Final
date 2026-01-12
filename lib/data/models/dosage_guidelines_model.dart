import 'package:archive/archive.dart';
import 'dart:convert';

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
    super.ncbiIndications,
    super.ncbiAdministration,
    super.ncbiMonitoring,
    super.ncbiMechanism,
    super.structuredDosage,
  });

  factory DosageGuidelinesModel.fromJson(Map<String, dynamic> json) {
    return DosageGuidelinesModel(
      id: json['id'] as int?,
      medId: json['med_id'] as int? ?? 0,
      dailymedSetid: json['dailymed_setid'] as String?,

      // Map WikEM columns to standard fields
      minDose: (json['wikem_min_dose'] as num?)?.toDouble(),
      maxDose: (json['wikem_max_dose'] as num?)?.toDouble(),
      frequency: json['wikem_frequency'] as int?,
      duration: null,

      instructions: _decompress(json['wikem_instructions']),
      condition: null,

      source: json['source'] as String? ?? 'Hybrid',
      isPediatric: json['wikem_patient_category'] == 'Pediatric',
      route: json['wikem_route'] as String?,

      // Map NCBI columns to Rich Data Fields (cleaned)
      // Note: These fields are now likely compressed BLOBs in the DB
      contraindications: _cleanCitations(
        _decompress(json['ncbi_contraindications']),
      ),
      adverseReactions: _cleanCitations(
        _decompress(json['ncbi_adverse_effects']),
      ),
      overdoseManagement: _cleanCitations(_decompress(json['ncbi_toxicity'])),

      // Map NCBI Specific Fields (cleaned)
      ncbiIndications: _cleanCitations(_decompress(json['ncbi_indications'])),
      ncbiAdministration: _cleanCitations(
        _decompress(json['ncbi_administration']),
      ),
      ncbiMonitoring: _cleanCitations(_decompress(json['ncbi_monitoring'])),
      ncbiMechanism: _cleanCitations(_decompress(json['ncbi_mechanism'])),

      // Use WikEM BLOB for structured view
      structuredDosage:
          json['wikem_json_blob'] is List
              ? (json['wikem_json_blob'] as List).cast<int>()
              : (json['wikem_json_blob'] is String
                  ? base64Decode(json['wikem_json_blob'] as String)
                  : null),
    );
  }

  /// Helper to decompress ZLIB data if needed
  static String? _decompress(dynamic data) {
    if (data == null) return null;
    if (data is String)
      return data; // Already string (legacy or not compressed)

    if (data is List) {
      try {
        final bytes = data.cast<int>();
        if (bytes.isEmpty) return null;

        // ZLIB header check (78 9C etc) roughly, or just try decode
        // Since we compressed with python zlib (which uses zlib format),
        // we use ZLibDecoder from archive package
        final decoded = const ZLibDecoder().decodeBytes(bytes);
        return utf8.decode(decoded);
      } catch (e) {
        // Fallback or print error?
        // If it fails, maybe it wasn't compressed or different format.
        // But for this specific DB update, we know it is zlib.
        print('Error decompressing dosage field: $e');
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

  factory DosageGuidelinesModel.fromMap(Map<String, dynamic> map) {
    return DosageGuidelinesModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}
