import 'package:dartz/dartz.dart';
import '../repositories/drug_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

// Use case to get the list of available drug categories.
class GetAvailableCategoriesUseCase implements UseCase<List<String>, NoParams> {
  final DrugRepository repository;

  GetAvailableCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    return await repository.getAvailableCategories();
  }
}
