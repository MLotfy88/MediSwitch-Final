import 'package:dartz/dartz.dart'; // Import dartz

import '../../core/error/failures.dart'; // Import Failure base class (placeholder)
import '../entities/drug_entity.dart';

abstract class DrugRepository {
  Future<Either<Failure, List<DrugEntity>>> getAllDrugs();
  // Add other methods as needed, e.g.:
  // Future<Either<Failure, List<DrugEntity>>> searchDrugs(String query);
  // Future<Either<Failure, List<DrugEntity>>> filterDrugsByCategory(String category);
}
