import 'package:dartz/dartz.dart';
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/core/usecases/usecase.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';

/// Use case to fetch a list of high risk drugs based on interaction severity.
class GetHighRiskDrugsUseCase implements UseCase<List<DrugEntity>, int> {
  final InteractionRepository interactionRepository;

  GetHighRiskDrugsUseCase({required this.interactionRepository});

  @override
  Future<Either<Failure, List<DrugEntity>>> call(int limit) async {
    try {
      final drugs = await interactionRepository.getHighRiskDrugs(limit);
      return Right(drugs);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
