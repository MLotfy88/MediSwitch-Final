class DosageGuidelines {
  final int? id;
  final int medId; // Relational link to Drug
  final String? dailymedSetid;
  final double? minDose;
  final double? maxDose;
  final int? frequency;
  final int? duration;
  final String? instructions;
  final String? condition;
  final String source; // 'DailyMed' or 'Local'
  final bool isPediatric;
  final String? route;

  // New Rich Data Fields
  final String? warnings;
  final String? contraindications;
  final String? adverseReactions;
  final String? renalAdjustment;
  final String? hepaticAdjustment;
  final String? blackBoxWarning;
  final String? overdoseManagement;
  final String? pregnancyCategory;
  final String? lactationInfo;
  final String? specialPopulations;

  // Offline Structured Data (ZLIB Compressed JSON)
  final List<int>? structuredDosage;

  const DosageGuidelines({
    this.id,
    required this.medId,
    this.dailymedSetid,
    this.minDose,
    this.maxDose,
    this.frequency,
    this.duration,
    this.instructions,
    this.condition,
    this.source = 'Local',
    this.isPediatric = false,
    this.route,
    this.warnings,
    this.contraindications,
    this.adverseReactions,
    this.renalAdjustment,
    this.hepaticAdjustment,
    this.blackBoxWarning,
    this.overdoseManagement,
    this.pregnancyCategory,
    this.lactationInfo,
    this.specialPopulations,
    this.structuredDosage,
  });

  factory DosageGuidelines.fromJson(Map<String, dynamic> json) {
    return DosageGuidelines(
      id: json['id'] as int?,
      medId: json['med_id'] as int? ?? 0,
      dailymedSetid: json['dailymed_setid'] as String?,
      minDose: (json['min_dose'] as num?)?.toDouble(),
      maxDose: (json['max_dose'] as num?)?.toDouble(),
      frequency: json['frequency'] as int?,
      duration: json['duration'] as int?,
      instructions: json['instructions'] as String?,
      condition: json['condition'] as String?,
      source: json['source'] as String? ?? 'Local',
      isPediatric: json['is_pediatric'] == 1 || json['is_pediatric'] == true,
      route: json['route'] as String?,
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
      'instructions': instructions,
      'condition': condition,
      'source': source,
      'is_pediatric': isPediatric ? 1 : 0,
      'route': route,
    };
  }
}
