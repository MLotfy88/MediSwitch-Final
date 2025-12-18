import 'package:dartz/dartz.dart';
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/core/usecases/usecase.dart';
import 'package:mediswitch/domain/entities/high_risk_ingredient.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';

/// Use case to fetch a list of highest risk active ingredients.
class GetHighRiskIngredientsUseCase
    implements UseCase<List<HighRiskIngredient>, int> {
  final InteractionRepository interactionRepository;

  GetHighRiskIngredientsUseCase({required this.interactionRepository});

  @override
  Future<Either<Failure, List<HighRiskIngredient>>> call(int limit) async {
    try {
      // Fetch high risk drugs directly from DB
      final drugs = await interactionRepository.getHighRiskDrugs(limit);

      final results =
          drugs.map((drug) {
            // Simplify name to primary ingredient
            final simpleName =
                drug.active.isNotEmpty
                    ? drug.active.split(RegExp(r'[+/]')).first.trim()
                    : drug.tradeName;

            return HighRiskIngredient(
              name: simpleName.isEmpty ? 'Unknown' : simpleName,
              totalInteractions: 0, // Not available from drug query directly
              severeCount: 0,
              moderateCount: 0,
              minorCount: 0,
              dangerScore: 100, // Placeholder
            );
          }).toList();

      // Deduplicate by name
      final uniqueResults = <String, HighRiskIngredient>{};
      for (final item in results) {
        if (!uniqueResults.containsKey(item.name.toLowerCase())) {
          uniqueResults[item.name.toLowerCase()] = item;
        }
      }

      return Right(uniqueResults.values.take(limit).toList());
    } catch (e) {
      return Left(
        CacheFailure(message: 'Error fetching high risk ingredients: $e'),
      );
    }
  }
}
