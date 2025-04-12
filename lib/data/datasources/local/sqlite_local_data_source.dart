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
// Keep timestamp key, remove local CSV file name
const String _prefsKeyLastUpdate = 'csv_last_update_timestamp';

// --- Top-level Parsing Function (Temporary - for initial seeding) ---
// This function parses the raw CSV string into a list of MedicineModel
// It should only be used once during database creation.
List<MedicineModel> _parseCsvForSeed(String rawCsv) {
  final List<List<dynamic>> csvTable = const CsvToListConverter(
    fieldDelimiter: ',',
    eol: '\n',
    shouldParseNumbers: false, // Keep as string for DB
  ).convert(rawCsv);

  if (csvTable.isNotEmpty) {
    csvTable.removeAt(0); // Remove header row
  }

  final medicines =
      csvTable.map((row) {
        // Use the existing factory constructor for consistency
        return MedicineModel.fromCsv(row);
      }).toList();

  print('Parsed ${medicines.length} medicines from CSV for DB seeding.');
  return medicines;
}

// --- SqliteLocalDataSource Class ---
class SqliteLocalDataSource {
  final DatabaseHelper dbHelper;

  // Constructor with dependency injection
  SqliteLocalDataSource({required this.dbHelper});

  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // --- Core Logic ---

  // Gets the timestamp of the last update (from prefs) - Stays the same
  Future<int?> getLastUpdateTimestamp() async {
    final prefs = await _prefs;
    return prefs.getInt(_prefsKeyLastUpdate);
  }

  // Seeds the database from the initial asset CSV if the DB is empty
  // This should ideally run only once after DB creation or if DB is deleted.
  // We might call this explicitly after _onCreate in DatabaseHelper or check if table is empty.
  Future<void> seedDatabaseFromAssetIfNeeded() async {
    final db = await dbHelper.database;
    // Check if table is empty
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.medicinesTable}',
      ),
    );
    if (count == 0) {
      print('Medicines table is empty. Seeding database from asset...');
      final stopwatch = Stopwatch()..start(); // Start timer
      try {
        final rawCsv = await rootBundle.loadString('assets/meds.csv');
        // Use compute for parsing large CSV even during seeding
        final medicines = await compute(_parseCsvForSeed, rawCsv);
        await dbHelper.insertMedicinesBatch(medicines);
        final prefs = await _prefs;
        await prefs.setInt(
          _prefsKeyLastUpdate,
          DateTime.now().millisecondsSinceEpoch,
        );
        stopwatch.stop(); // Stop timer
        print(
          'Database seeded successfully in ${stopwatch.elapsedMilliseconds}ms.',
        );
      } catch (e) {
        print('Error seeding database from asset: $e');
        // Handle error appropriately - maybe delete DB and retry?
        rethrow;
      }
    } else {
      print('Database already contains data. Skipping seed.');
    }
  }

  // Save new CSV data downloaded from remote source
  Future<void> saveDownloadedCsv(String csvData) async {
    try {
      print('Parsing downloaded CSV data for database update...');
      // Use compute for parsing large CSV
      final medicines = await compute(_parseCsvForSeed, csvData);

      print('Clearing existing data and inserting new data...');
      await dbHelper.clearMedicines();
      await dbHelper.insertMedicinesBatch(medicines);

      // Update the timestamp in shared preferences
      final prefs = await _prefs;
      await prefs.setInt(
        _prefsKeyLastUpdate,
        DateTime.now().millisecondsSinceEpoch,
      );

      print('Database updated successfully from downloaded CSV.');
    } catch (e) {
      print('Error saving downloaded CSV to database: $e');
      rethrow;
    }
  }

  // --- Public API Methods (Using SQLite) ---

  // Get all medicines
  Future<List<MedicineModel>> getAllMedicines() async {
    print("Fetching all medicines from SQLite...");
    return await dbHelper.getAllMedicines();
  }

  // Search medicines using SQL LIKE
  // Add optional limit parameter
  Future<List<MedicineModel>> searchMedicinesByName(
    String query, {
    int? limit,
  }) async {
    print("Searching medicines in SQLite for query: $query");
    if (query.isEmpty) return getAllMedicines(); // Return all if query is empty

    final db = await dbHelper.database;
    final lowerCaseQuery = '%${query.toLowerCase()}%'; // Add wildcards for LIKE

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: '''
         LOWER(${DatabaseHelper.colTradeName}) LIKE ? OR
         LOWER(${DatabaseHelper.colArabicName}) LIKE ? OR
         LOWER(${DatabaseHelper.colActive}) LIKE ?
       ''',
      whereArgs: [lowerCaseQuery, lowerCaseQuery, lowerCaseQuery],
      limit: limit, // Apply limit if provided
    );

    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  // Filter medicines using SQL WHERE
  Future<List<MedicineModel>> filterMedicinesByCategory(String category) async {
    print("Filtering medicines in SQLite by category: $category");
    if (category.isEmpty)
      return getAllMedicines(); // Return all if category is empty

    final db = await dbHelper.database;
    final lowerCaseCategory = category.toLowerCase();

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where:
          'LOWER(${DatabaseHelper.colMainCategory}) = ?', // Exact match on main category
      whereArgs: [lowerCaseCategory],
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
