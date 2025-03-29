import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart'; // Assuming a base usecase definition
import '../entities/drug_entity.dart';
import '../repositories/drug_repository.dart';

// Use case for getting all drugs.
// For now, assuming no parameters are needed.
// If a base UseCase<Type, Params> interface is defined in core/usecases, implement it.
// Example: class GetAllDrugs implements UseCase<List<DrugEntity>, NoParams> {
class GetAllDrugs {
  final DrugRepository repository;

  GetAllDrugs(this.repository);

  // The call method executes the use case.
  // It calls the corresponding method in the repository.
  Future<Either<Failure, List<DrugEntity>>> call() async {
    // In a real app, you might add pre-call logic here if needed.
    return await repository.getAllDrugs();
  }
}

// Define NoParams if using the base UseCase structure from core/usecases/usecase.dart
// import 'package:equatable/equatable.dart';
// class NoParams extends Equatable {
//   @override
//   List<Object?> get props => [];
// }
