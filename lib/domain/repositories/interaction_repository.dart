// lib/domain/repositories/interaction_repository.dart

import 'package:dartz/dartz.dart'; // For Either

import '../../core/error/failures.dart'; // For Failure
import '../entities/dosage_guidelines.dart'; // Import DosageGuidelines
import '../entities/drug_entity.dart';
import '../entities/drug_interaction.dart';
import '../entities/high_risk_ingredient.dart';
import '../entities/interaction_severity.dart';
// Potentially import ActiveIngredient if needed by the interface

abstract class InteractionRepository {
  /// Loads the interaction database (e.g., from assets).
  /// Should be called once during app initialization.
  Future<Either<Failure, Unit>> loadInteractionData();

  /// Finds interactions between a list of provided medicines.
  Future<Either<Failure, List<DrugInteraction>>> findInteractionsForMedicines(
    List<DrugEntity> medicines,
  );

  /// Finds all interactions involving the given medicine.
  Future<Either<Failure, List<DrugInteraction>>> findAllInteractionsForDrug(
    DrugEntity drug,
  );

  /// Checks if a drug has any known interactions efficiently.
  /// Note: Now async as it might query DB.
  Future<bool> hasKnownInteractions(DrugEntity drug);

  /// Gets the maximum severity level of known interactions for a drug.
  Future<InteractionSeverity> getMaxSeverityForDrug(DrugEntity drug);

  /// Get total count of interaction rules in the database
  Future<int> getRulesCount();

  /// Increment visits for a drug
  Future<void> incrementVisits(int drugId);

  /// Get interaction count for a specific drug
  Future<int> getInteractionCountForDrug(DrugEntity drug);

  /// Get a list of ingredients known to have high-risk (severe/contraindicated) interactions
  Future<List<HighRiskIngredient>> getHighRiskIngredients(int limit);

  /// Get high risk drugs based on interaction severity score
  Future<List<DrugEntity>> getHighRiskDrugs(int limit);

  /// Get dosage guidelines for a specific drug
  Future<List<DosageGuidelines>> getDosageGuidelines(DrugEntity drug);

  /// Get list of high risk individual interactions
  Future<List<DrugInteraction>> getHighRiskInteractions({int limit = 50});

  /// Get all interactions matching a specific drug name string (e.g. ingredient)
  Future<List<DrugInteraction>> getInteractionsWith(String drugName);

  /// Synchronize interaction rules with remote server
  Future<Either<Failure, int>> syncInteractions(int lastTimestamp);

  /// Synchronize medicine-ingredient mapping with remote server
  Future<Either<Failure, int>> syncMedIngredients(int lastTimestamp);

  /// Synchronize dosage guidelines with remote server
  Future<Either<Failure, int>> syncDosages(int lastTimestamp);

  /// Get food interactions for a specific drug
  /// Get food interactions for a specific drug
  /// Checks both ID and active ingredient for robust matching
  Future<List<String>> getFoodInteractions(DrugEntity drug);

  /// Gets a list of ingredients that have food interactions, with counts.
  Future<List<HighRiskIngredient>> getFoodInteractionIngredients();

  /// Get drugs that have known food interactions (for Home Screen)
  Future<List<DrugEntity>> getDrugsWithFoodInteractions(int limit);
}
