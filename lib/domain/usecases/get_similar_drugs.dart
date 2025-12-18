import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../domain/entities/drug_entity.dart';
import '../repositories/drug_repository.dart';

class GetSimilarDrugsUseCase implements UseCase<List<DrugEntity>, DrugEntity> {
  final DrugRepository repository;

  GetSimilarDrugsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DrugEntity>>> call(DrugEntity params) async {
    // Similars logic: Same Active Ingredient
    final allDrugsResult = await repository.getAllDrugs();

    return allDrugsResult.fold((failure) => Left(failure), (allDrugs) {
      try {
        final targetActive = params.active.toLowerCase().trim();
        if (targetActive.isEmpty) return Right([]);

        final similars =
            allDrugs.where((drug) {
              // Exclude self
              if (drug.id == params.id) return false;

              final currentActive = drug.active.toLowerCase().trim();
              return currentActive == targetActive;
            }).toList();

        return Right(similars);
      } catch (e) {
        return Left(
          CacheFailure(message: "Failed to filter similar drugs: $e"),
        );
      }
    });
  }
}
