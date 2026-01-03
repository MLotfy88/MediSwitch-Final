import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart'; // For compute
import 'package:mediswitch/core/database/database_helper.dart';
import 'package:mediswitch/core/di/locator.dart'; // Import locator
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/core/services/file_logger_service.dart';
import 'package:mediswitch/data/datasources/local/sqlite_local_data_source.dart';
import 'package:mediswitch/data/datasources/remote/drug_remote_data_source.dart';
import 'package:mediswitch/data/models/medicine_model.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/repositories/drug_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

// import '../../core/network/network_info.dart';

class DrugRepositoryImpl implements DrugRepository {
  /// Constructor for DrugRepositoryImpl
  DrugRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    // required this.networkInfo,
    this.isConnected = true, // Default, should be determined by NetworkInfo
  });

  final SqliteLocalDataSource localDataSource; // Changed type to SQLite
  final DrugRemoteDataSource remoteDataSource;
  // final NetworkInfo networkInfo;
  final bool isConnected; // Simple flag for now
  final FileLoggerService _logger =
      locator<FileLoggerService>(); // Get logger instance

  // Removed in-memory cache and indices

  // Removed _buildIndices and _clearCache methods

  // --- Repository Method Implementations ---

  @override
  Future<Either<Failure, List<DrugEntity>>> getAllDrugs() async {
    _logger.i("DrugRepository: getAllDrugs called (Update Check Trigger)");

    // --- Update Check Logic (DISABLED by user request for performance) ---
    _logger.i(
      "DrugRepository: Manual sync requested? Currently handled via UnifiedSyncService.",
    );
    // --- End of Update Check Logic ---

    // Fetch all drugs from local storage regardless of update status
    try {
      _logger.i("DrugRepository: Fetching all drugs from local data source...");
      final List<MedicineModel> localMedicines =
          await localDataSource.getAllMedicines();
      final List<DrugEntity> drugEntities =
          localMedicines.map((model) => model.toEntity()).toList();
      _logger.i(
        "DrugRepository: Successfully fetched ${drugEntities.length} drugs from local source.",
      );
      return Right(drugEntities);
    } catch (e, s) {
      _logger.e('Error fetching all drugs from local source', e, s);
      return Left(CacheFailure()); // Return CacheFailure if local fetch fails
    }
  }

  @override
  // Add limit and offset parameters
  Future<Either<Failure, List<DrugEntity>>> searchDrugs(
    String query, {
    int? limit,
    int? offset,
  }) async {
    _logger.d(
      "DrugRepository: searchDrugs called with query: '$query', limit: $limit, offset: $offset",
    );
    try {
      // Pass limit and offset to the data source method
      final List<MedicineModel> localMedicines = await localDataSource
          .searchMedicinesByName(query, limit: limit, offset: offset);
      final List<DrugEntity> drugEntities =
          localMedicines.map((model) => model.toEntity()).toList();
      _logger.i(
        "DrugRepository: searchDrugs successful, found ${drugEntities.length} drugs.",
      );
      return Right(drugEntities);
    } catch (e, s) {
      // Add stack trace
      _logger.e('Error searching drugs in repository', e, s); // Use logger
      return Left(CacheFailure());
    }
  }

  @override
  // Add limit and offset parameters
  Future<Either<Failure, List<DrugEntity>>> filterDrugsByCategory(
    String category, {
    int? limit,
    int? offset,
  }) async {
    _logger.d(
      "DrugRepository: filterDrugsByCategory called with category: '$category', limit: $limit, offset: $offset",
    );
    try {
      // Pass limit and offset to the data source method
      final List<MedicineModel> localMedicines = await localDataSource
          .filterMedicinesByCategory(category, limit: limit, offset: offset);
      final List<DrugEntity> drugEntities =
          localMedicines.map((model) => model.toEntity()).toList();
      _logger.i(
        "DrugRepository: filterDrugsByCategory successful, found ${drugEntities.length} drugs.",
      );
      return Right(drugEntities);
    } catch (e, s) {
      // Add stack trace
      _logger.e(
        'Error filtering drugs by category in repository',
        e,
        s,
      ); // Use logger
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableCategories() async {
    _logger.d("DrugRepository: getAvailableCategories called.");
    try {
      final List<String> categories =
          await localDataSource.getAvailableCategories();
      final formattedCategories =
          categories.map((cat) {
            if (cat.isNotEmpty) return cat[0].toUpperCase() + cat.substring(1);
            return cat;
          }).toList();
      _logger.i(
        "DrugRepository: getAvailableCategories successful, found ${formattedCategories.length} categories.",
      );
      return Right(formattedCategories);
    } catch (e, s) {
      // Add stack trace
      _logger.e(
        'Error getting available categories in repository',
        e,
        s,
      ); // Use logger
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getCategoriesWithCounts() async {
    _logger.d("DrugRepository: getCategoriesWithCounts called.");
    try {
      final Map<String, int> categories =
          await localDataSource.getCategoriesWithCount();
      _logger.i(
        "DrugRepository: getCategoriesWithCounts successful, found ${categories.length} categories.",
      );
      return Right(categories);
    } catch (e, s) {
      _logger.e(
        'Error getting available categories with counts in repository',
        e,
        s,
      );
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, int>> getLastUpdateTimestamp() async {
    _logger.d("DrugRepository: getLastUpdateTimestamp called.");
    try {
      final timestamp = await localDataSource.getLastUpdateTimestamp();
      _logger.i(
        "DrugRepository: getLastUpdateTimestamp successful, timestamp: $timestamp",
      );
      return Right(timestamp ?? 0); // Return 0 if null
    } catch (e, s) {
      _logger.e('Error getting last update timestamp from local source', e, s);
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, int>> getDeltaSyncDrugs(int lastTimestamp) async {
    _logger.d(
      "DrugRepository: getDeltaSyncDrugs called with lastTimestamp: $lastTimestamp",
    );
    if (!isConnected) {
      _logger.w('DrugRepository: Not connected, cannot get delta sync.');
      return Left(NetworkFailure());
    }

    try {
      int offset = 0;
      const limit = 2000;
      int totalSynced = 0;
      bool hasMore = true;

      while (hasMore) {
        _logger.d(
          "DrugRepository: Syncing drugs batch: offset=$offset, limit=$limit",
        );

        final result = await remoteDataSource.getDeltaSyncDrugs(
          lastTimestamp,
          limit: limit,
          offset: offset,
        );

        final shouldContinue = await result.fold(
          (failure) async {
            _logger.w('DrugRepository: Delta sync batch failed - $failure');
            return false; // Stop on error
          },
          (data) async {
            final List<Map<String, dynamic>> drugsData =
                ((data['data'] ?? data['drugs'] ?? []) as List)
                    .cast<Map<String, dynamic>>();
            final int count = drugsData.length;
            _logger.i(
              "DrugRepository: Sync batch received, found $count items",
            );

            if (drugsData.isNotEmpty) {
              // Use compute for heavy mapping
              final List<MedicineModel> models = await compute(
                _parseSyncDrugs,
                drugsData,
              );

              if (models.isNotEmpty) {
                final db = await localDataSource.dbHelper.database;
                await db.transaction((txn) async {
                  final batch = txn.batch();
                  for (final model in models) {
                    batch.insert(
                      DatabaseHelper.medicinesTable,
                      model.toMap(),
                      conflictAlgorithm: ConflictAlgorithm.replace,
                    );

                    // Populate ingredients for interactions
                    if (model.id != null && model.active.isNotEmpty) {
                      final parts = model.active.split(RegExp(r'[+/,]'));
                      for (final p in parts) {
                        final ing = p.trim().toLowerCase();
                        if (ing.isNotEmpty) {
                          batch.insert(
                            'med_ingredients',
                            {'med_id': model.id, 'ingredient': ing},
                            conflictAlgorithm: ConflictAlgorithm.replace,
                          );
                        }
                      }
                    }
                  }
                  await batch.commit(noResult: true);
                });
                _logger.i(
                  "DrugRepository: Updated ${models.length} drugs in DB (Batch)",
                );
              }
            }

            // Update local timestamp (update on every successful batch or just once?
            // Better to update purely at the end, but getting partial data is better than none.
            // For now, only update if successful batch)
            final newTimestamp = data['currentTimestamp'] as int?;
            if (newTimestamp != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('drugs_last_sync_timestamp', newTimestamp);
            }

            totalSynced += count;
            offset += limit;
            return count >= limit;
          },
        );

        if (!shouldContinue) {
          hasMore = false;
        }
      }

      return Right(totalSynced);
    } catch (e, s) {
      _logger.e('DrugRepository: Error during delta sync', e, s);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Top-level function for compute
  static List<MedicineModel> _parseSyncDrugs(List<Map<String, dynamic>> data) {
    return data.map((json) => MedicineModel.fromSyncJson(json)).toList();
  }

  @override
  Future<Either<Failure, List<DrugEntity>>> getRecentlyUpdatedDrugs({
    required String cutoffDate,
    required int limit,
    int? offset,
  }) async {
    _logger.d(
      "DrugRepository: getRecentlyUpdatedDrugs called with cutoffDate: '$cutoffDate', limit: $limit, offset: $offset",
    );
    try {
      final List<MedicineModel> localMedicines = await localDataSource
          .getRecentlyUpdatedMedicines(
            cutoffDate,
            limit: limit,
            offset: offset,
          ); // Corrected call
      final List<DrugEntity> drugEntities =
          localMedicines.map((model) => model.toEntity()).toList();
      _logger.i(
        "DrugRepository: getRecentlyUpdatedDrugs successful, found ${drugEntities.length} drugs.",
      );
      return Right(drugEntities);
    } catch (e, s) {
      _logger.e('Error getting recently updated drugs in repository', e, s);
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<DrugEntity>>> getPopularDrugs({
    required int limit,
  }) async {
    _logger.d(
      "DrugRepository: getPopularDrugs called with limit: $limit (using random)",
    );
    try {
      final List<MedicineModel> localMedicines = await localDataSource
          .getRandomMedicines(limit: limit);
      final List<DrugEntity> drugEntities =
          localMedicines.map((model) => model.toEntity()).toList();
      _logger.i(
        "DrugRepository: getPopularDrugs successful, found ${drugEntities.length} random drugs.",
      );
      return Right(drugEntities);
    } catch (e, s) {
      _logger.e('Error getting popular (random) drugs in repository', e, s);
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<DrugEntity>>> findSimilars(
    DrugEntity drug,
  ) async {
    _logger.d(
      "DrugRepository: findSimilars called for drug: '${drug.tradeName}' with active: '${drug.active}'",
    );
    try {
      final List<MedicineModel> localMedicines = await localDataSource
          .findSimilars(drug.active, drug.tradeName);
      final List<DrugEntity> drugEntities =
          localMedicines.map((model) => model.toEntity()).toList();
      _logger.i(
        "DrugRepository: findSimilars successful, found ${drugEntities.length} drugs.",
      );
      return Right(drugEntities);
    } catch (e, s) {
      _logger.e('Error finding similar drugs in repository', e, s);
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<DrugEntity>>> findAlternatives(
    DrugEntity drug,
  ) async {
    _logger.d(
      "DrugRepository: findAlternatives called for drug: '${drug.tradeName}' with category: '${drug.category}' and active: '${drug.active}'",
    );
    // Use the 'category' field from the DrugEntity, which might be null
    final categoryToSearch = drug.category;

    if (categoryToSearch == null || categoryToSearch.isEmpty) {
      _logger.w(
        "DrugRepository: Cannot find alternatives for '${drug.tradeName}' because its category is null or empty.",
      );
      return const Right([]); // Return empty list if category is missing
    }

    try {
      final List<MedicineModel> localMedicines = await localDataSource
          .findAlternatives(categoryToSearch, drug.active);
      final List<DrugEntity> drugEntities =
          localMedicines.map((model) => model.toEntity()).toList();
      _logger.i(
        "DrugRepository: findAlternatives successful, found ${drugEntities.length} drugs.",
      );
      return Right(drugEntities);
    } catch (e, s) {
      _logger.e('Error finding alternative drugs in repository', e, s);
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<int>>> getNewestDrugIds(int limit) async {
    _logger.d("DrugRepository: getNewestDrugIds called with limit: $limit");
    try {
      final ids = await localDataSource.getNewestDrugIds(limit);
      _logger.i(
        "DrugRepository: getNewestDrugIds successful, found ${ids.length} IDs.",
      );
      return Right(ids);
    } catch (e, s) {
      _logger.e('Error getting newest drug IDs in repository', e, s);
      return Left(CacheFailure());
    }
  }
}
