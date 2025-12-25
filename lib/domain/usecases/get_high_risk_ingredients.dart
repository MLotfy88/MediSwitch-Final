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
      // Fetch high risk ingredients metrics directly from DB
      final ingredients = await interactionRepository.getHighRiskIngredients(
        limit,
      );
      return Right(ingredients);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Error fetching high risk ingredients: $e'),
      );
    }
  }
}
