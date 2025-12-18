import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/data/datasources/local/sqlite_local_data_source.dart';
import 'package:mediswitch/domain/entities/dosage_guidelines.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';

class InteractionRepositoryImpl implements InteractionRepository {
  final SqliteLocalDataSource localDataSource;

  InteractionRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Unit>> loadInteractionData() async {
    // No-op for now. Data is accessed on demand from DB.
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<DrugInteraction>>> findInteractionsForMedicines(
    List<DrugEntity> medicines,
  ) async {
    try {
      final List<DrugInteraction> results = [];
      final Set<String> addedIds = {}; // Use a string key for uniqueness

      for (int i = 0; i < medicines.length; i++) {
        final medA = medicines[i];
        if (medA.id == null) continue;

        // Fetch interactions where medA is the 'primary' drug
        final interactionsA = await localDataSource.getInteractionsForDrug(
          medA.id!,
        );

        for (final interaction in interactionsA) {
          // Check against all other medicines
          for (int j = 0; j < medicines.length; j++) {
            if (i == j) continue;
            final medB = medicines[j];

            if (_isMatch(interaction.interactionDrugName, medB)) {
              // We found a match! medA interacts with medB.
              if (!addedIds.contains(interaction.id.toString())) {
                results.add(interaction);
                addedIds.add(interaction.id.toString());
              }
            }
          }
        }
      }
      return Right(results);
    } catch (e) {
      return Left(CacheFailure(message: 'Error finding interactions: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DrugInteraction>>> findAllInteractionsForDrug(
    DrugEntity drug,
  ) async {
    try {
      if (drug.id == null) return const Right([]);
      final interactions = await localDataSource.getInteractionsForDrug(
        drug.id!,
      );
      return Right(interactions);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Error finding interactions for drug: $e'),
      );
    }
  }

  @override
  Future<bool> hasKnownInteractions(DrugEntity drug) async {
    if (drug.id == null) return false;
    try {
      final interactions = await localDataSource.getInteractionsForDrug(
        drug.id!,
      );
      return interactions.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<InteractionSeverity> getMaxSeverityForDrug(DrugEntity drug) async {
    if (drug.id == null) return InteractionSeverity.unknown;
    try {
      final interactions = await localDataSource.getInteractionsForDrug(
        drug.id!,
      );

      InteractionSeverity maxSeverity = InteractionSeverity.unknown;
      for (final interaction in interactions) {
        // Map string severity to enum
        final severityEnum = _parseSeverity(interaction.severity);
        if (_getSeverityWeight(severityEnum) >
            _getSeverityWeight(maxSeverity)) {
          maxSeverity = severityEnum;
        }
      }
      return maxSeverity;
    } catch (e) {
      return InteractionSeverity.unknown;
    }
  }

  @override
  Future<int> getInteractionCountForDrug(DrugEntity drug) async {
    if (drug.id == null) return 0;
    try {
      final interactions = await localDataSource.getInteractionsForDrug(
        drug.id!,
      );
      return interactions.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<List<String>> getHighRiskIngredients() async {
    // Deprecated / Not implemented
    return [];
  }

  @override
  Future<List<DrugEntity>> getHighRiskDrugs(int limit) async {
    try {
      final models = await localDataSource.getHighRiskMedicines(limit);
      return List<DrugEntity>.from(models);
    } catch (e) {
      debugPrint('Error getting high risk drugs: $e');
      return [];
    }
  }

  @override
  Future<List<DosageGuidelines>> getDosageGuidelines(DrugEntity drug) async {
    if (drug.id == null) return [];
    try {
      return await localDataSource.getDosageGuidelines(drug.id!);
    } catch (e) {
      debugPrint('Error getting dosage guidelines: $e');
      return [];
    }
  }

  // Helper
  InteractionSeverity _parseSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'contraindicated':
        return InteractionSeverity.contraindicated;
      case 'severe':
        return InteractionSeverity.severe;
      case 'major':
        return InteractionSeverity.major;
      case 'moderate':
        return InteractionSeverity.moderate; // Fixed Typo
      case 'minor':
        return InteractionSeverity.minor;
      default:
        return InteractionSeverity.unknown;
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
  Future<List<DrugInteraction>> getHighRiskInteractions({
    int limit = 50,
  }) async {
    try {
      final interactions = await localDataSource.getHighRiskInteractions(
        limit: limit,
      );
      return List<DrugInteraction>.from(interactions);
    } catch (e) {
      debugPrint('Error getting high risk interactions: $e');
      return [];
    }
  }

  @override
  Future<List<DrugInteraction>> getInteractionsWith(String drugName) async {
    try {
      final interactions = await localDataSource.getInteractionsWith(drugName);
      return List<DrugInteraction>.from(interactions);
    } catch (e) {
      debugPrint('Error getting interactions with $drugName: $e');
      return [];
    }
  }

  // Helper to match names locally for list checking
  bool _isMatch(String interactionName, DrugEntity drug) {
    final name = interactionName.toLowerCase().trim();

    // 1. Direct Trade Name Match
    if (name == drug.tradeName.toLowerCase().trim()) return true;

    // 2. Active Ingredient Match (Handle multiple ingredients)
    final activeStr = drug.active.toLowerCase().trim();
    if (name == activeStr) return true;

    // Split by common separators: ';', '+', '/'
    final ingredients =
        activeStr.split(RegExp(r'[;+/]')).map((e) => e.trim()).toList();
    if (ingredients.contains(name)) return true;

    return false;
  }
}
