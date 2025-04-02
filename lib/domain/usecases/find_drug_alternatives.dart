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
          // --- Refined Logic for Alternatives (Task 3.4.3) ---
          final String originalActiveLower =
              (originalDrug.active ?? '')
                  .toLowerCase()
                  .trim(); // Use active ingredient
          final String originalTradeNameLower =
              (originalDrug.tradeName ?? '')
                  .toLowerCase()
                  .trim(); // To exclude self
          // Keep category for potential future use or broader filtering
          // final String originalCategoryLower = (originalDrug.mainCategory ?? '').toLowerCase();

          // Cannot find alternatives if active ingredient is unknown
          if (originalActiveLower.isEmpty) {
            print(
              'Cannot find alternatives: Original drug active ingredient is empty.',
            );
            return Right(DrugAlternativesResult(alternatives: []));
          }

          // final List<DrugEntity> similars = []; // Removed Similars logic
          final List<DrugEntity> alternatives = [];

          for (final drug in allDrugs) {
            final String currentTradeNameLower =
                (drug.tradeName ?? '').toLowerCase();
            // Skip the original drug itself
            if (currentTradeNameLower == originalTradeNameLower) continue;

            final String currentActiveLower =
                (drug.active ?? '').toLowerCase().trim();
            // final String currentCategoryLower = (drug.mainCategory ?? '').toLowerCase(); // Keep for potential future use

            // Find Alternatives: Match active ingredient primarily
            if (currentActiveLower == originalActiveLower) {
              alternatives.add(drug);
            }
            // Optional: Add secondary criteria here if needed (e.g., dosage form)
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
