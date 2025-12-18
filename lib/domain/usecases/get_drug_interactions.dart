import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../domain/repositories/interaction_repository.dart';

class GetDrugInteractionsUseCase
    implements UseCase<List<DrugInteraction>, DrugEntity> {
  final InteractionRepository repository;

  GetDrugInteractionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DrugInteraction>>> call(DrugEntity drug) async {
    return await repository.findAllInteractionsForDrug(drug);
  }
}
