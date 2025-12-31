import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../core/utils/category_mapper_helper.dart';
import '../../domain/entities/drug_entity.dart';
import '../repositories/drug_repository.dart';

// Define the result type for the use case
class DrugAlternativesResult {
  final List<DrugEntity> alternatives;

  DrugAlternativesResult({required this.alternatives});
}

class FindDrugAlternativesUseCase
    implements UseCase<DrugAlternativesResult, DrugEntity> {
  final DrugRepository repository;

  FindDrugAlternativesUseCase(this.repository);

  @override
  Future<Either<Failure, DrugAlternativesResult>> call(
    DrugEntity originalDrug,
  ) async {
    final failureOrAllDrugs = await repository.getAllDrugs();

    return failureOrAllDrugs.fold((failure) => Left(failure), (allDrugs) {
      try {
        // Alternatives = Same Therapeutic Category, Different Active Ingredient
        // 1. Determine Target Category (Smart Mapping)
        final originalCategory = (originalDrug.category ?? '').trim();
        final String targetSpecialty =
            originalCategory.isNotEmpty
                ? CategoryMapperHelper.mapCategoryToSpecialty(originalCategory)
                : 'general'; // Default fallback

        final String originalActiveLower =
            originalDrug.active.toLowerCase().trim();
        final String originalId = originalDrug.id.toString();

        final List<DrugEntity> alternatives = [];

        for (final drug in allDrugs) {
          // Exclude self
          if (drug.id.toString() == originalId) continue;

          // Exclude Similars (Same Active Ingredient) - distinct tab
          final String currentActiveLower = drug.active.toLowerCase().trim();
          if (currentActiveLower == originalActiveLower) continue;

          // Check Category Match
          final currentCategory = (drug.category ?? '').trim();
          // Optimization: If strings match exactly, it's a match
          if (currentCategory.isNotEmpty &&
              currentCategory.toLowerCase() == originalCategory.toLowerCase()) {
            alternatives.add(drug);
            continue;
          }

          // Smart Match: Check mapped specialty
          final String currentSpecialty =
              currentCategory.isNotEmpty
                  ? CategoryMapperHelper.mapCategoryToSpecialty(currentCategory)
                  : 'other';

          if (targetSpecialty != 'general' &&
              currentSpecialty == targetSpecialty) {
            alternatives.add(drug);
          }
        }

        return Right(DrugAlternativesResult(alternatives: alternatives));
      } catch (e) {
        return Left(CacheFailure(message: "Failed to find alternatives: $e"));
      }
    });
  }
}
