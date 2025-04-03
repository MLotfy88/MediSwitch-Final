import 'dart:async'; // Added for async operations like Future.delayed
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode or logging

import '../../core/error/failures.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/repositories/drug_repository.dart';
import '../datasources/local/csv_local_data_source.dart';
import '../datasources/remote/drug_remote_data_source.dart'; // Keep import for future use
import '../models/medicine_model.dart';
// import '../../core/network/network_info.dart'; // For checking connectivity

// Define specific Failure types (can be moved to failures.dart)
// class CacheFailure extends Failure {} // Defined in core/error/failures.dart
class ServerFailure extends Failure {} // Example for remote source later

class NetworkFailure extends Failure {} // Example for network issues

class DrugRepositoryImpl implements DrugRepository {
  final CsvLocalDataSource localDataSource;
  final DrugRemoteDataSource remoteDataSource; // Inject RemoteDataSource
  // final NetworkInfo networkInfo; // Keep commented for now
  final bool isConnected; // Simple flag for now, replace with NetworkInfo later

  // In-memory cache and indices
  List<DrugEntity>? _cachedDrugs;
  Map<String, List<DrugEntity>> _categoryIndex = {};
  Map<String, List<DrugEntity>> _nameIndex = {}; // Index by first letter

  DrugRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource, // Add remoteDataSource to constructor
    // required this.networkInfo,
    this.isConnected = true, // Default, should be determined by NetworkInfo
  });

  // Removed the factory constructor DrugRepositoryImpl.create()

  // --- Helper: Build Indices ---
  void _buildIndices(List<DrugEntity> drugs) {
    if (kDebugMode) {
      print('Building in-memory indices for ${drugs.length} drugs...');
    }
    _categoryIndex.clear();
    _nameIndex.clear();

    for (final drug in drugs) {
      // Category Index (lowercase key)
      final category = drug.mainCategory.toLowerCase();
      if (category.isNotEmpty) {
        _categoryIndex.putIfAbsent(category, () => []).add(drug);
      }

      // Name Index (first letter lowercase key)
      if (drug.tradeName.isNotEmpty) {
        final firstChar = drug.tradeName[0].toLowerCase();
        _nameIndex.putIfAbsent(firstChar, () => []).add(drug);
      }
      // Optionally index arabicName too, ensuring no duplicates in list
      if (drug.arabicName.isNotEmpty) {
        final firstChar = drug.arabicName[0].toLowerCase();
        final list = _nameIndex.putIfAbsent(firstChar, () => []);
        if (!list.contains(drug)) {
          // Avoid adding same drug twice under same letter
          list.add(drug);
        }
      }
    }
    if (kDebugMode) {
      print(
        'Indices built: ${_categoryIndex.length} categories, ${_nameIndex.length} name prefixes',
      );
    }
  }

  // --- Helper: Clear Cache ---
  void _clearCache() {
    _cachedDrugs = null;
    _categoryIndex.clear();
    _nameIndex.clear();
    if (kDebugMode) {
      print('In-memory cache and indices cleared');
    }
  }

  // --- Helper: Check for Updates ---
  Future<bool> _shouldUpdateData() async {
    if (!isConnected) {
      // Check connectivity first (using simple flag for now)
      if (kDebugMode) print('Not connected, skipping update check.');
      return false;
    }
    try {
      if (kDebugMode) print('Checking for remote data updates...');
      // Fetch remote version (timestamp)
      final remoteVersionResult = await remoteDataSource.getLatestVersion();

      // Fold on the remote result first
      return await remoteVersionResult.fold(
        (failure) {
          if (kDebugMode)
            print('Failed to get remote version: $failure. Not updating.');
          return false; // Don't update if remote check fails
        },
        (remoteVersionInfo) async {
          // Make callback async to await local timestamp
          // Fetch local timestamp *after* successfully getting remote version
          final localTimestamp = await localDataSource.getLastUpdateTimestamp();
          final remoteTimestamp =
              int.tryParse(remoteVersionInfo['version']?.toString() ?? '0') ??
              0;

          if (kDebugMode) {
            print('Remote version timestamp: $remoteTimestamp');
            print('Local version timestamp: $localTimestamp');
          }
          // Update if local data doesn't exist OR remote is newer
          final needsUpdate =
              localTimestamp == null || remoteTimestamp > localTimestamp;
          if (kDebugMode) print('Needs update: $needsUpdate');
          return needsUpdate;
        },
      ); // Close fold
    } catch (e) {
      if (kDebugMode) print('Error during update check: $e. Not updating.');
      return false; // Don't update if any error occurs during check
    }
  }

  // --- Helper: Update Local Data ---
  Future<void> _updateLocalDataFromRemote() async {
    if (!isConnected) {
      if (kDebugMode) print('Not connected, cannot download remote data.');
      // Optionally throw a specific NetworkFailure here if needed upstream
      return; // Or throw NetworkFailure();
    }
    try {
      if (kDebugMode) print('Downloading latest data from remote source...');
      // Download latest data (CSV or XLSX handled by remote source)
      final downloadResult = await remoteDataSource.downloadLatestData();

      // Fold on the download result
      await downloadResult.fold(
        (failure) async {
          if (kDebugMode) print('Failed to download remote data: $failure');
          // Propagate failure - the caller (getAllDrugs) will handle it
          throw failure;
        },
        (fileData) async {
          if (kDebugMode)
            print('Downloaded data successfully. Saving locally...');
          // Save the downloaded data (assuming it's CSV string for now)
          // TODO: Handle different file types if remote source returns them
          await localDataSource.saveDownloadedCsv(fileData);
          _clearCache(); // Clear cache after successful update
          if (kDebugMode) print('Local data updated and cache cleared.');
        },
      );
    } catch (e) {
      if (kDebugMode) print('Error during remote data download/save: $e');
      // Rethrow the error or map to a specific Failure type
      // If it's a Failure from fold, rethrow it. Otherwise, wrap it.
      if (e is Failure) {
        rethrow;
      } else {
        throw ServerFailure(); // Or a more specific download/save failure
      }
    }
  }

  // --- Repository Method Implementations ---

  @override
  Future<Either<Failure, List<DrugEntity>>> getAllDrugs() async {
    // Return cached drugs if available
    if (_cachedDrugs != null && _cachedDrugs!.isNotEmpty) {
      if (kDebugMode) {
        print('Using cached drugs from memory');
      }
      return Right(_cachedDrugs!);
    }

    bool updateFailed = false; // Flag to track if update attempt failed
    // Check for updates if connected
    if (isConnected) {
      try {
        final shouldUpdate = await _shouldUpdateData();
        if (shouldUpdate) {
          await _updateLocalDataFromRemote();
          // Cache was cleared in _updateLocalDataFromRemote,
          // data will be reloaded from local source below.
        }
      } catch (e) {
        updateFailed = true; // Mark update as failed
        if (kDebugMode) {
          print(
            'Update check/download failed: $e. Proceeding with local data.',
          );
        }
        // Don't return failure yet, try local cache first.
      }
    }

    // Get data from local source
    try {
      final List<MedicineModel> localMedicines =
          await localDataSource.getAllMedicines();
      final List<DrugEntity> drugEntities =
          localMedicines.map((model) {
            return DrugEntity(
              tradeName: model.tradeName ?? '',
              arabicName: model.arabicName ?? '',
              price: model.price ?? '',
              mainCategory: model.mainCategory ?? '',
              // Pass additional fields from model to entity
              active: model.active ?? '',
              company: model.company ?? '',
              dosageForm: model.dosageForm ?? '',
              unit: model.unit ?? '',
              usage: model.usage ?? '',
              description: model.description ?? '',
              lastPriceUpdate: model.lastPriceUpdate ?? '',
            );
          }).toList();

      _buildIndices(drugEntities); // Build indices
      _cachedDrugs = drugEntities; // Cache the result

      return Right(drugEntities);
    } catch (e) {
      if (kDebugMode) {
        print('Cache Error in Repository (getAllDrugs): $e');
      }
      // If update also failed, return InitialLoadFailure, otherwise CacheFailure
      if (updateFailed || !isConnected) {
        // Also fail if not connected and cache fails
        return Left(InitialLoadFailure());
      } else {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<DrugEntity>>> searchDrugs(String query) async {
    // Ensure data is loaded and cached first
    final initialResult = await getAllDrugs();
    if (initialResult.isLeft()) {
      return initialResult; // Return failure if initial load failed
    }
    // We know _cachedDrugs is not null here if initialResult is Right
    final List<DrugEntity> drugsToSearch = _cachedDrugs!;

    if (query.isEmpty) {
      return Right(drugsToSearch);
    }

    try {
      final lowerCaseQuery = query.toLowerCase();
      List<DrugEntity> results = [];

      // Basic search without index first for simplicity, can add index later
      results =
          drugsToSearch.where((drug) {
            final tradeNameLower = drug.tradeName.toLowerCase();
            final arabicNameLower = drug.arabicName.toLowerCase();
            return tradeNameLower.contains(lowerCaseQuery) ||
                arabicNameLower.contains(lowerCaseQuery);
          }).toList();

      if (kDebugMode) {
        print('Search for "$query" found ${results.length} results');
      }
      return Right(results);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching drugs: $e');
      }
      return Left(CacheFailure()); // Or a more specific search failure
    }
  }

  @override
  Future<Either<Failure, List<DrugEntity>>> filterDrugsByCategory(
    String category,
  ) async {
    // Ensure data is loaded and cached first
    final initialResult = await getAllDrugs();
    if (initialResult.isLeft()) {
      return initialResult; // Return failure if initial load failed
    }
    final List<DrugEntity> drugsToFilter = _cachedDrugs!;

    if (category.isEmpty) {
      return Right(drugsToFilter);
    }

    try {
      final lowerCaseCategory = category.toLowerCase();
      List<DrugEntity> results = [];

      // Use category index if available and populated
      if (_categoryIndex.containsKey(lowerCaseCategory)) {
        results = _categoryIndex[lowerCaseCategory] ?? [];
      }
      // Optional: Fallback to linear search if index is empty for the key?
      // else {
      //    results = drugsToFilter.where((drug) {
      //      final mainCatLower = drug.mainCategory.toLowerCase();
      //      return mainCatLower == lowerCaseCategory;
      //    }).toList();
      // }

      if (kDebugMode) {
        print('Filter by category "$category" found ${results.length} results');
      }
      return Right(results);
    } catch (e) {
      if (kDebugMode) {
        print('Error filtering drugs by category: $e');
      }
      return Left(CacheFailure()); // Or a more specific filter failure
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableCategories() async {
    // Ensure data is loaded and indices are built first
    final initialResult = await getAllDrugs();
    if (initialResult.isLeft()) {
      // If initial load fails, return a specific failure for categories
      return Left(CacheFailure());
    }

    try {
      // Get unique categories from the index keys
      final categories =
          _categoryIndex.keys.map((cat) {
            if (cat.isNotEmpty) {
              return cat[0].toUpperCase() + cat.substring(1);
            }
            return cat;
          }).toList();
      categories.sort();

      if (kDebugMode) {
        print('Found ${categories.length} available categories from index');
      }
      return Right(categories);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available categories: $e');
      }
      return Left(CacheFailure());
    }
  }

  // Implementation for Step 2
  @override
  Future<Either<Failure, int?>> getLastUpdateTimestamp() async {
    try {
      final timestamp = await localDataSource.getLastUpdateTimestamp();
      return Right(timestamp);
    } catch (e) {
      // If localDataSource throws an error (e.g., SharedPreferences error)
      if (kDebugMode) {
        print('Error getting last update timestamp from local source: $e');
      }
      return Left(
        CacheFailure(),
      ); // Return CacheFailure for local storage issues
    }
  }
}
