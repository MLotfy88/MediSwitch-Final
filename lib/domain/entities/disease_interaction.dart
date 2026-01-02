import 'package:equatable/equatable.dart';

import 'interaction_severity.dart';

class DiseaseInteraction extends Equatable {
  final int medId;
  final String tradeName;
  final String diseaseName;
  final String interactionText;
  final String severity;
  final String source;

  const DiseaseInteraction({
    required this.medId,
    required this.tradeName,
    required this.diseaseName,
    required this.interactionText,
    required this.severity,
    required this.source,
  });

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
    medId,
    tradeName,
    diseaseName,
    interactionText,
    severity,
    source,
  ];
}
