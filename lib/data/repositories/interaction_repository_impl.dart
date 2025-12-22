import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:mediswitch/core/database/database_helper.dart';
import 'package:mediswitch/core/di/locator.dart';
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/core/services/file_logger_service.dart';
import 'package:mediswitch/data/datasources/local/sqlite_local_data_source.dart';
import 'package:mediswitch/data/datasources/remote/drug_remote_data_source.dart';
import 'package:mediswitch/domain/entities/dosage_guidelines.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/high_risk_ingredient.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';
import 'package:sqflite/sqflite.dart';

class InteractionRepositoryImpl implements InteractionRepository {
  final SqliteLocalDataSource localDataSource;
  final FileLoggerService _logger;

  InteractionRepositoryImpl({
    required this.localDataSource,
    required FileLoggerService logger,
  }) : _logger = logger;

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
  Future<List<HighRiskIngredient>> getHighRiskIngredients() async {
    try {
      final List<Map<String, dynamic>> maps = await localDataSource
          .getHighRiskIngredientsWithMetrics(limit: 10);

      return maps.map((m) {
        return HighRiskIngredient(
          name: m['name'] as String,
          totalInteractions: m['totalInteractions'] as int,
          severeCount: m['severeCount'] as int,
          moderateCount: m['moderateCount'] as int,
          minorCount: m['minorCount'] as int,
          dangerScore: m['dangerScore'] as int,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting high risk ingredients: $e');
      return [];
    }
  }

  @override
  Future<List<DrugEntity>> getHighRiskDrugs(int limit) async {
    _logger.d('[InteractionRepo] getHighRiskDrugs called with limit=$limit');
    try {
      final models = await localDataSource.getHighRiskMedicines(limit);
      _logger.d(
        '[InteractionRepo] Received ${models.length} models from data source',
      );
      return List<DrugEntity>.from(models);
    } catch (e, stackTrace) {
      _logger.e(
        '[InteractionRepo] ❌ EXCEPTION in getHighRiskDrugs',
        e,
        stackTrace,
      );
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
  // Synchronize interaction rules with remote server
  @override
  Future<Either<Failure, int>> syncInteractions(int lastTimestamp) async {
    try {
      final remoteDataSource = locator<DrugRemoteDataSource>();
      final Either<Failure, Map<String, dynamic>> result =
          await remoteDataSource.getDeltaSyncInteractions(lastTimestamp);

      return await result.fold(
        (Failure failure) => Left<Failure, int>(failure),
        (Map<String, dynamic> data) async {
          final List<dynamic> rulesRaw = (data['data'] as List?) ?? [];
          final List<Map<String, dynamic>> rulesData =
              rulesRaw.cast<Map<String, dynamic>>();

          if (rulesData.isNotEmpty) {
            final db = await localDataSource.dbHelper.database;
            await db.transaction((txn) async {
              final batch = txn.batch();
              for (final ruleMap in rulesData) {
                batch.insert(
                  DatabaseHelper.interactionsTable,
                  {
                    'id': ruleMap['id'],
                    'ingredient1': ruleMap['ingredient1'],
                    'ingredient2': ruleMap['ingredient2'],
                    'severity': ruleMap['severity'],
                    'effect': ruleMap['effect'],
                    'source': ruleMap['source'],
                    'updated_at': ruleMap['updated_at'],
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
              await batch.commit(noResult: true);
            });
            return Right<Failure, int>(rulesData.length);
          }
          return const Right<Failure, int>(0);
        },
      );
    } catch (e) {
      return Left<Failure, int>(ServerFailure(message: e.toString()));
    }
  }

  // Synchronize medicine-ingredient mapping with remote server
  @override
  Future<Either<Failure, int>> syncMedIngredients(int lastTimestamp) async {
    try {
      final remoteDataSource = locator<DrugRemoteDataSource>();
      final Either<Failure, Map<String, dynamic>> result =
          await remoteDataSource.getDeltaSyncMedIngredients(lastTimestamp);

      return await result.fold(
        (Failure failure) => Left<Failure, int>(failure),
        (Map<String, dynamic> data) async {
          final List<dynamic> mappingRaw = (data['data'] as List?) ?? [];
          final List<Map<String, dynamic>> mappingData =
              mappingRaw.cast<Map<String, dynamic>>();

          if (mappingData.isNotEmpty) {
            final db = await localDataSource.dbHelper.database;
            await db.transaction((txn) async {
              final batch = txn.batch();
              for (final map in mappingData) {
                batch.insert('med_ingredients', {
                  'med_id': map['med_id'],
                  'ingredient': map['ingredient'],
                  'updated_at': map['updated_at'],
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              }
              await batch.commit(noResult: true);
            });
            return Right<Failure, int>(mappingData.length);
          }
          return const Right<Failure, int>(0);
        },
      );
    } catch (e) {
      return Left<Failure, int>(ServerFailure(message: e.toString()));
    }
  }

  // Synchronize dosage guidelines with remote server
  @override
  Future<Either<Failure, int>> syncDosages(int lastTimestamp) async {
    try {
      final remoteDataSource = locator<DrugRemoteDataSource>();
      final Either<Failure, Map<String, dynamic>> result =
          await remoteDataSource.getDeltaSyncDosages(lastTimestamp);

      return await result.fold(
        (Failure failure) => Left<Failure, int>(failure),
        (Map<String, dynamic> data) async {
          final List<dynamic> dosageRaw = (data['data'] as List?) ?? [];
          final List<Map<String, dynamic>> dosageData =
              dosageRaw.cast<Map<String, dynamic>>();

          if (dosageData.isNotEmpty) {
            final db = await localDataSource.dbHelper.database;
            await db.transaction((txn) async {
              final batch = txn.batch();
              for (final dosage in dosageData) {
                batch.insert(
                  'dosage_guidelines',
                  {
                    'id': dosage['id'],
                    'med_id': dosage['med_id'],
                    'min_dose': dosage['min_dose'],
                    'max_dose': dosage['max_dose'],
                    'frequency': dosage['frequency'],
                    'duration': dosage['duration'],
                    'instructions': dosage['instructions'],
                    'condition': dosage['condition'],
                    'source': dosage['source'],
                    'is_pediatric': dosage['is_pediatric'] == true ? 1 : 0,
                    'updated_at': dosage['updated_at'],
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
              await batch.commit(noResult: true);
            });
            return Right<Failure, int>(dosageData.length);
          }
          return const Right<Failure, int>(0);
        },
      );
    } catch (e) {
      return Left<Failure, int>(ServerFailure(message: e.toString()));
    }
  }

  bool _isMatch(String interactionName, DrugEntity drug) {
    final name = interactionName.toLowerCase().trim();

    // 1. Direct Trade Name Match
    if (name == drug.tradeName.toLowerCase().trim()) return true;

    // 2. Active Ingredient Match (Handle multiple ingredients)
    final activeStr = drug.active.toLowerCase().trim();
    if (name == activeStr) return true;

    // Split by common separators: ';', '+', '/'
    final ingredients =
        activeStr.split(RegExp(r'[+;,/]')).map((e) => e.trim()).toList();
    if (ingredients.contains(name)) return true;

    return false;
  }

  @override
  Future<List<String>> getFoodInteractions(int medId) async {
    try {
      return await localDataSource.getFoodInteractionsForDrug(medId);
    } catch (e) {
      debugPrint('Error getting food interactions: $e');
      return [];
    }
  }

  @override
  Future<List<DrugEntity>> getDrugsWithFoodInteractions(int limit) async {
    _logger.d(
      '[InteractionRepo] getDrugsWithFoodInteractions called with limit=$limit',
    );
    try {
      _logger.d(
        '[InteractionRepo] Calling localDataSource.getDrugsWithFoodInteractions...',
      );
      final models = await localDataSource.getDrugsWithFoodInteractions(limit);
      _logger.d(
        '[InteractionRepo] Received ${models.length} models from data source',
      );
      final entities = List<DrugEntity>.from(models);
      _logger.i('[InteractionRepo] Converted to ${entities.length} entities');
      return entities;
    } catch (e, stackTrace) {
      _logger.e(
        '[InteractionRepo] ❌ EXCEPTION in getDrugsWithFoodInteractions',
        e,
        stackTrace,
      );
      return [];
    }
  }
}
