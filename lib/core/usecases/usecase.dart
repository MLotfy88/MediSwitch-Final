import 'package:dartz/dartz.dart';
import 'package:mediswitch/core/error/failures.dart';

// Abstract class representing a Use Case.
// Type: The return type of the use case (e.g., List<DrugEntity>, void).
// Params: The parameters required by the use case (e.g., SearchParams, NoParams).
/// Abstract class representing a Use Case.
/// [Type] The return type of the use case (e.g., List<DrugEntity>, void).
/// [Params] The parameters required by the use case (e.g., SearchParams, NoParams).
abstract class UseCase<Type, Params> {
  /// Execute the use case
  Future<Either<Failure, Type>> call(Params params);
}

// Use this class if the use case doesn't require any parameters.
class NoParams {}
