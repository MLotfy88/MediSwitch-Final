// lib/domain/entities/interaction_analysis_result.dart

import 'package:equatable/equatable.dart';
import 'drug_interaction.dart'; // Import DrugInteraction and InteractionSeverity

class InteractionAnalysisResult extends Equatable {
  final List<DrugInteraction>
  interactions; // List of found pairwise interactions
  final InteractionSeverity overallSeverity; // Highest severity found
  final List<String> recommendations; // Generated recommendations (Arabic)
  // Add other fields if needed, e.g., interaction paths for advanced analysis

  const InteractionAnalysisResult({
    required this.interactions,
    required this.overallSeverity,
    required this.recommendations,
  });

  @override
  List<Object?> get props => [interactions, overallSeverity, recommendations];
}
