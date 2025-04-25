import 'package:dartz/dartz.dart'; // Import dartz

import '../../core/error/failures.dart'; // Import Failure base class (placeholder)
import '../entities/drug_entity.dart';

abstract class DrugRepository {
  /// Checks for updates and potentially downloads new data.
  /// Returns Right([]) on success (or if no update needed/offline),
  /// or Left(Failure) if update check/download fails critically.
  Future<Either<Failure, List<DrugEntity>>> getAllDrugs();

  /// Searches drugs by name (trade name or Arabic name) with pagination.
  Future<Either<Failure, List<DrugEntity>>> searchDrugs(
    String query, {
    int? limit,
    int? offset, // Add offset
  });

  /// Filters drugs by category with pagination.
  Future<Either<Failure, List<DrugEntity>>> filterDrugsByCategory(
    String category, {
    int? limit,
    int? offset, // Add offset
  });

  /// Gets all available categories
  Future<Either<Failure, List<String>>> getAvailableCategories();

  /// Gets the timestamp of the last successful data update from local storage.
  /// Returns null if no timestamp is found.
  Future<Either<Failure, int?>> getLastUpdateTimestamp();

  /// Gets drugs updated after a specific date.
  Future<Either<Failure, List<DrugEntity>>> getRecentlyUpdatedDrugs({
    required String cutoffDate,
    required int limit,
  });

  /// Gets popular drugs (currently implemented as random).
  Future<Either<Failure, List<DrugEntity>>> getPopularDrugs({
    required int limit,
  });

  /// Finds drugs with the exact same active ingredients.
  Future<Either<Failure, List<DrugEntity>>> findSimilars(DrugEntity drug);

  /// Finds drugs with a different active ingredient but the same category.
  Future<Either<Failure, List<DrugEntity>>> findAlternatives(DrugEntity drug);
}
