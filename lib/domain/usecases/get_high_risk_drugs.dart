import 'package:dartz/dartz.dart';
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/core/usecases/usecase.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
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

    // 3. Select ingredients to feature
    // For variety, we can shuffle, but standard list specific methods are better.
    // We'll take the first few distinct ones for now, or shuffle if we want randomness.
    // Let's shuffle to show different ones on restart if desired, or keep deterministic.
    // Using deterministic for stability: take specific well known ones first if present
    // But getHighRiskIngredients returns alphabetic.

    final List<DrugEntity> results = [];
    final Set<String> existingNames = {};

    // Prioritize likely "famous" risky drugs if present (Warfarin, Digoxin, etc)
    // This is optional logic but improves UX quality
    final famousRisks = [
      'Warfarin',
      'Digoxin',
      'Methotrexate',
      'Lithium',
      'Insulin',
    ];
    final sortedIngredients = [...ingredients];

    // Move famous ones to front
    sortedIngredients.sort((a, b) {
      bool aFamous = famousRisks.any(
        (r) => a.toLowerCase().contains(r.toLowerCase()),
      );
      bool bFamous = famousRisks.any(
        (r) => b.toLowerCase().contains(r.toLowerCase()),
      );
      if (aFamous && !bFamous) return -1;
      if (!aFamous && bFamous) return 1;
      return a.compareTo(b);
    });

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
