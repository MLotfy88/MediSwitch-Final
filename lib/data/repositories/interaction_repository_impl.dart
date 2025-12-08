// lib/data/repositories/interaction_repository_impl.dart
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/services.dart' show rootBundle;
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/core/utils/fuzzy_matcher.dart';
import 'package:mediswitch/data/services/interaction_sync_service.dart';
import 'package:mediswitch/domain/entities/dosage_guidelines.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';
import 'package:mediswitch/domain/services/interaction_analyzer_service.dart';
import 'package:mediswitch/domain/services/interaction_index.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InteractionRepositoryImpl implements InteractionRepository {
  List<DrugInteraction> _allInteractions = [];
  Map<String, List<String>> _medicineToIngredientsMap = {};
  bool _isDataLoaded = false;

  final InteractionSyncService _syncService = InteractionSyncService();
  static const String _updatesFileName = 'interaction_updates.json';
  static const String _lastSyncKey = 'last_interaction_sync_date';

  // Cache for fast lookup
  final Set<String> _ingredientsWithKnownInteractions = {};
  final Map<String, InteractionSeverity> _ingredientMaxSeverity = {};

  // Search index for O(1) lookups
  final InteractionIndex _searchIndex = InteractionIndex();

  @override
  Future<Either<Failure, Unit>> loadInteractionData() async {
    if (_isDataLoaded) return const Right(unit);

    try {
      debugPrint('InteractionRepositoryImpl: Loading new interaction data...');

      // 1. Load Medicine Ingredients Map
      final medIngredientsJsonString = await rootBundle.loadString(
        'assets/data/medicine_ingredients.json',
      );
      final Map<String, dynamic> medIngredientsJson =
          jsonDecode(medIngredientsJsonString) as Map<String, dynamic>;

      _medicineToIngredientsMap = medIngredientsJson.map((key, value) {
        final ingredients =
            (value as List<dynamic>?)
                ?.map((e) => e.toString().toLowerCase().trim())
                .toList() ??
            [];
        return MapEntry(key.toLowerCase().trim(), ingredients);
      });

      // 2. Load Base Drug Interactions (Bundled)
      final interactionsJsonString = await rootBundle.loadString(
        'assets/data/drug_interactions.json',
      );
      final List<dynamic> interactionsListJson =
          jsonDecode(interactionsJsonString) as List<dynamic>;

      _allInteractions =
          interactionsListJson
              .map(
                (json) =>
                    DrugInteraction.fromJson(json as Map<String, dynamic>),
              )
              .toList();

      // 3. Load Local Updates (if any)
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_updatesFileName');
        if (await file.exists()) {
          final updatesJsonString = await file.readAsString();
          final List<dynamic> updatesListJson =
              jsonDecode(updatesJsonString) as List<dynamic>;
          final updates =
              updatesListJson
                  .map(
                    (json) =>
                        DrugInteraction.fromJson(json as Map<String, dynamic>),
                  )
                  .toList();

          _allInteractions.addAll(updates);
          debugPrint(
            'InteractionRepositoryImpl: Loaded ${updates.length} updates from local storage.',
          );
        }
      } catch (e) {
        debugPrint(
          'InteractionRepositoryImpl: Error loading local updates: $e',
        );
      }

      // 4. Trigger Background Sync
      _syncUpdates();

      // 3. Populate fast lookup set
      _ingredientsWithKnownInteractions.clear();
      for (final interaction in _allInteractions) {
        _ingredientsWithKnownInteractions.add(
          interaction.ingredient1.toLowerCase(),
        );
        _ingredientsWithKnownInteractions.add(
          interaction.ingredient2.toLowerCase(),
        );

        _updateMaxSeverity(
          interaction.ingredient1.toLowerCase(),
          interaction.severity,
        );
        _updateMaxSeverity(
          interaction.ingredient2.toLowerCase(),
          interaction.severity,
        );
      }

      // 4. Build search index
      debugPrint('InteractionRepositoryImpl: Building search index...');
      _searchIndex.buildIndex(_allInteractions);

      _isDataLoaded = true;
      debugPrint(
        'InteractionRepositoryImpl: Loaded ${_allInteractions.length} interactions, '
        '${_medicineToIngredientsMap.length} medicine maps, '
        'and indexed ${_searchIndex.totalInteractions} for fast lookup.',
      );

      return const Right(unit);
    } catch (e, stacktrace) {
      debugPrint('InteractionRepositoryImpl: Failed to load data: $e');
      debugPrint(stacktrace.toString());
      _isDataLoaded = false;
      return Left(CacheFailure(message: 'Failed to load interaction data: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DrugInteraction>>> findInteractionsForMedicines(
    List<DrugEntity> medicines,
  ) async {
    if (!_isDataLoaded) {
      await loadInteractionData();
    }

    try {
      // 1. Get names and ingredients
      final List<String> medicineNames =
          medicines.map((m) => m.tradeName).toList();

      // Prepare pairwise interactions for the analyzer
      final List<Map<String, dynamic>> pairwiseInteractions = [];
      final List<DrugInteraction> flatInteractions = [];

      for (int i = 0; i < medicines.length; i++) {
        for (int j = i + 1; j < medicines.length; j++) {
          final med1 = medicines[i];
          final med2 = medicines[j];

          final ingredients1 = _getIngredients(med1);
          final ingredients2 = _getIngredients(med2);

          final List<DrugInteraction> currentPairInteractions = [];

          for (final ing1 in ingredients1) {
            for (final ing2 in ingredients2) {
              final matches = _allInteractions.where(
                (interaction) =>
                    (interaction.ingredient1 == ing1 &&
                        interaction.ingredient2 == ing2) ||
                    (interaction.ingredient1 == ing2 &&
                        interaction.ingredient2 == ing1),
              );
              currentPairInteractions.addAll(matches);
            }
          }

          if (currentPairInteractions.isNotEmpty) {
            flatInteractions.addAll(currentPairInteractions);
            pairwiseInteractions.add({
              'medicine1': med1.tradeName,
              'medicine2': med2.tradeName,
              'interactions': currentPairInteractions,
            });
          }
        }
      }

      // Optional: Run the full analyzer to get advanced insights (graph paths)
      if (pairwiseInteractions.isNotEmpty) {
        final analysisResult = MultiDrugInteractionAnalyzer.analyzeInteractions(
          medicineNames,
          pairwiseInteractions,
        );
        debugPrint(
          'Analyzer Result Severity: ${analysisResult['overall_severity']}',
        );
      }

      return Right(flatInteractions.toSet().toList());
    } catch (e) {
      return Left(CacheFailure(message: 'Error finding interactions: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DrugInteraction>>> findAllInteractionsForDrug(
    DrugEntity drug,
  ) async {
    if (!_isDataLoaded) {
      await loadInteractionData();
    }

    try {
      final ingredients = _getIngredients(drug);
      if (ingredients.isEmpty) return const Right([]);

      final Set<String> drugIngredientsSet = ingredients.toSet();
      final List<DrugInteraction> foundInteractions = [];

      for (final interaction in _allInteractions) {
        if (drugIngredientsSet.contains(interaction.ingredient1) ||
            drugIngredientsSet.contains(interaction.ingredient2)) {
          foundInteractions.add(interaction);
        }
      }

      return Right(foundInteractions);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Error finding interactions for drug: $e'),
      );
    }
  }

  @override
  bool hasKnownInteractions(DrugEntity drug) {
    if (!_isDataLoaded) return false;

    final ingredients = _getIngredients(drug);
    for (final ingredient in ingredients) {
      if (_ingredientsWithKnownInteractions.contains(ingredient)) {
        return true;
      }
    }
    return false;
  }

  @override
  InteractionSeverity getMaxSeverityForDrug(DrugEntity drug) {
    if (!_isDataLoaded) return InteractionSeverity.unknown;

    final ingredients = _getIngredients(drug);
    InteractionSeverity maxSeverity = InteractionSeverity.unknown;

    for (final ingredient in ingredients) {
      if (_ingredientMaxSeverity.containsKey(ingredient)) {
        final severity = _ingredientMaxSeverity[ingredient]!;
        if (_getSeverityWeight(severity) > _getSeverityWeight(maxSeverity)) {
          maxSeverity = severity;
        }
      }
    }
    return maxSeverity;
  }

  void _updateMaxSeverity(String ingredient, InteractionSeverity newSeverity) {
    if (!_ingredientMaxSeverity.containsKey(ingredient)) {
      _ingredientMaxSeverity[ingredient] = newSeverity;
    } else {
      final current = _ingredientMaxSeverity[ingredient]!;
      if (_getSeverityWeight(newSeverity) > _getSeverityWeight(current)) {
        _ingredientMaxSeverity[ingredient] = newSeverity;
      }
    }
  }

  int _getSeverityWeight(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return 5;
      case InteractionSeverity.severe:
        return 4;
      case InteractionSeverity.major:
        return 3;
      case InteractionSeverity.moderate:
        return 2;
      case InteractionSeverity.minor:
        return 1;
      case InteractionSeverity.unknown:
        return 0;
    }
  }

  @override
  List<DrugInteraction> get allLoadedInteractions => _allInteractions;

  @override
  Map<String, List<String>> get medicineToIngredientsMap =>
      _medicineToIngredientsMap;

  // Enhanced helper to get ingredients with fuzzy matching
  List<String> _getIngredients(DrugEntity drug) {
    final List<String> results = [];
    final tradeNameLower = drug.tradeName.toLowerCase().trim();

    // Strategy 1: Exact match in medicine map
    if (_medicineToIngredientsMap.containsKey(tradeNameLower)) {
      results.addAll(_medicineToIngredientsMap[tradeNameLower]!);
    }

    // Strategy 2: Also add the drug name itself (for OpenFDA data)
    // OpenFDA uses drug names like "aspirin", "warfarin" directly
    results.add(tradeNameLower);

    // Strategy 3: Parse active ingredient string
    final parsed = _extractIngredientsFromString(drug.active);
    results.addAll(parsed);

    // Strategy 4: Fuzzy matching against indexed ingredients (if no exact match)
    if (results.length <= 2) {
      // Only trade name + maybe one parsed
      final indexed = _searchIndex.allIndexedIngredients;
      if (indexed.isNotEmpty) {
        final match = FuzzyMatcher.findBestMatch(
          tradeNameLower,
          indexed,
          minThreshold: 0.7, // 70% similarity
        );
        if (match != null) {
          results.add(match.value1);
          debugPrint(
            'FuzzyMatch: "$tradeNameLower" → "${match.value1}" (${(match.value2 * 100).toStringAsFixed(0)}%)',
          );
        }
      }
    }

    // Remove duplicates
    return results.toSet().toList();
  }

  List<String> _extractIngredientsFromString(String activeText) {
    if (activeText.isEmpty) return [];

    // Enhanced parsing with better separators
    final List<String> parts = activeText.split(
      RegExp(r'[,+/|&]|\s+and\s+|\s+with\s+'),
    );

    return parts
        .map((part) {
          // Remove dosage info and common suffixes
          String cleaned = part.replaceAll(
            RegExp(
              r'\b\d+(\.\d+)?\s*(mg|mcg|g|ml|%|iu|units?|u|tablet|capsule|syrup|injection)\b',
              caseSensitive: false,
            ),
            '',
          );
          cleaned = cleaned.replaceAll(RegExp(r'\b\d+(\.\d+)?\b'), '');
          cleaned = cleaned.replaceAll(RegExp(r'[()\[\]"]'), '');
          cleaned = FuzzyMatcher.normalize(cleaned);
          return cleaned;
        })
        .where((part) => part.length > 2) // Ignore very short
        .toList();
  }

  /// Syncs interactions in the background
  Future<void> _syncUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);

      // Fetch updates
      final newInteractions = await _syncService.fetchUpdates(lastSync);

      if (newInteractions.isEmpty) return;

      // Save updates locally
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_updatesFileName');

      List<DrugInteraction> existingUpdates = [];
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
        existingUpdates =
            jsonList
                .map(
                  (json) =>
                      DrugInteraction.fromJson(json as Map<String, dynamic>),
                )
                .toList();
      }

      existingUpdates.addAll(newInteractions);

      // Write back
      final updatedJsonList = existingUpdates.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(updatedJsonList));

      // Update Prefs
      await prefs.setString(
        _lastSyncKey,
        DateTime.now().toIso8601String().split('T')[0],
      );

      debugPrint(
        'InteractionRepositoryImpl: Synced and saved ${newInteractions.length} new interactions.',
      );

      // Note: We don't update _allInteractions in memory here to avoid complexity with concurrency.
      // The new data will be loaded on next app restart.
      // This is acceptable for large datasets.
    } catch (e) {
      debugPrint('InteractionRepositoryImpl: Background sync failed: $e');
    }
  }

  @override
  int getInteractionCountForDrug(DrugEntity drug) {
    if (!_isDataLoaded) return 0;

    // Get all ingredients for this drug
    final ingredients = _getIngredientsForDrug(drug);
    if (ingredients.isEmpty) return 0;

    // Use the search index to find all interactions for these ingredients
    int count = 0;
    for (final ingredient in ingredients) {
      final interactions = _searchIndex.findByIngredient(ingredient);
      count += interactions.length;
    }
    return count;
  }

  @override
  List<String> getHighRiskIngredients() {
    if (!_isDataLoaded) return [];

    final highRiskIngredients = <String>{};
    for (final entry in _ingredientMaxSeverity.entries) {
      if (entry.value == InteractionSeverity.contraindicated ||
          entry.value == InteractionSeverity.severe ||
          entry.value == InteractionSeverity.major) {
        highRiskIngredients.add(entry.key);
      }
    }
    // Return sorted list for consistency
    return highRiskIngredients.toList()..sort();
  }

  // Helper to get ingredients for a drug
  List<String> _getIngredientsForDrug(DrugEntity drug) {
    final tradeNameLower = drug.tradeName.toLowerCase().trim();
    final activeLower = drug.active.toLowerCase().trim();

    // Try medicine-to-ingredients map
    if (_medicineToIngredientsMap.containsKey(tradeNameLower)) {
      return _medicineToIngredientsMap[tradeNameLower]!;
    }

    // Fallback to active ingredient
    if (activeLower.isNotEmpty) {
      return [activeLower];
    }

    return [];
  }

  @override
  Future<List<DosageGuidelines>> getDosageGuidelines(
    String activeIngredient,
  ) async {
    return [];
  }
}
