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
    // Delegate to repository which uses SQL for efficient lookup
    return await repository.findSimilars(params);
  }
}
