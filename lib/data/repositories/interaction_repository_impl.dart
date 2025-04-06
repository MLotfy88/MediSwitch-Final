// lib/data/repositories/interaction_repository_impl.dart

import 'dart:convert'; // For jsonDecode
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart' show rootBundle; // For loading assets
import '../../core/error/failures.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../domain/entities/interaction_severity.dart'; // Import enum
import '../../domain/entities/interaction_type.dart'; // Import enum
import '../../domain/repositories/interaction_repository.dart';
import '../../domain/entities/active_ingredient.dart'; // Import domain entity

class InteractionRepositoryImpl implements InteractionRepository {
  // TODO: Inject necessary data sources (e.g., InteractionLocalDataSource)
  // final InteractionLocalDataSource localDataSource;
  // InteractionRepositoryImpl({required this.localDataSource});

  // Placeholder data stores (will be loaded from data source)
  List<DrugInteraction> _allInteractions = []; // Store parsed domain entities
  Map<String, List<String>> _medicineToIngredientsMap =
      {}; // Map tradeName to ingredients
  List<ActiveIngredient> _activeIngredients =
      []; // Store parsed domain entities
  bool _isDataLoaded = false; // Flag to prevent multiple loads

  @override
  Future<Either<Failure, Unit>> loadInteractionData() async {
    if (_isDataLoaded) {
      print('InteractionRepositoryImpl: Interaction data already loaded.');
      return const Right(unit); // Already loaded successfully
    }

    print('InteractionRepositoryImpl: Loading interaction data from assets...');
    try {
      // 1. Load Active Ingredients
      final ingredientsJsonString = await rootBundle.loadString(
        'assets/data/active_ingredients.json',
      );
      final List<dynamic> ingredientsJson =
          jsonDecode(ingredientsJsonString) as List<dynamic>; // Cast result
      _activeIngredients =
          ingredientsJson
              .map(
                (json) =>
                    _ActiveIngredientModel.fromJson(
                      json as Map<String, dynamic>,
                    ) // Cast element
                    .toEntity(),
              )
              .toList();

      // 2. Load Drug Interactions
      final interactionsJsonString = await rootBundle.loadString(
        'assets/data/drug_interactions.json',
      );
      final List<dynamic> interactionsJson =
          jsonDecode(interactionsJsonString) as List<dynamic>; // Cast result
      _allInteractions =
          interactionsJson
              .map(
                (json) =>
                    _DrugInteractionModel.fromJson(
                      json as Map<String, dynamic>,
                    ) // Cast element
                    .toEntity(),
              )
              .toList();

      // 3. Load Medicine to Ingredients Mapping
      final medIngredientsJsonString = await rootBundle.loadString(
        'assets/data/medicine_ingredients.json',
      );
      final Map<String, dynamic> medIngredientsJson =
          jsonDecode(medIngredientsJsonString)
              as Map<String, dynamic>; // Cast result
      _medicineToIngredientsMap = medIngredientsJson.map((key, value) {
        // Ensure keys are lowercase for consistent lookup
        // Ensure values are List<String> and ingredients are lowercase
        final ingredients =
            (value as List<dynamic>?)
                ?.map((e) => e.toString().toLowerCase().trim())
                .toList() ??
            [];
        return MapEntry(key.toLowerCase().trim(), ingredients);
      });

      _isDataLoaded = true; // Mark data as loaded
      print('InteractionRepositoryImpl: Interaction data loaded successfully.');
      print('Loaded ${_activeIngredients.length} active ingredients.');
      print('Loaded ${_allInteractions.length} interactions.');
      print('Loaded ${_medicineToIngredientsMap.length} medicine mappings.');

      return const Right(unit);
    } catch (e) {
      _isDataLoaded = false; // Ensure flag is false on error
      print('InteractionRepositoryImpl: Failed to load interaction data: $e');
      return Left(
        CacheFailure(
          message: 'Failed to load interaction data from assets: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<DrugInteraction>>> findInteractionsForMedicines(
    List<DrugEntity> medicines,
  ) async {
    // TODO: Implement actual interaction finding logic
    print(
      'InteractionRepositoryImpl: Finding interactions for ${medicines.length} medicines (Placeholder)...',
    );
    // Ensure data is loaded before finding interactions
    if (!_isDataLoaded) {
      print(
        'InteractionRepositoryImpl: Interaction data not loaded. Attempting load...',
      );
      final loadResult = await loadInteractionData();
      if (loadResult.isLeft()) {
        // Propagate the loading failure
        return loadResult.fold(
          (failure) => Left(failure),
          (_) => Left(
            CacheFailure(message: 'Unknown error after failed load attempt.'),
          ),
        );
      }
      // Check again if data is loaded after attempt
      if (!_isDataLoaded) {
        return Left(
          CacheFailure(
            message: 'Interaction data is still not loaded after attempt.',
          ),
        );
      }
      print(
        'InteractionRepositoryImpl: Data loaded successfully. Proceeding with interaction check.',
      );
    }

    try {
      List<DrugInteraction> foundInteractions = [];
      List<String> medicineNames =
          medicines.map((m) => m.tradeName.toLowerCase()).toList();
      List<List<String>> ingredientsList =
          medicines.map((m) {
            // Attempt to get ingredients from map, default to parsing active field
            return _medicineToIngredientsMap[m.tradeName.toLowerCase()] ??
                _extractIngredientsFromString(m.active);
          }).toList();

      // Iterate through all pairs of medicines
      for (int i = 0; i < medicines.length; i++) {
        for (int j = i + 1; j < medicines.length; j++) {
          final ingredients1 = ingredientsList[i];
          final ingredients2 = ingredientsList[j];

          // Check for interactions between each pair of ingredients
          for (final ing1 in ingredients1) {
            final ing1Lower = ing1.toLowerCase().trim();
            for (final ing2 in ingredients2) {
              final ing2Lower = ing2.toLowerCase().trim();
              // Find interactions in the loaded list
              foundInteractions.addAll(
                _allInteractions.where(
                  (interaction) =>
                      (interaction.ingredient1.toLowerCase() == ing1Lower &&
                          interaction.ingredient2.toLowerCase() == ing2Lower) ||
                      (interaction.ingredient1.toLowerCase() == ing2Lower &&
                          interaction.ingredient2.toLowerCase() == ing1Lower),
                ),
              );
            }
          }
        }
      }
      print(
        'InteractionRepositoryImpl: Found ${foundInteractions.length} interactions (Placeholder).',
      );
      return Right(foundInteractions);
    } catch (e) {
      print('InteractionRepositoryImpl: Error finding interactions: $e');
      return Left(CacheFailure(message: 'Failed to find interactions: $e'));
    }
  }

  // Helper function to extract ingredients from the 'active' string if not found in map
  // (Similar to logic in external source)
  List<String> _extractIngredientsFromString(String activeText) {
    final List<String> parts = activeText.split(RegExp(r'[,+]'));
    return parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  // --- Getters for Loaded Data ---

  @override
  List<DrugInteraction> get allLoadedInteractions => _allInteractions;

  @override
  Map<String, List<String>> get medicineToIngredientsMap =>
      _medicineToIngredientsMap;
}

// --- Helper Data Models for JSON Parsing ---
// These models match the JSON structure exactly.

class _ActiveIngredientModel {
  final String name;
  final String? arabicName;
  final List<String>? alternativeNames;

  _ActiveIngredientModel({
    required this.name,
    this.arabicName,
    this.alternativeNames,
  });

  factory _ActiveIngredientModel.fromJson(Map<String, dynamic> json) {
    return _ActiveIngredientModel(
      name: json['name'] as String? ?? '', // Handle potential null
      arabicName: json['arabic_name'] as String?,
      alternativeNames:
          (json['alternative_names'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
    );
  }

  // Convert to Domain Entity
  ActiveIngredient toEntity() {
    return ActiveIngredient(
      name: name.toLowerCase().trim(), // Standardize name
      arabicName: arabicName ?? '',
      alternativeNames:
          alternativeNames?.map((e) => e.toLowerCase().trim()).toList() ?? [],
    );
  }
}

class _DrugInteractionModel {
  final String ingredient1;
  final String ingredient2;
  final String severity; // Read as string first
  final String? type; // Read as string first
  final String effect;
  final String? arabicEffect;
  final String recommendation;
  final String? arabicRecommendation;

  _DrugInteractionModel({
    required this.ingredient1,
    required this.ingredient2,
    required this.severity,
    this.type,
    required this.effect,
    this.arabicEffect,
    required this.recommendation,
    this.arabicRecommendation,
  });

  factory _DrugInteractionModel.fromJson(Map<String, dynamic> json) {
    return _DrugInteractionModel(
      ingredient1: json['ingredient1'] as String? ?? '',
      ingredient2: json['ingredient2'] as String? ?? '',
      severity: json['severity'] as String? ?? 'unknown',
      type: json['type'] as String?,
      effect: json['effect'] as String? ?? '',
      arabicEffect: json['arabic_effect'] as String?,
      recommendation: json['recommendation'] as String? ?? '',
      arabicRecommendation: json['arabic_recommendation'] as String?,
    );
  }

  // Convert to Domain Entity
  DrugInteraction toEntity() {
    InteractionSeverity severityEnum;
    try {
      severityEnum = InteractionSeverity.values.byName(severity.toLowerCase());
    } catch (_) {
      severityEnum = InteractionSeverity.unknown; // Default if parsing fails
    }

    InteractionType typeEnum;
    try {
      typeEnum =
          type != null
              ? InteractionType.values.byName(type!.toLowerCase())
              : InteractionType.unknown;
    } catch (_) {
      typeEnum = InteractionType.unknown; // Default if parsing fails
    }

    return DrugInteraction(
      ingredient1: ingredient1.toLowerCase().trim(), // Standardize
      ingredient2: ingredient2.toLowerCase().trim(), // Standardize
      severity: severityEnum,
      type: typeEnum,
      effect: effect,
      arabicEffect: arabicEffect ?? '',
      recommendation: recommendation,
      arabicRecommendation: arabicRecommendation ?? '',
    );
  }
}
