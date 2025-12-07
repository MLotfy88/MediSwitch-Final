import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/drug_repository.dart';

// Use case to get the list of available drug categories with their drug counts.
class GetCategoriesWithCountUseCase
    implements UseCase<Map<String, int>, NoParams> {
  final DrugRepository repository;

  GetCategoriesWithCountUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, int>>> call(NoParams params) async {
    return await repository.getCategoriesWithCounts();
  }
}
