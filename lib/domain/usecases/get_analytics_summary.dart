import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/analytics_repository.dart';

class GetAnalyticsSummary implements UseCase<AnalyticsSummary, NoParams> {
  final AnalyticsRepository repository;

  GetAnalyticsSummary(this.repository);

  @override
  Future<Either<Failure, AnalyticsSummary>> call(NoParams params) async {
    return await repository.getAnalyticsSummary();
  }
}
