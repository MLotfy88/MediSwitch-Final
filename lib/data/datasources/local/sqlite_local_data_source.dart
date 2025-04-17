import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
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

  // Renamed to be public and indicate its purpose clearly.
  // No longer automatically called. Returns Future<bool> indicating if seeding was performed.
  Future<bool> performInitialSeedingIfNeeded() async {
    if (_seedingCompleter.isCompleted) {
      print('Seeding completer already completed. Assuming seeding is done.');
      return false; // Seeding was not performed now
    }
    // Remove _isSeeding check, as this method is now explicitly called.

    print('Performing initial database seeding check...');
    Database? db; // Declare db here again
    bool seedingPerformed = false;
    try {
      // Restore original check logic
      db = await dbHelper.database; // Ensure DB is initialized first
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.medicinesTable}',
        ),
      );
      print('Database seed check: Medicine count = $count');

      if (count == 0) {
        // db instance is already available here
        print(
          'Medicines table is empty. Seeding database from asset ON MAIN THREAD...',
        );
        final stopwatch = Stopwatch()..start();

        print('[Main Thread] Loading raw CSV asset...');
        final rawCsv = await rootBundle.loadString('assets/meds.csv');
        print('[Main Thread] Raw CSV loaded.');

        print('[Main Thread] Parsing CSV...');
        final List<MedicineModel> medicines = _parseCsvData(rawCsv);
        print('[Main Thread] Parsed ${medicines.length} medicines.');

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

        final prefs = await _prefs;
        await prefs.setInt(
          _prefsKeyLastUpdate,
          DateTime.now().millisecondsSinceEpoch,
        );
        stopwatch.stop();
        print(
          'Database seeded successfully ON MAIN THREAD in ${stopwatch.elapsedMilliseconds}ms.',
        );
        if (!_seedingCompleter.isCompleted) {
          _seedingCompleter.complete();
        }
      } else {
        print('Database already contains data. Skipping seed.');
        if (!_seedingCompleter.isCompleted) {
          _seedingCompleter.complete();
        }
      }
    } catch (e, s) {
      print('Error during MAIN THREAD seeding check/process: $e');
      print(s);
      if (!_seedingCompleter.isCompleted) {
        _seedingCompleter.completeError(e, s);
      }
      seedingPerformed = true; // Mark that seeding was done
    } catch (e, s) {
      print('Error during performInitialSeedingIfNeeded: $e');
      print(s);
      if (!_seedingCompleter.isCompleted) {
        // Propagate the error through the completer
        _seedingCompleter.completeError(e, s);
      }
      rethrow; // Rethrow the error to the caller (e.g., SetupScreen)
    } finally {
      // Ensure completer is completed even if seeding wasn't needed or failed before completion
      if (!_seedingCompleter.isCompleted) {
        print(
          'Completing seeding completer (likely because seeding was skipped or finished).',
        );
        _seedingCompleter.complete();
      }
      print('performInitialSeedingIfNeeded finished.');
    }
    return seedingPerformed;
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
}
