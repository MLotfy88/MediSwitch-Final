import 'package:dartz/dartz.dart';
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/core/usecases/usecase.dart';
import 'package:mediswitch/domain/entities/high_risk_ingredient.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';

/// Use case to fetch a list of highest risk active ingredients.
class GetHighRiskIngredientsUseCase
    implements UseCase<List<HighRiskIngredient>, int> {
  final InteractionRepository interactionRepository;

  GetHighRiskIngredientsUseCase({required this.interactionRepository});

  @override
  Future<Either<Failure, List<HighRiskIngredient>>> call(int limit) async {
    // 1. Ensure interaction data is loaded
    await interactionRepository.loadInteractionData();

    // 2. Get all interactions
    final allInteractions = interactionRepository.allLoadedInteractions;
    if (allInteractions.isEmpty) {
      return const Right([]);
    }

    // 3. Count interactions and severity for each ingredient
    final Map<String, int> severeCount = {};
    final Map<String, int> moderateCount = {};
    final Map<String, int> minorCount = {};

    for (final interaction in allInteractions) {
      final ing1 = interaction.ingredient1.toLowerCase().trim();
      final ing2 = interaction.ingredient2.toLowerCase().trim();

      // Skip entries with "multiple" as ingredient
      if (ing2 == 'multiple' || ing1 == 'multiple') continue;

      // Weight by severity
      int severe = 0;
      int moderate = 0;
      int minor = 0;

      switch (interaction.severity) {
        case InteractionSeverity.contraindicated:
        case InteractionSeverity.severe:
        case InteractionSeverity.major:
          severe = 1;
        case InteractionSeverity.moderate:
          moderate = 1;
        case InteractionSeverity.minor:
        case InteractionSeverity.unknown:
          minor = 1;
      }

      // Add to ingredient 1
      severeCount[ing1] = (severeCount[ing1] ?? 0) + severe;
      moderateCount[ing1] = (moderateCount[ing1] ?? 0) + moderate;
      minorCount[ing1] = (minorCount[ing1] ?? 0) + minor;

      // Add to ingredient 2
      severeCount[ing2] = (severeCount[ing2] ?? 0) + severe;
      moderateCount[ing2] = (moderateCount[ing2] ?? 0) + moderate;
      minorCount[ing2] = (minorCount[ing2] ?? 0) + minor;
    }

    // 4. Calculate danger score for each ingredient
    // dangerScore = (severe * 10) + (moderate * 3) + (minor * 1)
    final List<HighRiskIngredient> ingredients = [];

    final allIngredients = <String>{
      ...severeCount.keys,
      ...moderateCount.keys,
      ...minorCount.keys,
    };

    for (final name in allIngredients) {
      final severe = severeCount[name] ?? 0;
      final moderate = moderateCount[name] ?? 0;
      final minor = minorCount[name] ?? 0;
      final total = severe + moderate + minor;

      // Only include ingredients with at least 1 severe interaction
      if (severe == 0) continue;

      final dangerScore = (severe * 10) + (moderate * 3) + (minor * 1);

      ingredients.add(
        HighRiskIngredient(
          name: name,
          totalInteractions: total,
          severeCount: severe,
          moderateCount: moderate,
          minorCount: minor,
          dangerScore: dangerScore,
        ),
      );
    }

    // 5. Sort by danger score (highest first)
    ingredients.sort((a, b) => b.dangerScore.compareTo(a.dangerScore));

    // 6. Return top N
    return Right(ingredients.take(limit).toList());
  }
}
