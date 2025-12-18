import '../../domain/entities/drug_interaction.dart';

class DrugInteractionModel extends DrugInteraction {
  const DrugInteractionModel({
    super.id,
    required super.medId,
    required super.interactionDrugName,
    super.interactionDailymedId,
    super.severity = 'Unknown',
    required super.description,
    super.source = 'Local',
  });

  factory DrugInteractionModel.fromJson(Map<String, dynamic> json) {
    return DrugInteractionModel(
      id: json['id'] as int?,
      medId: json['med_id'] as int? ?? 0,
      interactionDrugName:
          json['interaction_drug_name'] as String? ?? 'Unknown Drug',
      interactionDailymedId: json['interaction_dailymed_id'] as String?,
      severity: json['severity'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? 'No description available',
      source: json['source'] as String? ?? 'Local',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'med_id': medId,
      'interaction_drug_name': interactionDrugName,
      'interaction_dailymed_id': interactionDailymedId,
      'severity': severity,
      'description': description,
      'source': source,
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
