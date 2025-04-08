import 'package:dartz/dartz.dart';
import '../repositories/interaction_repository.dart';
import '../../core/error/failures.dart'; // Assuming Failure path
import '../../core/usecases/usecase.dart'; // Assuming UseCase path

// Use case to load interaction data from the repository
class LoadInteractionData implements UseCase<void, NoParams> {
  final InteractionRepository repository;

  LoadInteractionData(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    // Simply call the repository method to load the data
    return await repository.loadInteractionData();
  }
}
