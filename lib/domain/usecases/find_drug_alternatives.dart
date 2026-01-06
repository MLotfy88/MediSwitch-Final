import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../domain/entities/drug_entity.dart';
import '../repositories/drug_repository.dart';

// Define the result type for the use case
class DrugAlternativesResult {
  final List<DrugEntity> alternatives;

  DrugAlternativesResult({required this.alternatives});
}

class FindDrugAlternativesUseCase
    implements UseCase<DrugAlternativesResult, DrugEntity> {
  final DrugRepository repository;

  FindDrugAlternativesUseCase(this.repository);

  @override
  Future<Either<Failure, DrugAlternativesResult>> call(
    DrugEntity originalDrug,
  ) async {
    // Delegate to repository which uses SQL for efficient lookup
    final result = await repository.findAlternatives(originalDrug);

    return result.fold(
      (failure) => Left(failure),
      (drugs) => Right(DrugAlternativesResult(alternatives: drugs)),
    );
  }
}
