import 'package:dartz/dartz.dart'; // Import dartz

import '../../core/error/failures.dart'; // Import Failure base class (placeholder)
import '../entities/drug_entity.dart';

abstract class DrugRepository {
  Future<Either<Failure, List<DrugEntity>>> getAllDrugs();

  /// Searches drugs by name (trade name or Arabic name)
  Future<Either<Failure, List<DrugEntity>>> searchDrugs(
    String query, {
    int? limit,
  }); // Add optional limit

  /// Filters drugs by category
  Future<Either<Failure, List<DrugEntity>>> filterDrugsByCategory(
    String category,
  );

  /// Gets all available categories
  Future<Either<Failure, List<String>>> getAvailableCategories();

  /// Gets the timestamp of the last successful data update from local storage.
  /// Returns null if no timestamp is found.
  Future<Either<Failure, int?>> getLastUpdateTimestamp();
}
