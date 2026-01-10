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
      frequency:
          json['wikem_frequency'] as int?, // Assumed column existence or null
      duration: null, // Removed in new schema

      instructions: json['wikem_instructions'] as String?,
      condition: null, // Removed in new schema

      source: json['source'] as String? ?? 'Hybrid',
      isPediatric: json['wikem_patient_category'] == 'Pediatric',
      route: json['wikem_route'] as String?,

      // Map NCBI columns to Rich Data Fields
      contraindications: json['ncbi_contraindications'] as String?,
      adverseReactions: json['ncbi_adverse_effects'] as String?,
      overdoseManagement: json['ncbi_toxicity'] as String?,

      // Map NCBI Specific Fields
      ncbiIndications: json['ncbi_indications'] as String?,
      ncbiAdministration: json['ncbi_administration'] as String?,
      ncbiMonitoring: json['ncbi_monitoring'] as String?,
      ncbiMechanism: json['ncbi_mechanism'] as String?,

      // Use WikEM BLOB for structured view (it has the dosage arrays)
      structuredDosage:
          json['wikem_json_blob'] is List
              ? (json['wikem_json_blob'] as List).cast<int>()
              : (json['wikem_json_blob'] is String
                  ? base64Decode(
                    json['wikem_json_blob'] as String,
                  ) // Explicit cast
                  : null),
    );
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
