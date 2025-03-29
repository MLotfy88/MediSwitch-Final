import 'package:dartz/dartz.dart';
import '../entities/drug_entity.dart';
import '../repositories/drug_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

class FilterDrugsByCategoryUseCase
    implements UseCase<List<DrugEntity>, FilterParams> {
  final DrugRepository repository;

  FilterDrugsByCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<DrugEntity>>> call(FilterParams params) async {
    // Input validation
    if (params.category.isEmpty) {
      // Return empty list or delegate to repository?
      // Let's delegate to repository for consistency.
      // return Right([]);
    }
    return await repository.filterDrugsByCategory(params.category);
  }
}

class FilterParams {
  final String category;

  FilterParams({required this.category});

  // Consider adding equality checks if needed
}
