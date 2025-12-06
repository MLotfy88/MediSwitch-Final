// lib/domain/repositories/interaction_repository.dart

import 'package:dartz/dartz.dart'; // For Either

import '../../core/error/failures.dart'; // For Failure
import '../entities/drug_entity.dart';
import '../entities/drug_interaction.dart';
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

  /// Gets the list of all loaded drug interactions.
  /// Returns an empty list if data is not loaded.
  List<DrugInteraction> get allLoadedInteractions;

  /// Gets the map linking medicine trade names (lowercase) to their active ingredients (lowercase).
  /// Returns an empty map if data is not loaded.
  Map<String, List<String>> get medicineToIngredientsMap;

  /// Finds all interactions involving any active ingredient of the given medicine.
  Future<Either<Failure, List<DrugInteraction>>> findAllInteractionsForDrug(
    DrugEntity drug,
  );

  /// Checks if a drug has any known interactions efficiently (O(1) lookup).
  bool hasKnownInteractions(DrugEntity drug);

  /// Gets the maximum severity level of known interactions for a drug.
  /// Returns InteractionSeverity.unknown if no interactions found.
  InteractionSeverity getMaxSeverityForDrug(DrugEntity drug);
}
