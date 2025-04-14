import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart'; // Import Equatable
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
    // Pass limit and offset to repository method
    return await repository.filterDrugsByCategory(
      params.category,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

// Make FilterParams extend Equatable
class FilterParams extends Equatable {
  final String category;
  final int? limit;
  final int? offset;

  // Update constructor
  const FilterParams({required this.category, this.limit, this.offset});

  @override
  // Update props
  List<Object?> get props => [category, limit, offset];
}
