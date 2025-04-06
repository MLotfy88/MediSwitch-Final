// lib/domain/repositories/interaction_repository.dart

import 'package:dartz/dartz.dart'; // For Either
import '../../core/error/failures.dart'; // For Failure
import '../entities/drug_entity.dart';
import '../entities/drug_interaction.dart';
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

  // Add other methods if needed, e.g., finding interactions for a single pair,
  // or getting active ingredients for a specific medicine if not handled elsewhere.
}
