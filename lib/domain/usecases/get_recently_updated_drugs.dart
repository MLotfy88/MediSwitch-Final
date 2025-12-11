import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/drug_entity.dart';
import '../repositories/drug_repository.dart';

class GetRecentlyUpdatedDrugsUseCase
    implements UseCase<List<DrugEntity>, GetRecentlyUpdatedDrugsParams> {
  final DrugRepository repository;

  GetRecentlyUpdatedDrugsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DrugEntity>>> call(
    GetRecentlyUpdatedDrugsParams params,
  ) async {
    return await repository.getRecentlyUpdatedDrugs(
      cutoffDate: params.cutoffDate,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetRecentlyUpdatedDrugsParams {
  final String cutoffDate;
  final int limit;
  final int? offset;

  GetRecentlyUpdatedDrugsParams({
    required this.cutoffDate,
    required this.limit,
    this.offset,
  });
}
