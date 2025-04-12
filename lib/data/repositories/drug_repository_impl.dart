import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/repositories/drug_repository.dart';
import '../datasources/local/sqlite_local_data_source.dart'; // Use SQLite
import '../datasources/remote/drug_remote_data_source.dart';
import '../models/medicine_model.dart'; // Import MedicineModel for conversion
// import '../../core/network/network_info.dart';

// Define specific Failure types
class ServerFailure extends Failure {}

class NetworkFailure extends Failure {}

class DrugRepositoryImpl implements DrugRepository {
  final SqliteLocalDataSource localDataSource; // Changed type to SQLite
  final DrugRemoteDataSource remoteDataSource;
  // final NetworkInfo networkInfo;
  final bool isConnected; // Simple flag for now

  // Removed in-memory cache and indices

  DrugRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    // required this.networkInfo,
    this.isConnected = true, // Default, should be determined by NetworkInfo
  });

  // Removed _buildIndices and _clearCache methods

  // --- Helper: Check for Updates ---
  Future<bool> _shouldUpdateData() async {
    if (!isConnected) {
      if (kDebugMode) print('Not connected, skipping update check.');
      return false;
    }
    final stopwatch = Stopwatch()..start(); // Start timer
    try {
      if (kDebugMode) print('Checking for remote data updates...');
      final remoteVersionResult = await remoteDataSource.getLatestVersion();

      return await remoteVersionResult.fold(
        (failure) {
          if (kDebugMode)
            print('Failed to get remote version: $failure. Not updating.');
          return false;
        },
        (remoteVersionInfo) async {
          final localTimestamp = await localDataSource.getLastUpdateTimestamp();
          final remoteTimestamp =
              int.tryParse(remoteVersionInfo['version']?.toString() ?? '0') ??
              0;

          if (kDebugMode) {
            print('Remote version timestamp: $remoteTimestamp');
            print('Local version timestamp: $localTimestamp');
          }
          final needsUpdate =
              localTimestamp == null || remoteTimestamp > localTimestamp;
          if (kDebugMode) print('Needs update: $needsUpdate');
          return needsUpdate;
        },
      );
    } catch (e) {
      if (kDebugMode) print('Error during update check: $e. Not updating.');
      return false;
    } finally {
      stopwatch.stop();
      if (kDebugMode)
        print('Update check took ${stopwatch.elapsedMilliseconds}ms.');
    }
  }

  // --- Helper: Update Local Data ---
  Future<void> _updateLocalDataFromRemote() async {
    if (!isConnected) {
      if (kDebugMode) print('Not connected, cannot download remote data.');
      throw NetworkFailure(); // Throw specific failure
    }
    final stopwatch = Stopwatch()..start(); // Start timer
    try {
      if (kDebugMode) print('Downloading latest data from remote source...');
      final downloadResult = await remoteDataSource.downloadLatestData();

      await downloadResult.fold(
        (failure) async {
          if (kDebugMode) print('Failed to download remote data: $failure');
          throw failure; // Propagate failure
        },
        (fileData) async {
          if (kDebugMode)
            print('Downloaded data successfully. Saving locally...');
          await localDataSource.saveDownloadedCsv(
            fileData,
          ); // This now clears DB and inserts
          // No need to clear cache here anymore
          if (kDebugMode) print('Local data updated via SQLite.');
        },
      );
    } catch (e) {
      if (kDebugMode) print('Error during remote data download/save: $e');
      if (e is Failure) {
        rethrow;
      } else {
        throw ServerFailure();
      }
    } finally {
      stopwatch.stop();
      if (kDebugMode)
        print(
          'Remote data download/save took ${stopwatch.elapsedMilliseconds}ms.',
        );
    }
  }

  // --- Repository Method Implementations ---

  @override
  Future<Either<Failure, List<DrugEntity>>> getAllDrugs() async {
    // This method NO LONGER returns all drugs.
    // Its primary responsibility is now to check and perform updates if needed.
    // The actual fetching of data will happen via search/filter methods.
    bool updateAttempted = false;
    bool updateFailed = false;

    if (isConnected) {
      try {
        updateAttempted = true;
        final shouldUpdate = await _shouldUpdateData();
        if (shouldUpdate) {
          await _updateLocalDataFromRemote();
          // Data is updated in DB, but we don't load it all here.
        }
      } catch (e) {
        updateFailed = true;
        if (kDebugMode)
          print('Update check/download failed in getAllDrugs: $e.');
        // If update fails, we might still want to proceed if local data exists.
        // Return the specific failure from the update process.
        if (e is Failure) return Left(e);
        return Left(
          InitialLoadFailure(),
        ); // General failure if update fails badly
      }
    }

    // If update wasn't attempted or failed, we still return success,
    // assuming local DB exists (or will be seeded).
    // The UI will then call search/filter methods to get actual data.
    // If the DB is empty and seeding failed, subsequent calls will return empty lists.
    if (updateFailed) {
      print(
        "Update failed, but proceeding. Subsequent fetches will use local DB.",
      );
    } else if (!updateAttempted) {
      print(
        "Offline or update check skipped. Subsequent fetches will use local DB.",
      );
    } else {
      print(
        "Update check complete (or update performed). Subsequent fetches will use local DB.",
      );
    }
    // Return an empty list or a success indicator. Let's return empty list for now.
    return const Right([]);
    // IMPORTANT: MedicineProvider needs to be adjusted to handle this empty list
    // and call search/filter methods to populate the initial view if needed.
  }

  @override
  // Add optional limit parameter
  Future<Either<Failure, List<DrugEntity>>> searchDrugs(
    String query, {
    int? limit,
  }) async {
    try {
      // Directly query the local data source (SQLite)
      // Pass the limit to the data source method
      final List<MedicineModel> localMedicines = await localDataSource
          .searchMedicinesByName(query, limit: limit);
      // Use the toEntity method from MedicineModel
      final List<DrugEntity> drugEntities =
          localMedicines.map((model) => model.toEntity()).toList();
      return Right(drugEntities);
    } catch (e) {
      if (kDebugMode) print('Error searching drugs in repository: $e');
      return Left(
        CacheFailure(),
      ); // Indicate failure to retrieve from local source
    }
  }

  @override
  Future<Either<Failure, List<DrugEntity>>> filterDrugsByCategory(
    String category,
  ) async {
    try {
      // Directly query the local data source (SQLite)
      final List<MedicineModel> localMedicines = await localDataSource
          .filterMedicinesByCategory(category);
      // Use the toEntity method from MedicineModel
      final List<DrugEntity> drugEntities =
          localMedicines.map((model) => model.toEntity()).toList();
      return Right(drugEntities);
    } catch (e) {
      if (kDebugMode)
        print('Error filtering drugs by category in repository: $e');
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableCategories() async {
    try {
      // Directly query the local data source (SQLite)
      final List<String> categories =
          await localDataSource.getAvailableCategories();
      // Capitalize first letter for display consistency
      final formattedCategories =
          categories.map((cat) {
            if (cat.isNotEmpty) return cat[0].toUpperCase() + cat.substring(1);
            return cat;
          }).toList();
      return Right(formattedCategories);
    } catch (e) {
      if (kDebugMode)
        print('Error getting available categories in repository: $e');
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, int?>> getLastUpdateTimestamp() async {
    try {
      final timestamp = await localDataSource.getLastUpdateTimestamp();
      return Right(timestamp);
    } catch (e) {
      if (kDebugMode)
        print('Error getting last update timestamp from local source: $e');
      return Left(CacheFailure());
    }
  }
}

// Removed the helper extension method as it's now part of MedicineModel
