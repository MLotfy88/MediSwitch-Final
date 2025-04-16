import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart'; // Import Equatable
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
    // Repository handles empty query now by returning all (or limited set)
    // if (params.query.isEmpty && params.limit == null) {
    //   return Right([]); // Avoid loading all if query is empty and no limit set
    // }

    // Pass limit and offset to repository method
    return await repository.searchDrugs(
      params.query,
      limit: params.limit,
      offset: params.offset, // Pass the offset here
    );
  }
}

// Make SearchParams extend Equatable
class SearchParams extends Equatable {
  final String query;
  final int? limit;
  final int? offset; // Add optional offset

  // Update constructor to include limit and offset
  const SearchParams({required this.query, this.limit, this.offset});

  @override
  // Update props to include limit
  List<Object?> get props => [query, limit, offset]; // Update props
}
