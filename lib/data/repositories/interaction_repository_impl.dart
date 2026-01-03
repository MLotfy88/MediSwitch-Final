import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:mediswitch/core/database/database_helper.dart';
import 'package:mediswitch/core/di/locator.dart';
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/core/services/file_logger_service.dart';
import 'package:mediswitch/data/datasources/local/sqlite_local_data_source.dart';
import 'package:mediswitch/data/datasources/remote/drug_remote_data_source.dart';
import 'package:mediswitch/data/datasources/remote/interaction_remote_data_source.dart';
import 'package:mediswitch/domain/entities/disease_interaction.dart';
import 'package:mediswitch/domain/entities/dosage_guidelines.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/high_risk_ingredient.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Implementation of [InteractionRepository] using SQLite as the local data source.
class InteractionRepositoryImpl implements InteractionRepository {
  final SqliteLocalDataSource localDataSource;
  final InteractionRemoteDataSource remoteDataSource;
  final FileLoggerService _logger;

  /// Creates a new [InteractionRepositoryImpl] instance.
  InteractionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
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
      final results = <DrugInteraction>[];
      final addedIds = <String>{}; // Use a string key for uniqueness

      for (var i = 0; i < medicines.length; i++) {
        final medA = medicines[i];
        if (medA.id == null) continue;

        // Fetch interactions where medA is involved via its ingredients
        final interactionsA = await localDataSource.getInteractionsForDrug(
          medA.id!,
        );

        for (final interaction in interactionsA) {
          // Check against all other medicines
          for (int j = 0; j < medicines.length; j++) {
            if (i == j) continue;
            final medB = medicines[j];

            // A rule (Ing1, Ing2) matches if:
            // (medA has Ing1 AND medB has Ing2) OR (medA has Ing2 AND medB has Ing1)
            final matchA1B2 =
                _isMatch(interaction.ingredient1, medA) &&
                _isMatch(interaction.ingredient2, medB);
            final matchA2B1 =
                _isMatch(interaction.ingredient2, medA) &&
                _isMatch(interaction.ingredient1, medB);

            if (matchA1B2 || matchA2B1) {
              // We found a match!
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

      // 1. Try Local Cache
      var interactions = await localDataSource.getInteractionsForDrug(drug.id!);

      // 2. If empty and has connection, try API (Hybrid Mode)
      if (interactions.isEmpty) {
        _logger.i(
          '[InteractionRepo] No local interactions for ${drug.tradeName}, fetching from API...',
        );
        try {
          final remoteData = await remoteDataSource.getDrugInteractions(
            drug.id!,
          );
          if (remoteData.isNotEmpty) {
            await localDataSource.saveDrugInteractions(remoteData);
            // Re-fetch from local to get proper models
            interactions = await localDataSource.getInteractionsForDrug(
              drug.id!,
            );
          }
        } catch (e) {
          _logger.w('[InteractionRepo] API fetch failed: $e');
        }
      }

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
  Future<List<HighRiskIngredient>> getHighRiskIngredients(int limit) async {
    try {
      final List<Map<String, dynamic>> maps = await localDataSource
          .getHighRiskIngredientsWithMetrics(limit: limit);

      return maps.map((m) {
        _logger.d(
          'Mapping HighRiskIngredient: ${m['name']} - Total: ${m['totalInteractions']}',
        );
        return HighRiskIngredient(
          name: m['name'] as String,
          totalInteractions: m['totalInteractions'] as int,
          severeCount: m['severeCount'] as int,
          moderateCount: m['moderateCount'] as int,
          minorCount: m['minorCount'] as int,
          dangerScore: m['dangerScore'] as int,
          normalizedName: m['normalized_name'] as String?,
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
      int offset = 0;
      const limit = 2000;
      int totalSynced = 0;
      bool hasMore = true;

      while (hasMore) {
        _logger.d(
          '[InteractionRepo] Syncing interactions batch: offset=$offset, limit=$limit',
        );

        final Either<Failure, Map<String, dynamic>> result =
            await remoteDataSource.getDeltaSyncInteractions(
              lastTimestamp,
              limit: limit,
              offset: offset,
            );

        final shouldContinue = await result.fold(
          (failure) async {
            _logger.e('[InteractionRepo] Sync batch failed: $failure');
            return false; // Stop on error
          },
          (data) async {
            final rulesRaw = (data['data'] as List?) ?? [];
            final rulesData = rulesRaw.cast<Map<String, dynamic>>();

            if (rulesData.isEmpty) {
              return false; // No more data
            }

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
                    'arabic_effect': ruleMap['arabic_effect'],
                    'recommendation': ruleMap['recommendation'],
                    'arabic_recommendation': ruleMap['arabic_recommendation'],
                    'source': ruleMap['source'],
                    'type': ruleMap['type'],
                    'updated_at': ruleMap['updated_at'],
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
              await batch.commit(noResult: true);
            });

            totalSynced += rulesData.length;
            offset += limit;

            // If we received fewer items than the limit, we're done
            return rulesData.length >= limit;
          },
        );

        if (!shouldContinue) {
          hasMore = false;
        }
      }
      return Right(totalSynced);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Synchronize medicine-ingredient mapping with remote server
  @override
  Future<Either<Failure, int>> syncMedIngredients(int lastTimestamp) async {
    try {
      final remoteDataSource = locator<DrugRemoteDataSource>();
      int offset = 0;
      const limit = 2000;
      int totalSynced = 0;
      bool hasMore = true;

      while (hasMore) {
        _logger.d(
          '[InteractionRepo] Syncing ingredients batch: offset=$offset, limit=$limit',
        );

        final Either<Failure, Map<String, dynamic>> result =
            await remoteDataSource.getDeltaSyncMedIngredients(
              lastTimestamp,
              limit: limit,
              offset: offset,
            );

        final shouldContinue = await result.fold(
          (failure) async {
            _logger.e(
              '[InteractionRepo] Sync ingredients batch failed: $failure',
            );
            return false;
          },
          (data) async {
            final mappingRaw = (data['data'] as List?) ?? [];
            final mappingData = mappingRaw.cast<Map<String, dynamic>>();

            if (mappingData.isEmpty) {
              return false;
            }

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

            totalSynced += mappingData.length;
            offset += limit;
            return mappingData.length >= limit;
          },
        );

        if (!shouldContinue) {
          hasMore = false;
        }
      }
      return Right(totalSynced);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Synchronize dosage guidelines with remote server
  @override
  Future<Either<Failure, int>> syncDosages(int lastTimestamp) async {
    try {
      final remoteDataSource = locator<DrugRemoteDataSource>();
      final Either<Failure, Map<String, dynamic>> result =
          await remoteDataSource.getDeltaSyncDosages(lastTimestamp);

      return await result.fold((failure) => Left<Failure, int>(failure), (
        data,
      ) async {
        final dosageRaw = (data['data'] as List?) ?? [];
        final dosageData = dosageRaw.cast<Map<String, dynamic>>();

        if (dosageData.isNotEmpty) {
          final db = await localDataSource.dbHelper.database;
          await db.transaction((txn) async {
            final batch = txn.batch();
            for (final dosage in dosageData) {
              batch.insert('dosage_guidelines', {
                'id': dosage['id'],
                'med_id': dosage['med_id'],
                'dailymed_setid': dosage['dailymed_setid'],
                'min_dose': dosage['min_dose'],
                'max_dose': dosage['max_dose'],
                'frequency': dosage['frequency'],
                'duration': dosage['duration'],
                'instructions': dosage['instructions'],
                'condition': dosage['condition'],
                'source': dosage['source'],
                'is_pediatric':
                    (dosage['is_pediatric'] == 1 ||
                            dosage['is_pediatric'] == true)
                        ? 1
                        : 0,
                'updated_at': dosage['updated_at'],
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
            await batch.commit(noResult: true);
          });
          return Right<Failure, int>(dosageData.length);
        }
        return const Right<Failure, int>(0);
      });
    } catch (e) {
      return Left<Failure, int>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> syncFoodInteractions(int lastTimestamp) async {
    try {
      final remoteDataSource = locator<DrugRemoteDataSource>();
      final result = await remoteDataSource.getDeltaSyncFoodInteractions(
        lastTimestamp,
      );

      return await result.fold((failure) => Left(failure), (data) async {
        final raw = (data['data'] as List?) ?? [];
        final items = raw.cast<Map<String, dynamic>>();

        if (items.isNotEmpty) {
          final db = await localDataSource.dbHelper.database;
          await db.transaction((txn) async {
            final batch = txn.batch();
            for (final item in items) {
              batch.insert(
                DatabaseHelper.foodInteractionsTable,
                {
                  'id': item['id'],
                  'med_id': item['med_id'],
                  'trade_name': item['trade_name'],
                  'interaction': item['interaction'],
                  'source': item['source'],
                  'updated_at': item['updated_at'],
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            await batch.commit(noResult: true);
          });
          return Right(items.length);
        }
        return const Right(0);
      });
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> syncDiseaseInteractions(
    int lastTimestamp,
  ) async {
    try {
      final remoteDataSource = locator<DrugRemoteDataSource>();
      final result = await remoteDataSource.getDeltaSyncDiseaseInteractions(
        lastTimestamp,
      );

      return await result.fold((failure) => Left(failure), (data) async {
        final raw = (data['data'] as List?) ?? [];
        final items = raw.cast<Map<String, dynamic>>();

        if (items.isNotEmpty) {
          final db = await localDataSource.dbHelper.database;
          await db.transaction((txn) async {
            final batch = txn.batch();
            for (final item in items) {
              batch.insert(
                DatabaseHelper.diseaseInteractionsTable,
                {
                  'id': item['id'],
                  'med_id': item['med_id'],
                  'disease_name': item['disease_name'],
                  'severity': item['severity'],
                  'interaction': item['interaction'],
                  'source': item['source'],
                  'updated_at': item['updated_at'],
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            await batch.commit(noResult: true);
          });
          return Right(items.length);
        }
        return const Right(0);
      });
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
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
  Future<List<String>> getFoodInteractions(DrugEntity drug) async {
    try {
      final Set<String> allInteractions = {};

      // 1. Check by ID (Local Cache)
      if (drug.id != null) {
        var byId = await localDataSource.getFoodInteractionsForDrug(drug.id!);
        if (byId.isEmpty) {
          // 2. Hybrid API Fetch
          _logger.i(
            '[InteractionRepo] Fetching food interactions from API for ${drug.tradeName}...',
          );
          try {
            final remoteData = await remoteDataSource.getFoodInteractions(
              drug.id!,
            );
            if (remoteData.isNotEmpty) {
              await localDataSource.saveFoodInteractions(remoteData);
              byId = await localDataSource.getFoodInteractionsForDrug(drug.id!);
            }
          } catch (e) {
            _logger.w('[InteractionRepo] Food API fetch failed: $e');
          }
        }
        allInteractions.addAll(byId);
      }

      // 3. Fallback/Molecular Match (Local)
      if (drug.active.isNotEmpty) {
        final byIngredient = await localDataSource
            .getFoodInteractionsForIngredient(drug.active);
        allInteractions.addAll(byIngredient);
      }

      return allInteractions.toList();
    } catch (e) {
      debugPrint('Error getting food interactions: $e');
      return [];
    }
  }

  @override
  Future<List<HighRiskIngredient>> getFoodInteractionIngredients() async {
    try {
      final List<Map<String, dynamic>> maps =
          await localDataSource.getFoodInteractionCounts();

      return maps.map((m) {
        return HighRiskIngredient(
          name: m['name'] as String,
          totalInteractions: m['count'] as int,
          severeCount:
              0, // Food interactions usually don't have severity breakdown here
          moderateCount: 0,
          minorCount: 0,
          dangerScore: 0,
        );
      }).toList();
    } catch (e) {
      _logger.e('Error getting food interaction ingredients: $e');
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

  @override
  Future<int> getRulesCount() async {
    try {
      return await localDataSource.getInteractionsCount();
    } catch (e) {
      _logger.e('Error getting rules count', e);
      return 0;
    }
  }

  @override
  Future<void> incrementVisits(int drugId) async {
    try {
      await localDataSource.incrementVisits(drugId);
    } catch (e) {
      _logger.e('Error incrementing visits for drug $drugId', e);
    }
  }

  @override
  Future<List<DiseaseInteraction>> getDiseaseInteractions(
    DrugEntity drug,
  ) async {
    if (drug.id == null) return [];
    try {
      var interactions = await localDataSource.getDiseaseInteractionsForDrug(
        drug.id!,
      );

      if (interactions.isEmpty) {
        // Hybrid API Fetch
        _logger.i(
          '[InteractionRepo] Fetching disease interactions from API for ${drug.tradeName}...',
        );
        try {
          final remoteData = await remoteDataSource.getDiseaseInteractions(
            drug.id!,
          );
          if (remoteData.isNotEmpty) {
            await localDataSource.saveDiseaseInteractions(remoteData);
            interactions = await localDataSource.getDiseaseInteractionsForDrug(
              drug.id!,
            );
          }
        } catch (e) {
          _logger.w('[InteractionRepo] Disease API fetch failed: $e');
        }
      }

      return interactions;
    } catch (e) {
      _logger.e('Error getting disease interactions: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDetailedFoodInteractions(
    DrugEntity drug,
  ) async {
    if (drug.id == null) return [];
    try {
      return await localDataSource.getFoodInteractionsDetailedForDrug(drug.id!);
    } catch (e) {
      _logger.e('Error getting detailed food interactions: $e');
      return [];
    }
  }
}
