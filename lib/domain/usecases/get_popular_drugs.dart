import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/drug_entity.dart';
import '../repositories/drug_repository.dart';

class GetPopularDrugsUseCase
    implements UseCase<List<DrugEntity>, GetPopularDrugsParams> {
  final DrugRepository repository;

  GetPopularDrugsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DrugEntity>>> call(
    GetPopularDrugsParams params,
  ) async {
    // This will call the repository method we'll define next
    return await repository.getPopularDrugs(limit: params.limit);
  }
}

class GetPopularDrugsParams {
  final int limit;

  GetPopularDrugsParams({required this.limit});
}
