import 'package:dartz/dartz.dart';
import '../entities/drug_entity.dart';
import '../repositories/drug_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

class SearchDrugsUseCase implements UseCase<List<DrugEntity>, SearchParams> {
  final DrugRepository repository;

  SearchDrugsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DrugEntity>>> call(SearchParams params) async {
    // Input validation (optional but recommended)
    if (params.query.isEmpty) {
      // Decide behavior for empty query: return all or empty list?
      // Returning empty list might be safer to avoid loading all data unintentionally.
      // Or delegate this decision to the repository implementation.
      // For now, let's delegate to repository.
      // return Right([]);
    }
    return await repository.searchDrugs(params.query);
  }
}

class SearchParams {
  final String query;

  SearchParams({required this.query});

  // Consider adding equality checks if needed
}
