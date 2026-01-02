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
      instructions: json['instructions'] as String?,
      condition: json['condition'] as String?,
      source: json['source'] as String? ?? 'DailyMed',
      isPediatric: json['is_pediatric'] == 1 || json['is_pediatric'] == true,
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
    };
  }

  factory DosageGuidelinesModel.fromMap(Map<String, dynamic> map) {
    return DosageGuidelinesModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}
