import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/drug_repository.dart';

/// Use case to get the timestamp of the last successful data update.
class GetLastUpdateTimestampUseCase implements UseCase<int?, NoParams> {
  final DrugRepository repository;

  GetLastUpdateTimestampUseCase(this.repository);

  @override
  Future<Either<Failure, int?>> call(NoParams params) async {
    return await repository.getLastUpdateTimestamp();
  }
}
