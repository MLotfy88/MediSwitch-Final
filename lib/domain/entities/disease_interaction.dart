import 'package:equatable/equatable.dart';

class DiseaseInteraction extends Equatable {
  final int medId;
  final String tradeName;
  final String diseaseName;
  final String interactionText;
  final String source;

  const DiseaseInteraction({
    required this.medId,
    required this.tradeName,
    required this.diseaseName,
    required this.interactionText,
    required this.source,
  });

  @override
  List<Object?> get props => [
    medId,
    tradeName,
    diseaseName,
    interactionText,
    source,
  ];
}
