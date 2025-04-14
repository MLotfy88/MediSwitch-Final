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

// --- Top-level Parsing Function (Temporary - for initial seeding) ---
List<MedicineModel> _parseCsvForSeed(String rawCsv) {
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
        final medicines = await compute(_parseCsvForSeed, rawCsv);
        await dbHelper.insertMedicinesBatch(medicines);
        final prefs = await _prefs;
        await prefs.setInt(
          _prefsKeyLastUpdate,
          DateTime.now().millisecondsSinceEpoch,
        );
        stopwatch.stop();
        print(
          'Database seeded successfully in ${stopwatch.elapsedMilliseconds}ms.',
        );
      } catch (e) {
        print('Error seeding database from asset: $e');
        rethrow;
      }
    } else {
      print('Database already contains data. Skipping seed.');
    }
  }

  Future<void> saveDownloadedCsv(String csvData) async {
    try {
      print('Parsing downloaded CSV data for database update...');
      final medicines = await compute(_parseCsvForSeed, csvData);

      print('Clearing existing data and inserting new data...');
      await dbHelper.clearMedicines();
      await dbHelper.insertMedicinesBatch(medicines);

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

  Future<List<MedicineModel>> getAllMedicines() async {
    print("Fetching all medicines from SQLite...");
    return await dbHelper.getAllMedicines();
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
