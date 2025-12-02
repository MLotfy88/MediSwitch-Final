// lib/data/repositories/interaction_repository_impl.dart

import 'dart:async'; // Import for Completer
import 'dart:convert'; // For jsonDecode
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart'; // For compute and kDebugMode
import 'package:flutter/services.dart' show rootBundle; // For loading assets
import '../../core/error/failures.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../domain/entities/interaction_severity.dart'; // Import enum
import '../../domain/entities/interaction_type.dart'; // Import enum
import '../../domain/repositories/interaction_repository.dart';
import '../../domain/entities/active_ingredient.dart'; // Import domain entity

// --- Data structure to pass data to and from the isolate ---
// --- Data structures for isolate communication ---
class _ParseInteractionDataParams {
  // Removed ingredientsJsonString as we might not need active_ingredients.json
  final String
  interactionsJsonString; // For drug_interactions_structured_data.json
  final String medIngredientsJsonString; // For medicine_ingredients.json

  _ParseInteractionDataParams({
    required this.interactionsJsonString,
    required this.medIngredientsJsonString,
  });
}

class _ParsedInteractionData {
  // Removed activeIngredients list
  final List<DrugInteraction> allInteractions;
  final Map<String, List<String>> medicineToIngredientsMap;

  _ParsedInteractionData({
    required this.allInteractions,
    required this.medicineToIngredientsMap,
  });
}

// --- Helper models for parsing the NEW interaction JSON structure ---
class _RawInteractionEntryModel {
  final String activeIngredient;
  final List<_ParsedInteractionModel> parsedInteractions;

  _RawInteractionEntryModel({
    required this.activeIngredient,
    required this.parsedInteractions,
  });

  factory _RawInteractionEntryModel.fromJson(Map<String, dynamic> json) {
    var interactionsList =
        (json['parsed_interactions'] as List<dynamic>?) ?? [];
    return _RawInteractionEntryModel(
      activeIngredient: json['active_ingredient'] as String? ?? '',
      parsedInteractions:
          interactionsList
              .map(
                (i) =>
                    _ParsedInteractionModel.fromJson(i as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class _ParsedInteractionModel {
  final String interactingSubstance;
  final String severity;
  final String description;

  _ParsedInteractionModel({
    required this.interactingSubstance,
    required this.severity,
    required this.description,
  });

  factory _ParsedInteractionModel.fromJson(Map<String, dynamic> json) {
    return _ParsedInteractionModel(
      interactingSubstance: json['interacting_substance'] as String? ?? '',
      severity: json['severity'] as String? ?? 'unknown',
      description: json['description'] as String? ?? '',
    );
  }
}

// --- Top-level function for parsing in isolate (MODIFIED) ---
_ParsedInteractionData _parseInteractionDataIsolate(
  _ParseInteractionDataParams params,
) {
  // 1. Parse Drug Interactions (NEW STRUCTURE)
  final List<dynamic> rawInteractionsListJson =
      jsonDecode(params.interactionsJsonString) as List<dynamic>;

  final List<DrugInteraction> allInteractions = [];

  for (final rawEntryJson in rawInteractionsListJson) {
    if (rawEntryJson is Map<String, dynamic>) {
      final rawEntry = _RawInteractionEntryModel.fromJson(rawEntryJson);
      final mainIngredient = rawEntry.activeIngredient.toLowerCase().trim();

      for (final parsedInteraction in rawEntry.parsedInteractions) {
        final interactingSubstance =
            parsedInteraction.interactingSubstance.toLowerCase().trim();

        // Skip self-interactions or interactions with empty substances
        if (mainIngredient.isEmpty ||
            interactingSubstance.isEmpty ||
            mainIngredient == interactingSubstance) {
          continue;
        }

        InteractionSeverity severityEnum;
        try {
          severityEnum = InteractionSeverity.values.byName(
            parsedInteraction.severity.toLowerCase(),
          );
        } catch (_) {
          severityEnum = InteractionSeverity.unknown;
        }

        // Create the DrugInteraction entity
        allInteractions.add(
          DrugInteraction(
            ingredient1: mainIngredient,
            ingredient2: interactingSubstance,
            severity: severityEnum,
            effect: parsedInteraction.description, // Use description as effect
            recommendation: '', // Keep recommendation empty for now
            type: InteractionType.unknown, // Default type
            arabicEffect: '',
            arabicRecommendation: '',
          ),
        );
      }
    }
  }

  // 2. Parse Medicine to Ingredients Mapping (Unchanged logic)
  final Map<String, dynamic> medIngredientsJson =
      jsonDecode(params.medIngredientsJsonString) as Map<String, dynamic>;
  final medicineToIngredientsMap = medIngredientsJson.map((key, value) {
    final ingredients =
        (value as List<dynamic>?)
            ?.map((e) => e.toString().toLowerCase().trim())
            .toList() ??
        [];
    return MapEntry(key.toLowerCase().trim(), ingredients);
  });

  print('Isolate: Parsed interaction data successfully.');
  print('Isolate: Processed ${allInteractions.length} interaction pairs.');
  print(
    'Isolate: Processed ${medicineToIngredientsMap.length} medicine mappings.',
  );

  return _ParsedInteractionData(
    // activeIngredients list removed
    allInteractions: allInteractions,
    medicineToIngredientsMap: medicineToIngredientsMap,
  );
}

class InteractionRepositoryImpl implements InteractionRepository {
  // Placeholder data stores (will be loaded from data source)
  List<DrugInteraction> _allInteractions = []; // Store parsed domain entities
  Map<String, List<String>> _medicineToIngredientsMap =
      {}; // Map tradeName to ingredients
  // Removed _activeIngredients list
  bool _isDataLoaded = false; // Flag to indicate successful load
  Future<Either<Failure, Unit>>?
  _loadingFuture; // Future for ongoing load operation

  @override
  Future<Either<Failure, Unit>> loadInteractionData() async {
    // If data is already loaded, return success immediately
    if (_isDataLoaded) {
      print('InteractionRepositoryImpl: Interaction data already loaded.');
      return const Right(unit);
    }

    // If loading is already in progress, wait for it to complete
    if (_loadingFuture != null) {
      print(
        'InteractionRepositoryImpl: Waiting for ongoing interaction data load...',
      );
      return _loadingFuture!;
    }

    // Start the loading process
    print('InteractionRepositoryImpl: Starting interaction data load...');
    final completer = Completer<Either<Failure, Unit>>();
    _loadingFuture = completer.future;

    try {
      // Determine which interaction file to load
      const interactionAssetPath =
          'assets/drug_interactions_structured_data.json';
      print(
        'InteractionRepositoryImpl: Loading interaction file: $interactionAssetPath',
      );

      // Load JSON strings from assets
      final interactionsJsonString = await rootBundle.loadString(
        interactionAssetPath,
      );
      final medIngredientsJsonString = await rootBundle.loadString(
        'assets/data/medicine_ingredients.json',
      );

      // Parse data in a separate isolate using compute
      print('InteractionRepositoryImpl: Starting data parsing in isolate...');
      final parsedData = await compute(
        _parseInteractionDataIsolate,
        _ParseInteractionDataParams(
          interactionsJsonString: interactionsJsonString,
          medIngredientsJsonString: medIngredientsJsonString,
        ),
      );
      print('InteractionRepositoryImpl: Isolate parsing complete.');

      // Assign parsed data to internal state
      _allInteractions = parsedData.allInteractions;
      _medicineToIngredientsMap = parsedData.medicineToIngredientsMap;

      // Populate the fast lookup set
      _ingredientsWithKnownInteractions.clear();
      for (final interaction in _allInteractions) {
        _ingredientsWithKnownInteractions.add(interaction.ingredient1);
        _ingredientsWithKnownInteractions.add(interaction.ingredient2);
      }

      _isDataLoaded = true; // Mark data as loaded successfully
      print('InteractionRepositoryImpl: Interaction data loaded successfully.');
      print('Loaded ${_allInteractions.length} interaction pairs.');
      print('Loaded ${_medicineToIngredientsMap.length} medicine mappings.');
      print('Indexed ${_ingredientsWithKnownInteractions.length} ingredients with interactions.');

      completer.complete(const Right(unit)); // Complete the future with success
    } catch (e, stacktrace) {
      _isDataLoaded = false; // Ensure flag is false on error
      print('InteractionRepositoryImpl: Failed to load interaction data: $e');
      print('Stacktrace: $stacktrace');
      final failure = CacheFailure(
        message: 'Failed to load interaction data from assets: $e',
      );
      completer.complete(Left(failure)); // Complete the future with failure
    } finally {
      // Reset the loading future once the operation is complete (success or failure)
      _loadingFuture = null;
      print('InteractionRepositoryImpl: Loading future reset.');
    }

    return completer.future; // Return the completed future
  }

  @override
  Future<Either<Failure, List<DrugInteraction>>> findInteractionsForMedicines(
    List<DrugEntity> medicines,
  ) async {
    print(
      'InteractionRepositoryImpl: Finding interactions for ${medicines.length} medicines...',
    );

    // Ensure data is loaded, waiting if necessary
    if (!_isDataLoaded) {
      print(
        'InteractionRepositoryImpl: Interaction data not loaded. Awaiting loadInteractionData...',
      );
      final loadResult =
          await loadInteractionData(); // Will wait for ongoing load
      if (loadResult.isLeft()) {
        print(
          'InteractionRepositoryImpl: Loading failed during findInteractionsForMedicines.',
        );
        // Propagate the loading failure
        return loadResult.fold(
          (failure) => Left(failure),
          (_) => Left(
            CacheFailure(message: 'Unknown error after failed load attempt.'),
          ), // Should not happen
        );
      }
      // Check again if data is loaded after waiting
      if (!_isDataLoaded) {
        print(
          'InteractionRepositoryImpl: Data still not loaded after waiting.',
        );
        return Left(
          CacheFailure(
            message:
                'Interaction data is still not loaded after waiting for load.',
          ),
        );
      }
      print(
        'InteractionRepositoryImpl: Data loaded successfully after waiting.',
      );
    } else {
      print('InteractionRepositoryImpl: Data was already loaded.');
    }

    // --- Proceed with finding interactions ---
    try {
      List<DrugInteraction> foundInteractions = [];
      List<List<String>> ingredientsList =
          medicines.map((m) {
            return _medicineToIngredientsMap[m.tradeName
                    .toLowerCase()
                    .trim()] ??
                _extractIngredientsFromString(m.active);
          }).toList();

      for (int i = 0; i < medicines.length; i++) {
        for (int j = i + 1; j < medicines.length; j++) {
          final ingredients1 = ingredientsList[i];
          final ingredients2 = ingredientsList[j];

          for (final ing1 in ingredients1) {
            final ing1Lower = ing1.toLowerCase().trim();
            for (final ing2 in ingredients2) {
              final ing2Lower = ing2.toLowerCase().trim();
              foundInteractions.addAll(
                _allInteractions.where(
                  (interaction) =>
                      (interaction.ingredient1 == ing1Lower &&
                          interaction.ingredient2 == ing2Lower) ||
                      (interaction.ingredient1 == ing2Lower &&
                          interaction.ingredient2 == ing1Lower),
                ),
              );
            }
          }
        }
      }
      foundInteractions = foundInteractions.toSet().toList();

      print(
        'InteractionRepositoryImpl: Found ${foundInteractions.length} interactions.',
      );
      return Right(foundInteractions);
    } catch (e, stacktrace) {
      print('InteractionRepositoryImpl: Error finding interactions: $e');
      print('Stacktrace: $stacktrace');
      return Left(CacheFailure(message: 'Failed to find interactions: $e'));
    }
  }

  // Helper function to extract ingredients from the 'active' string if not found in map
  List<String> _extractIngredientsFromString(String activeText) {
    final List<String> parts = activeText.split(RegExp(r'[,+]'));
    return parts
        .map((part) => part.trim().toLowerCase()) // Standardize to lowercase
        .where((part) => part.isNotEmpty)
        .toList();
  }

  // --- Getters for Loaded Data ---

  @override
  List<DrugInteraction> get allLoadedInteractions => _allInteractions;

  @override
  Map<String, List<String>> get medicineToIngredientsMap =>
      _medicineToIngredientsMap;

  // --- Fast Lookup Optimization ---
  final Set<String> _ingredientsWithKnownInteractions = {};

  @override
  bool hasKnownInteractions(DrugEntity drug) {
    if (!_isDataLoaded) return false;

    final drugTradeNameLower = drug.tradeName.toLowerCase().trim();
    // Check if trade name is directly mapped
    if (_medicineToIngredientsMap.containsKey(drugTradeNameLower)) {
       final ingredients = _medicineToIngredientsMap[drugTradeNameLower]!;
       for (final ingredient in ingredients) {
         if (_ingredientsWithKnownInteractions.contains(ingredient)) {
           return true;
         }
       }
       return false;
    }

    // Fallback to parsing active string
    final ingredients = _extractIngredientsFromString(drug.active);
    for (final ingredient in ingredients) {
      if (_ingredientsWithKnownInteractions.contains(ingredient)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<Either<Failure, List<DrugInteraction>>> findAllInteractionsForDrug(
    DrugEntity drug,
  ) async {
    print(
      'InteractionRepositoryImpl: Finding all interactions for drug: ${drug.tradeName}',
    );

    // Ensure data is loaded, waiting if necessary
    if (!_isDataLoaded) {
      print(
        'InteractionRepositoryImpl: Interaction data not loaded. Awaiting loadInteractionData...',
      );
      final loadResult =
          await loadInteractionData(); // Will wait for ongoing load
      if (loadResult.isLeft()) {
        print(
          'InteractionRepositoryImpl: Loading failed during findAllInteractionsForDrug.',
        );
        // Propagate the loading failure
        return loadResult.fold(
          (failure) => Left(failure),
          (_) => Left(
            CacheFailure(message: 'Unknown error after failed load attempt.'),
          ), // Should not happen
        );
      }
      // Check again if data is loaded after waiting
      if (!_isDataLoaded) {
        print(
          'InteractionRepositoryImpl: Data still not loaded after waiting.',
        );
        return Left(
          CacheFailure(
            message:
                'Interaction data is still not loaded after waiting for load.',
          ),
        );
      }
      print(
        'InteractionRepositoryImpl: Data loaded successfully after waiting.',
      );
    } else {
      print('InteractionRepositoryImpl: Data was already loaded.');
    }

    // --- Proceed with finding interactions ---
    try {
      final drugTradeNameLower = drug.tradeName.toLowerCase().trim();
      final drugIngredients =
          _medicineToIngredientsMap[drugTradeNameLower] ??
          _extractIngredientsFromString(drug.active);

      if (drugIngredients.isEmpty) {
        print(
          'InteractionRepositoryImpl: No ingredients found for drug: ${drug.tradeName}',
        );
        return const Right([]); // No ingredients, so no interactions
      }

      final Set<String> drugIngredientsSet =
          drugIngredients.toSet(); // For efficient lookup
      List<DrugInteraction> foundInteractions = [];

      for (final interaction in _allInteractions) {
        if (drugIngredientsSet.contains(interaction.ingredient1) ||
            drugIngredientsSet.contains(interaction.ingredient2)) {
          foundInteractions.add(interaction);
        }
      }

      print(
        'InteractionRepositoryImpl: Found ${foundInteractions.length} interactions for ${drug.tradeName}.',
      );
      return Right(foundInteractions);
    } catch (e, stacktrace) {
      print(
        'InteractionRepositoryImpl: Error finding interactions for drug ${drug.tradeName}: $e',
      );
      print('Stacktrace: $stacktrace');
      return Left(
        CacheFailure(
          message: 'Failed to find interactions for drug ${drug.tradeName}: $e',
        ),
      );
    }
  }
}

// --- Helper Data Models for JSON Parsing ---
// Removed _ActiveIngredientModel and _DrugInteractionModel as they are replaced
// by _RawInteractionEntryModel and _ParsedInteractionModel used within the isolate function.
