import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../domain/entities/drug_entity.dart'; // Corrected import path assuming entity is in domain/entities
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
          // Alternatives = Same Usage (Indication), Different Active Ingredient
          final String originalUsageLower =
              (originalDrug.usage).toLowerCase().trim();
          final String originalActiveLower =
              (originalDrug.active).toLowerCase().trim();
          final String originalTradeNameLower =
              (originalDrug.tradeName).toLowerCase().trim();

          // Cannot find alternatives if usage is unknown
          if (originalUsageLower.isEmpty) {
            // Fallback to Category if usage is empty
            final String originalCategoryLower =
                (originalDrug.category ?? originalDrug.mainCategory)
                    .toLowerCase()
                    .trim();
            if (originalCategoryLower.isEmpty) {
              print(
                'Cannot find alternatives: Original drug usage and category are empty.',
              );
              return Right(DrugAlternativesResult(alternatives: []));
            }
            // Use category logic if fallback needed, but for now just return empty or proceed?
            // Let's implement category fallback inside the loop
          }

          final List<DrugEntity> alternatives = [];

          for (final drug in allDrugs) {
            final String currentTradeNameLower =
                (drug.tradeName).toLowerCase().trim();
            // Skip the original drug itself
            if (currentTradeNameLower == originalTradeNameLower) continue;

            final String currentActiveLower =
                (drug.active).toLowerCase().trim();
            final String currentUsageLower = (drug.usage).toLowerCase().trim();

            // Skip Similars (Same Active Ingredient) - they are not just "Alternatives", they are "Similars"
            if (currentActiveLower == originalActiveLower) continue;

            // Find Alternatives: Match usage
            if (originalUsageLower.isNotEmpty &&
                currentUsageLower == originalUsageLower) {
              alternatives.add(drug);
            }
            // Fallback: If usage empty, match category (optional, based on user preference)
            // else if (originalUsageLower.isEmpty && currentCategory == originalCategory) ...
          }

          return Right(DrugAlternativesResult(alternatives: alternatives));
        } catch (e) {
          print('Error finding alternatives logic: $e');
          return Left(CacheFailure());
        }
      },
    );
  }
}
