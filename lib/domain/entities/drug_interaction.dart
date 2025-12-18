// lib/domain/entities/drug_interaction.dart

import 'package:equatable/equatable.dart';

import 'interaction_severity.dart'; // Import the enum
import 'interaction_type.dart'; // Import the enum

// نموذج التفاعل الدوائي في طبقة المجال
class DrugInteraction extends Equatable {
  final int? id;
  final int medId; // ID of the local drug
  final String interactionDrugName; // Name of the interacting drug
  final String? interactionDailymedId; // RXCUI/UNII
  final String severity;
  final String description;
  final String source;

  const DrugInteraction({
    this.id,
    required this.medId,
    required this.interactionDrugName,
    this.interactionDailymedId,
    required this.severity,
    required this.description,
    this.source = 'DailyMed',
  });

  // Factory constructor to create an instance from JSON
  factory DrugInteraction.fromJson(Map<String, dynamic> json) {
    return DrugInteraction(
      id: json['id'] as int?,
      medId: json['med_id'] as int? ?? 0,
      interactionDrugName: json['interaction_drug_name'] as String? ?? '',
      interactionDailymedId: json['interaction_dailymed_id'] as String?,
      severity: json['severity'] as String? ?? 'Moderate',
      description: json['description'] as String? ?? '',
      source: json['source'] as String? ?? 'DailyMed',
    );
  }

  // Method to convert instance back to JSON
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

  InteractionSeverity get severityEnum {
    switch (severity.toLowerCase()) {
      case 'contraindicated':
        return InteractionSeverity.contraindicated;
      case 'severe':
        return InteractionSeverity.severe;
      case 'major':
        return InteractionSeverity.major;
      case 'moderate':
        return InteractionSeverity.moderate;
      case 'minor':
        return InteractionSeverity.minor;
      default:
        return InteractionSeverity.unknown;
    }
  }

  @override
  List<Object?> get props => [
    id,
    medId,
    interactionDrugName,
    interactionDailymedId,
    severity,
    description,
    source,
  ];
}

// Helper function to parse InteractionSeverity from string safely
InteractionSeverity _parseSeverity(String severityString) {
  return InteractionSeverity.values.firstWhere(
    (e) =>
        e.toString().split('.').last.toLowerCase() ==
        severityString.toLowerCase(),
    orElse: () => InteractionSeverity.unknown, // Default if not found
  );
}

// Helper function to parse InteractionType from string safely
InteractionType _parseInteractionType(String typeString) {
  return InteractionType.values.firstWhere(
    (e) =>
        e.toString().split('.').last.toLowerCase() == typeString.toLowerCase(),
    orElse: () => InteractionType.unknown, // Default if not found
  );
}
