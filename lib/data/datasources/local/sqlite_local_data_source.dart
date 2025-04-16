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

// Function to parse CSV (remains the same, but now public for isolate use)
List<MedicineModel> parseCsvForSeed(String rawCsv) {
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

  print('Parsed ${medicines.length} medicines from CSV for DB seeding.');
  return medicines;
}

// Removed _seedDatabaseIsolate function as seeding will now happen directly

// --- SqliteLocalDataSource Class ---
class SqliteLocalDataSource {
  final DatabaseHelper dbHelper;

  SqliteLocalDataSource({required this.dbHelper});

  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // --- Core Logic ---

  Future<int?> getLastUpdateTimestamp() async {
    final prefs = await _prefs;
    return prefs.getInt(_prefsKeyLastUpdate);
  }

  Future<void> seedDatabaseFromAssetIfNeeded() async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.medicinesTable}',
      ),
    );
    if (count == 0) {
      print('Medicines table is empty. Seeding database from asset...');
      final stopwatch = Stopwatch()..start();
      try {
        final rawCsv = await rootBundle.loadString('assets/meds.csv');

        // --- Seeding Logic (Moved from Isolate) ---
        print('[seedDatabaseFromAssetIfNeeded] Parsing CSV...');
        final medicines = parseCsvForSeed(rawCsv);
        print(
          '[seedDatabaseFromAssetIfNeeded] Parsed ${medicines.length} medicines.',
        );

        print('[seedDatabaseFromAssetIfNeeded] Starting batch insert...');
        final batch = db.batch();
        for (final medicine in medicines) {
          batch.insert(
            DatabaseHelper.medicinesTable,
            medicine.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        print('[seedDatabaseFromAssetIfNeeded] Batch insert completed.');
        // --- End Seeding Logic ---

        // Update timestamp after successful seeding
        final prefs = await _prefs;
        await prefs.setInt(
          _prefsKeyLastUpdate,
          DateTime.now().millisecondsSinceEpoch,
        );
        stopwatch.stop();
        print(
          'Database seeded successfully in ${stopwatch.elapsedMilliseconds}ms.',
        );
        // Removed the 'else' block that threw an exception, rely on try/catch below
      } catch (e, s) {
        // Catch errors during direct seeding
        print('Error during seeding process (main thread): $e');
        // TODO: Add logging here if a logger is available
        rethrow; // Rethrow original error
      }
    } else {
      print('Database already contains data. Skipping seed.');
    }
  }

  Future<void> saveDownloadedCsv(String csvData) async {
    try {
      print('Parsing downloaded CSV data for database update...');
      final db = await dbHelper.database; // Get DB instance

      // --- Update Logic (Moved from Isolate) ---
      print('[saveDownloadedCsv] Parsing CSV...');
      final medicines = parseCsvForSeed(csvData);
      print('[saveDownloadedCsv] Parsed ${medicines.length} medicines.');

      print('[saveDownloadedCsv] Starting batch insert/replace...');
      // Clear existing data before inserting new data from downloaded CSV
      await db.delete(DatabaseHelper.medicinesTable);
      print('[saveDownloadedCsv] Existing data cleared.');

      final batch = db.batch();
      for (final medicine in medicines) {
        batch.insert(
          DatabaseHelper.medicinesTable,
          medicine.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace, // Still useful here
        );
      }
      await batch.commit(noResult: true);
      print('[saveDownloadedCsv] Batch insert completed.');
      // --- End Update Logic ---

      final prefs = await _prefs;
      await prefs.setInt(
        _prefsKeyLastUpdate,
        DateTime.now().millisecondsSinceEpoch,
      );

      print('Database updated successfully from downloaded CSV.');
    } catch (e, s) {
      // Catch errors during direct update
      print('Error during downloaded CSV update process (main thread): $e');
      // TODO: Add logging here if a logger is available
      rethrow;
    }
  }

  // --- Public API Methods (Using SQLite) ---

  Future<List<MedicineModel>> getAllMedicines() async {
    print("Fetching all medicines from SQLite...");
    final db = await dbHelper.database; // Ensure db is awaited here too
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
    );
    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  // Search medicines using SQL LIKE with pagination
  Future<List<MedicineModel>> searchMedicinesByName(
    String query, {
    int? limit,
    int? offset,
  }) async {
    print(
      "Searching medicines in SQLite for query: '$query', limit: $limit, offset: $offset",
    );
    // Return limited list if query is empty (for initial load)
    // if (query.isEmpty) return getAllMedicines(); // Keep this? Or rely on limit/offset? Let's rely on limit/offset

    final db = await dbHelper.database;
    final lowerCaseQuery = '%${query.toLowerCase()}%';

    String whereClause = '1=1'; // Default if query is empty
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
      limit: limit, // Apply limit if provided
      offset: offset, // Apply offset if provided
    );

    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  // Filter medicines using SQL WHERE with pagination
  Future<List<MedicineModel>> filterMedicinesByCategory(
    String category, {
    int? limit,
    int? offset,
  }) async {
    print(
      "Filtering medicines in SQLite by category: '$category', limit: $limit, offset: $offset",
    );
    if (category.isEmpty) {
      // If category is empty, maybe return paginated results of all?
      // Or handle this logic in the provider/use case?
      // For now, let's return based on limit/offset without category filter if category is empty.
      return searchMedicinesByName('', limit: limit, offset: offset);
    }

    final db = await dbHelper.database;
    final lowerCaseCategory = category.toLowerCase();

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where:
          'LOWER(${DatabaseHelper.colMainCategory}) = ?', // Case-insensitive match
      whereArgs: [lowerCaseCategory],
      limit: limit, // Apply limit if provided
      offset: offset, // Apply offset if provided
    );

    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  // Get available categories using SQL DISTINCT
  Future<List<String>> getAvailableCategories() async {
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
            .where((cat) => cat.isNotEmpty) // Filter out empty categories
            .toList();
    categories.sort(); // Sort alphabetically
    return categories;
  }
}
