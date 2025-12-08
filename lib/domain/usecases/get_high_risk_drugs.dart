import 'package:dartz/dartz.dart';
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/core/usecases/usecase.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/domain/repositories/drug_repository.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';

/// Use case to fetch a list of high risk drugs based on interaction severity.
class GetHighRiskDrugsUseCase implements UseCase<List<DrugEntity>, int> {
  final InteractionRepository interactionRepository;
  final DrugRepository drugRepository;

  GetHighRiskDrugsUseCase({
    required this.interactionRepository,
    required this.drugRepository,
  });

  @override
  Future<Either<Failure, List<DrugEntity>>> call(int limit) async {
    // 1. Ensure interaction data is loaded
    await interactionRepository.loadInteractionData();

    // 2. Get high risk ingredients
    final ingredients = interactionRepository.getHighRiskIngredients();

    if (ingredients.isEmpty) {
      return const Right([]);
    }

    // 3. Calculate danger score for each ingredient
    // Danger score = weighted sum of interactions by severity
    final Map<String, int> ingredientDangerScores = {};
    final allInteractions = interactionRepository.allLoadedInteractions;

    for (final ingredient in ingredients) {
      int dangerScore = 0;
      for (final interaction in allInteractions) {
        final ing1 = interaction.ingredient1.toLowerCase();
        final ing2 = interaction.ingredient2.toLowerCase();
        if (ing1 == ingredient.toLowerCase() ||
            ing2 == ingredient.toLowerCase()) {
          // Weight by severity
          switch (interaction.severity) {
            case InteractionSeverity.contraindicated:
              dangerScore += 10;
              break;
            case InteractionSeverity.severe:
              dangerScore += 8;
              break;
            case InteractionSeverity.major:
              dangerScore += 5;
              break;
            case InteractionSeverity.moderate:
              dangerScore += 3;
              break;
            case InteractionSeverity.minor:
              dangerScore += 1;
              break;
            case InteractionSeverity.unknown:
              dangerScore += 0;
              break;
          }
        }
      }
      ingredientDangerScores[ingredient] = dangerScore;
    }

    // 4. Sort ingredients by danger score (highest first)
    final sortedIngredients = [...ingredients];
    sortedIngredients.sort((a, b) {
      final scoreA = ingredientDangerScores[a] ?? 0;
      final scoreB = ingredientDangerScores[b] ?? 0;
      return scoreB.compareTo(scoreA); // Descending order
    });

    final List<DrugEntity> results = [];
    final Set<String> existingNames = {};

    final targetIngredients = sortedIngredients.take(8).toList();

    for (final ingredient in targetIngredients) {
      // Search by query (ingredient)
      final searchResult = await drugRepository.searchDrugs(
        ingredient, // Positional argument
        limit: 2, // Get top 2 examples per ingredient
        offset: 0,
      );

      searchResult.fold(
        (l) {}, // Ignore failures for individual searches
        (drugs) {
          for (var drug in drugs) {
            if (!existingNames.contains(drug.tradeName)) {
              existingNames.add(drug.tradeName);
              results.add(drug);
            }
          }
        },
      );
      if (results.length >= limit) break;
    }

    return Right(results.take(limit).toList());
  }
}
