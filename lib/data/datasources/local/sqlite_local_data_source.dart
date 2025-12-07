import 'dart:async';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart'; // Import sqflite

import '../../../core/database/database_helper.dart'; // Import DatabaseHelper
import '../../models/medicine_model.dart';

// --- Constants ---
const String _prefsKeyLastUpdate = 'csv_last_update_timestamp';

// --- Top-level Functions for Isolate ---
// Keep for update logic
List<MedicineModel> _parseCsvData(String rawCsv) {
  final List<List<dynamic>> csvTable = const CsvToListConverter(
    fieldDelimiter: ',',
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(rawCsv);

  if (csvTable.isNotEmpty) {
    csvTable.removeAt(0); // Remove header row
  }

  final medicines =
      csvTable.map((row) {
        return MedicineModel.fromCsv(row);
      }).toList();
  return medicines;
}

// Keep for update logic (still uses isolate)
Future<String?> _updateDatabaseIsolate(Map<String, dynamic> args) async {
  final String dbPath = args['dbPath'] as String;
  final String rawCsv = args['rawCsv'] as String;
  Database? db;

  try {
    final List<MedicineModel> medicines = _parseCsvData(rawCsv);
    db = await openDatabase(dbPath);
    await db.delete(DatabaseHelper.medicinesTable);
    final batch = db.batch();
    for (final medicine in medicines) {
      batch.insert(
        DatabaseHelper.medicinesTable,
        medicine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    return null;
  } catch (e, s) {
    print('!!! ERROR INSIDE _updateDatabaseIsolate !!!');
    print('Error: $e');
    print('Stacktrace: $s');
    return 'Isolate Update Error: $e \nStacktrace: $s';
  } finally {
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}

// --- SqliteLocalDataSource Class ---
class SqliteLocalDataSource {
  final DatabaseHelper dbHelper;
  final Completer<void> _seedingCompleter = Completer<void>();
  // Remove _isSeeding flag, state will be managed externally or by calling context
  // bool _isSeeding = false;

  // Keep the completer to signal when seeding (if performed) is done.
  Future<void> get seedingComplete => _seedingCompleter.future;
  // Add getter to check if the completer is done
  bool get isSeedingCompleted => _seedingCompleter.isCompleted;
  // Remove isSeeding getter
  // bool get isSeeding => _isSeeding;

  // Constructor no longer automatically triggers seeding
  SqliteLocalDataSource({required this.dbHelper});

  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // --- Core Logic ---

  Future<int?> getLastUpdateTimestamp() async {
    await seedingComplete;
    final prefs = await _prefs;
    return prefs.getInt(_prefsKeyLastUpdate);
  }

  // Performs initial seeding from the asset file. Called by SetupScreen.
  // Returns true if seeding was attempted and completed successfully, false otherwise.
  Future<bool> performInitialSeeding() async {
    if (_seedingCompleter.isCompleted) {
      print(
        'performInitialSeeding called, but completer is already completed. Skipping.',
      );
      return false; // Seeding was not performed now
    }

    print('Performing initial database seeding from asset...');
    Database? db;
    bool seedingPerformedSuccessfully = false; // Track success specifically
    try {
      db = await dbHelper.database; // Ensure DB is initialized first

      // --- Seeding Logic (No count check) ---
      print(
        'Seeding database from asset ON MAIN THREAD (unconditional attempt)...',
      );
      final stopwatch = Stopwatch()..start();

      print('[Main Thread] Loading raw CSV asset...');
      final rawCsv = await rootBundle.loadString('assets/meds.csv');
      print('[Main Thread] Raw CSV loaded.');

      print('[Main Thread] Parsing CSV...');
      final List<MedicineModel> medicines = _parseCsvData(rawCsv);
      print('[Main Thread] Parsed ${medicines.length} medicines.');

      if (medicines.isEmpty) {
        print(
          '[Main Thread] WARNING: Parsed medicine list is empty. Check CSV.',
        );
        // Still complete normally, but log warning. Might need error handling?
      } else {
        print('[Main Thread] Starting batch insert...');
        final batch = db.batch();
        for (final medicine in medicines) {
          batch.insert(
            DatabaseHelper.medicinesTable,
            medicine.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        print('[Main Thread] Batch insert completed.');
      }

      final prefs = await _prefs;
      await prefs.setInt(
        _prefsKeyLastUpdate,
        DateTime.now().millisecondsSinceEpoch,
      );
      stopwatch.stop();
      print(
        'Database seeding attempt finished ON MAIN THREAD in ${stopwatch.elapsedMilliseconds}ms.',
      );
      seedingPerformedSuccessfully = true; // Mark as successful
      // --- End Seeding Logic ---

      if (!_seedingCompleter.isCompleted) {
        _seedingCompleter.complete(); // Complete on success
      }
    } catch (e, s) {
      print('Error during MAIN THREAD seeding process: $e');
      print(s);
      seedingPerformedSuccessfully = false; // Mark as failed
      if (!_seedingCompleter.isCompleted) {
        _seedingCompleter.completeError(e, s); // Complete with error
      }
      // We don't rethrow here, SetupScreen will handle based on return value
    } finally {
      // Ensure completer is completed if something unexpected happened before completion
      if (!_seedingCompleter.isCompleted) {
        print(
          'Completing seeding completer in finally block (unexpected state).',
        );
        _seedingCompleter.complete(); // Complete normally as a fallback
      }
      print('performInitialSeeding finished.');
    }
    return seedingPerformedSuccessfully; // Return success status
  }

  // Method to manually complete the seeder if seeding is known to be done elsewhere
  // or not needed (e.g., subsequent app launches)
  void markSeedingAsComplete() {
    if (!_seedingCompleter.isCompleted) {
      print('Manually marking seeding as complete.');
      _seedingCompleter.complete();
    }
  }

  Future<void> saveDownloadedCsv(String csvData) async {
    await seedingComplete; // Ensure initial seeding isn't running concurrently
    try {
      print(
        'Parsing downloaded CSV data for database update (using isolate)...',
      );
      final db = await dbHelper.database; // Get DB instance for path

      print(
        '[Main Thread] Starting database update in isolate (parsing + insert)...',
      );
      final String? isolateResult = await compute(_updateDatabaseIsolate, {
        'dbPath': db.path,
        'rawCsv': csvData,
      });

      if (isolateResult != null) {
        print(
          '!!! ERROR RETURNED FROM _updateDatabaseIsolate (logged from main thread) !!!',
        );
        print(isolateResult);
        throw Exception('Update isolate failed: $isolateResult');
      } else {
        print('[Main Thread] Isolate update completed successfully.');
        final prefs = await _prefs;
        await prefs.setInt(
          _prefsKeyLastUpdate,
          DateTime.now().millisecondsSinceEpoch,
        );
        print(
          'Database updated successfully from downloaded CSV (via isolate).',
        );
      }
    } catch (e, s) {
      print('Error during downloaded CSV update process: $e');
      print(s);
      rethrow;
    }
  }

  // --- Public API Methods (Using SQLite) ---

  Future<List<MedicineModel>> getAllMedicines() async {
    await seedingComplete; // Wait for seeding
    print("Fetching all medicines from SQLite...");
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
    );
    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  Future<List<MedicineModel>> searchMedicinesByName(
    String query, {
    int? limit,
    int? offset,
  }) async {
    await seedingComplete; // Wait for seeding
    print(
      "Searching medicines in SQLite for query: '$query', limit: $limit, offset: $offset",
    );

    final db = await dbHelper.database;
    final lowerCaseQuery = '%${query.toLowerCase()}%';

    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (query.isNotEmpty) {
      whereClause = '''
         LOWER(${DatabaseHelper.colTradeName}) LIKE ? OR
         LOWER(${DatabaseHelper.colArabicName}) LIKE ? OR
         LOWER(${DatabaseHelper.colActive}) LIKE ?
       ''';
      whereArgs = [lowerCaseQuery, lowerCaseQuery, lowerCaseQuery];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy:
          '${DatabaseHelper.colLastPriceUpdate} DESC', // Order by newest first
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  Future<List<MedicineModel>> filterMedicinesByCategory(
    String category, {
    int? limit,
    int? offset,
  }) async {
    await seedingComplete; // Wait for seeding
    print(
      "Filtering medicines in SQLite by category: '$category', limit: $limit, offset: $offset",
    );
    if (category.isEmpty) {
      return searchMedicinesByName('', limit: limit, offset: offset);
    }

    final db = await dbHelper.database;
    final lowerCaseCategory = category.toLowerCase();

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: 'LOWER(${DatabaseHelper.colMainCategory}) = ?',
      whereArgs: [lowerCaseCategory],
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  Future<List<String>> getAvailableCategories() async {
    await seedingComplete; // Wait for seeding
    print("Fetching distinct categories from SQLite...");
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      distinct: true,
      columns: [DatabaseHelper.colMainCategory],
    );

    List<String> categories =
        maps
            .map((map) => map[DatabaseHelper.colMainCategory]?.toString() ?? '')
            .where((cat) => cat.isNotEmpty)
            .toList();
    categories.sort();
    return categories;
  }

  /// Get categories with their drug counts
  Future<Map<String, int>> getCategoriesWithCount() async {
    await seedingComplete; // Wait for seeding
    print("Fetching categories with counts from SQLite...");
    final db = await dbHelper.database;

    // Use SQL GROUP BY to get counts
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT ${DatabaseHelper.colMainCategory} as category, COUNT(*) as count
      FROM ${DatabaseHelper.medicinesTable}
      WHERE ${DatabaseHelper.colMainCategory} IS NOT NULL 
        AND ${DatabaseHelper.colMainCategory} != ''
      GROUP BY ${DatabaseHelper.colMainCategory}
      ORDER BY count DESC
    ''');

    final Map<String, int> categoryCounts = {};
    for (final row in results) {
      final category = row['category']?.toString() ?? '';
      final count = row['count'] as int? ?? 0;
      if (category.isNotEmpty) {
        categoryCounts[category] = count;
      }
    }

    print("Found ${categoryCounts.length} categories with counts.");
    return categoryCounts;
  }

  Future<List<MedicineModel>> getRecentlyUpdatedMedicines(
    String cutoffDate, {
    required int limit,
  }) async {
    await seedingComplete; // Wait for seeding
    print(
      "Fetching recently updated medicines from SQLite (since $cutoffDate, limit: $limit)...",
    );
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: '${DatabaseHelper.colLastPriceUpdate} >= ?',
      whereArgs: [cutoffDate],
      orderBy:
          '${DatabaseHelper.colLastPriceUpdate} DESC', // Optional: Order by most recent
      limit: limit,
    );
    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  Future<List<MedicineModel>> getRandomMedicines({required int limit}) async {
    await seedingComplete; // Wait for seeding
    print("Fetching $limit random medicines from SQLite...");
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      orderBy: 'RANDOM()', // SQLite specific function for random order
      limit: limit,
    );
    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  /// Checks if the medicines table has any data.
  Future<bool> hasMedicines() async {
    // No need to wait for seedingComplete here, as this check might be used
    // precisely to determine if seeding *needs* to happen.
    // We just need the database to be open.
    try {
      final db = await dbHelper.database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.medicinesTable}',
        ),
      );
      print("Checking if database has medicines. Count: $count");
      return count != null && count > 0;
    } catch (e, s) {
      print("Error checking medicine count: $e\n$s");
      // Assume no medicines if there's an error reading the count
      return false;
    }
  }

  // --- Find Similars (Same Active Ingredient, Different Trade Name) ---
  Future<List<MedicineModel>> findSimilars(
    String activeIngredient,
    String currentTradeName,
  ) async {
    await seedingComplete; // Wait for seeding
    print(
      "Finding similars in SQLite for active: '$activeIngredient', excluding: '$currentTradeName'",
    );
    final db = await dbHelper.database;
    final lowerCaseActive = activeIngredient.toLowerCase();
    final lowerCaseTradeName = currentTradeName.toLowerCase();

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where:
          'LOWER(${DatabaseHelper.colActive}) = ? AND LOWER(${DatabaseHelper.colTradeName}) != ?',
      whereArgs: [lowerCaseActive, lowerCaseTradeName],
      // Optional: Add limit if needed
    );

    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  // --- Find Alternatives (Same Category, Different Active Ingredient) ---
  Future<List<MedicineModel>> findAlternatives(
    String? category, // Category can be null
    String activeIngredient,
  ) async {
    await seedingComplete; // Wait for seeding
    print(
      "Finding alternatives in SQLite for category: '$category', excluding active: '$activeIngredient'",
    );

    // If category is null or empty, cannot find alternatives based on category
    if (category == null || category.isEmpty) {
      print("Cannot find alternatives: Category is null or empty.");
      return [];
    }

    final db = await dbHelper.database;
    final lowerCaseCategory = category.toLowerCase();
    final lowerCaseActive = activeIngredient.toLowerCase();

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where:
          'LOWER(${DatabaseHelper.colCategory}) = ? AND LOWER(${DatabaseHelper.colActive}) != ?',
      whereArgs: [lowerCaseCategory, lowerCaseActive],
      // Optional: Add limit if needed
    );

    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  // --- Find Alternatives by Description (Same Description) ---
  Future<List<MedicineModel>> findAlternativesByDescription(
    String description,
    String currentTradeName,
  ) async {
    await seedingComplete; // Wait for seeding
    print(
      "Finding alternatives by description in SQLite for description: '$description', excluding: '$currentTradeName'",
    );

    // If description is empty, return empty list
    if (description.isEmpty) {
      print("Cannot find alternatives: Description is empty.");
      return [];
    }

    final db = await dbHelper.database;
    final lowerCaseDescription = description.toLowerCase().trim();
    final lowerCaseTradeName = currentTradeName.toLowerCase();

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where:
          'LOWER(${DatabaseHelper.colDescription}) = ? AND LOWER(${DatabaseHelper.colTradeName}) != ?',
      whereArgs: [lowerCaseDescription, lowerCaseTradeName],
      // Optional: Add limit if needed
    );

    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }
}
