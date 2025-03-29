import 'package:dartz/dartz.dart';
import '../../domain/entities/drug_entity.dart'; // Corrected import path assuming entity is in domain/entities
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/drug_repository.dart';

// Define the result type for the use case (Only Alternatives for now)
class DrugAlternativesResult {
  // final List<DrugEntity> similars; // Removed Similars for now
  final List<DrugEntity> alternatives; // Same category

  DrugAlternativesResult({
    /*required this.similars,*/ required this.alternatives,
  });
}

class FindDrugAlternativesUseCase
    implements UseCase<DrugAlternativesResult, DrugEntity> {
  // Updated return type
  final DrugRepository repository;

  FindDrugAlternativesUseCase(this.repository);

  @override
  Future<Either<Failure, DrugAlternativesResult>> call(
    DrugEntity originalDrug,
  ) async {
    // Get all drugs first
    final failureOrAllDrugs = await repository.getAllDrugs();

    return failureOrAllDrugs.fold(
      (failure) =>
          Left(failure), // Propagate failure if getting all drugs fails
      (allDrugs) {
        try {
          // Use only category for finding alternatives for now
          final String originalCategoryLower =
              (originalDrug.mainCategory ?? '').toLowerCase();
          final String originalTradeNameLower =
              (originalDrug.tradeName ?? '').toLowerCase(); // To exclude self

          if (originalCategoryLower.isEmpty) {
            // Cannot find alternatives if category is unknown
            return Right(DrugAlternativesResult(alternatives: []));
          }

          // final List<DrugEntity> similars = []; // Removed Similars logic
          final List<DrugEntity> alternatives = [];

          for (final drug in allDrugs) {
            final String currentTradeNameLower =
                (drug.tradeName ?? '').toLowerCase();
            // Skip the original drug itself
            if (currentTradeNameLower == originalTradeNameLower) continue;

            // final String currentActiveLower = (drug.active ?? '').toLowerCase(); // Removed active ingredient logic
            final String currentCategoryLower =
                (drug.mainCategory ?? '').toLowerCase();

            // Find Alternatives (same category)
            if (currentCategoryLower == originalCategoryLower) {
              alternatives.add(drug);
            }
          }

          return Right(
            DrugAlternativesResult(
              alternatives: alternatives,
            ), // Return only alternatives
          );
        } catch (e) {
          print('Error finding alternatives logic: $e');
          // Use a specific Failure type, e.g., CacheFailure if error is likely from data processing
          return Left(CacheFailure());
        }
      },
    );
  }
}
