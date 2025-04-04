// lib/domain/services/interaction_checker_service.dart

import '../entities/drug_entity.dart';
import '../entities/drug_interaction.dart';
import '../entities/interaction_analysis_result.dart'; // Import the result class
// import '../repositories/interaction_repository.dart'; // Not needed if data is passed in

// TODO: Define a result class for interaction analysis if needed (e.g., InteractionAnalysisResult)
// For now, it might just return a list of found interactions and maybe a summary.

class InteractionCheckerService {
  // The repository might be injected if the service needs to fetch rules dynamically,
  // but the core logic might operate on data passed to it.
  // final InteractionRepository interactionRepository;
  // InteractionCheckerService({required this.interactionRepository});

  /// Analyzes pairwise interactions between a list of medicines.
  /// Returns an InteractionAnalysisResult containing interactions, severity, and recommendations.
  /// Assumes interaction data (allInteractions, medicineIngredientsMap) is already loaded.
  InteractionAnalysisResult analyzeInteractions(
    List<DrugEntity> medicines,
    List<DrugInteraction> allInteractions,
    Map<String, List<String>> medicineIngredientsMap,
  ) {
    print(
      'InteractionCheckerService: Analyzing interactions for ${medicines.length} medicines...',
    );
    List<DrugInteraction> foundInteractions = [];

    // Get ingredients for each medicine
    List<List<String>> ingredientsList =
        medicines.map((m) {
          // Use provided map first, fallback to parsing active field
          return medicineIngredientsMap[m.tradeName.toLowerCase().trim()] ??
              _extractIngredientsFromString(m.active);
        }).toList();

    // Iterate through all unique pairs of medicines
    for (int i = 0; i < medicines.length; i++) {
      for (int j = i + 1; j < medicines.length; j++) {
        final ingredients1 = ingredientsList[i];
        final ingredients2 = ingredientsList[j];

        // Check for interactions between each pair of ingredients from the two drugs
        for (final ing1 in ingredients1) {
          final ing1Lower = ing1.toLowerCase().trim();
          if (ing1Lower.isEmpty) continue; // Skip empty ingredients

          for (final ing2 in ingredients2) {
            final ing2Lower = ing2.toLowerCase().trim();
            if (ing2Lower.isEmpty) continue; // Skip empty ingredients
            if (ing1Lower == ing2Lower) continue; // Skip self-interaction check

            // Find interactions in the loaded list (case-insensitive)
            foundInteractions.addAll(
              allInteractions.where(
                (interaction) =>
                    (interaction.ingredient1 == ing1Lower &&
                        interaction.ingredient2 == ing2Lower) ||
                    (interaction.ingredient1 == ing2Lower &&
                        interaction.ingredient2 == ing1Lower),
              ),
            );
          }
        }
      }
    }

    // Remove duplicate interactions if any (based on ingredients pair and effect)
    final uniqueInteractions = foundInteractions.toSet().toList();

    print(
      'InteractionCheckerService: Found ${uniqueInteractions.length} unique pairwise interactions.',
    );
    // Calculate overall severity
    final overallSeverity = _calculateOverallSeverity(uniqueInteractions);

    // Generate recommendations (using original medicine names for clarity)
    final recommendations = _generateRecommendations(
      uniqueInteractions,
      medicines,
      medicineIngredientsMap,
    );

    return InteractionAnalysisResult(
      interactions: uniqueInteractions,
      overallSeverity: overallSeverity,
      recommendations: recommendations,
    );
  }

  // Helper function to extract ingredients from the 'active' string
  // This might be duplicated from repository, consider moving to a shared utility
  List<String> _extractIngredientsFromString(String activeText) {
    final List<String> parts = activeText.split(RegExp(r'[,+]'));
    return parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  // --- Helper Methods ---

  InteractionSeverity _calculateOverallSeverity(
    List<DrugInteraction> interactions,
  ) {
    if (interactions.isEmpty) {
      return InteractionSeverity
          .minor; // Or unknown? Minor seems better default.
    }
    // Find the highest severity index
    int maxSeverityIndex = interactions
        .map((i) => i.severity.index)
        .reduce((max, current) => current > max ? current : max);

    // Ensure the index is within the bounds of the enum
    if (maxSeverityIndex >= 0 &&
        maxSeverityIndex < InteractionSeverity.values.length) {
      return InteractionSeverity.values[maxSeverityIndex];
    } else {
      return InteractionSeverity.unknown; // Fallback for safety
    }
  }

  List<String> _generateRecommendations(
    List<DrugInteraction> interactions,
    List<DrugEntity> originalMedicines,
    Map<String, List<String>> medicineIngredientsMap,
  ) {
    List<String> recommendations = [];
    Set<String> processedPairs =
        {}; // To avoid duplicate recommendations for the same pair

    for (final interaction in interactions) {
      // Find the original medicine names involved in this specific interaction
      final med1Name = _findMedicineNameForIngredient(
        interaction.ingredient1,
        originalMedicines,
        medicineIngredientsMap,
      );
      final med2Name = _findMedicineNameForIngredient(
        interaction.ingredient2,
        originalMedicines,
        medicineIngredientsMap,
      );

      // Create a unique key for the pair to avoid duplicates
      final pairKey =
          [med1Name, med2Name].map((n) => n ?? '?').toList()..sort();
      final keyString = pairKey.join('-');

      if (processedPairs.contains(keyString))
        continue; // Skip if already processed

      // Generate recommendation based on severity
      if (interaction.severity.index >= InteractionSeverity.moderate.index) {
        final severityText = _getSeverityArabicName(interaction.severity);
        final effectText =
            interaction.arabicEffect.isNotEmpty
                ? interaction.arabicEffect
                : interaction.effect;
        final recommendationText =
            interaction.arabicRecommendation.isNotEmpty
                ? interaction.arabicRecommendation
                : interaction.recommendation;

        recommendations.add(
          "$severityText: ${effectText} بين ${med1Name ?? interaction.ingredient1} و ${med2Name ?? interaction.ingredient2}. ${recommendationText}",
        );
        processedPairs.add(keyString); // Mark pair as processed
      }
    }

    // TODO: Add recommendations for multi-drug paths if implemented

    if (recommendations.isEmpty && interactions.isNotEmpty) {
      recommendations.add(
        "تم العثور على تفاعلات بسيطة فقط لا تتطلب إجراءً محددًا عادةً.",
      );
    } else if (interactions.isEmpty) {
      recommendations.add(
        "لم يتم العثور على تفاعلات معروفة بين الأدوية المختارة.",
      );
    }

    return recommendations;
  }

  // Helper to find the original medicine name containing a specific ingredient
  String? _findMedicineNameForIngredient(
    String ingredientName,
    List<DrugEntity> originalMedicines,
    Map<String, List<String>> medicineIngredientsMap,
  ) {
    for (final med in originalMedicines) {
      final ingredients =
          medicineIngredientsMap[med.tradeName.toLowerCase().trim()] ??
          _extractIngredientsFromString(med.active);
      if (ingredients
          .map((e) => e.toLowerCase().trim())
          .contains(ingredientName.toLowerCase().trim())) {
        return med.arabicName.isNotEmpty
            ? med.arabicName
            : med.tradeName; // Prefer Arabic name
      }
    }
    return null; // Should ideally not happen if map is correct
  }

  // Helper to get Arabic name for severity
  String _getSeverityArabicName(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.minor:
        return 'بسيط';
      case InteractionSeverity.moderate:
        return 'متوسط';
      case InteractionSeverity.major:
        return 'كبير';
      case InteractionSeverity.severe:
        return 'شديد';
      case InteractionSeverity.contraindicated:
        return 'مضاد استطباب';
      default:
        return 'غير معروف';
    }
  }

  // TODO: Implement optional advanced analysis methods:
  // - _buildInteractionGraph
  // - _findInteractionPaths (DFS)
}
