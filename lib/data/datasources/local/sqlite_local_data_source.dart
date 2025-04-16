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

  // Note: Printing from isolates might not show up in the standard debug console
  // Consider using a dedicated isolate logging mechanism if needed.
  // print('Parsed ${medicines.length} medicines from CSV for DB seeding (Isolate).');
  return medicines;
}

// Isolate function for seeding
Future<void> _seedDatabaseIsolate(Map<String, dynamic> args) async {
  final String dbPath = args['dbPath'] as String; // Cast to String
  final List<MedicineModel> medicines =
      args['medicines'] as List<MedicineModel>; // Cast to List<MedicineModel>

  // Open the database within the isolate
  final Database db = await openDatabase(dbPath);

  // print('[Isolate] Starting batch insert...');
  final batch = db.batch();
  for (final medicine in medicines) {
    batch.insert(
      DatabaseHelper.medicinesTable,
      medicine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await batch.commit(noResult: true);
  // print('[Isolate] Batch insert completed.');

  await db.close(); // Close the database connection in the isolate
}

// Isolate function for updating from downloaded CSV
Future<void> _updateDatabaseIsolate(Map<String, dynamic> args) async {
  final String dbPath = args['dbPath'] as String; // Cast to String
  final List<MedicineModel> medicines =
      args['medicines'] as List<MedicineModel>; // Cast to List<MedicineModel>

  final Database db = await openDatabase(dbPath);

  // print('[Isolate] Clearing existing data...');
  await db.delete(DatabaseHelper.medicinesTable);
  // print('[Isolate] Existing data cleared.');

  // print('[Isolate] Starting batch insert/replace...');
  final batch = db.batch();
  for (final medicine in medicines) {
    batch.insert(
      DatabaseHelper.medicinesTable,
      medicine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await batch.commit(noResult: true);
  // print('[Isolate] Batch insert completed.');

  await db.close();
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
      print(
        'Medicines table is empty. Seeding database from asset (using isolate)...',
      );
      final stopwatch = Stopwatch()..start();
      try {
        final rawCsv = await rootBundle.loadString('assets/meds.csv');

        // Parse CSV on main thread (usually fast enough)
        print('[Main Thread] Parsing CSV...');
        final medicines = _parseCsvForSeed(rawCsv);
        print('[Main Thread] Parsed ${medicines.length} medicines.');
        // Perform DB operations in isolate
        print('[Main Thread] Starting database seeding in isolate...');
        try {
          await compute(_seedDatabaseIsolate, {
            'dbPath': db.path, // Pass the database path
            'medicines': medicines,
          });
          print('[Main Thread] Isolate seeding completed successfully.');
        } catch (isolateError, isolateStacktrace) {
          print(
            '[Main Thread] Error received from seeding isolate: $isolateError',
          );
          print(isolateStacktrace);
          // Rethrow the error to be caught by the outer try-catch
          rethrow;
        }

        // Update timestamp after successful seeding
        final prefs = await _prefs;
        await prefs.setInt(
          _prefsKeyLastUpdate,
          DateTime.now().millisecondsSinceEpoch,
        );
        stopwatch.stop();
        print(
          'Database seeded successfully (via isolate) in ${stopwatch.elapsedMilliseconds}ms.',
        );
      } catch (e, s) {
        print('Error during seeding process: $e');
        print(s); // Print stack trace for debugging
        rethrow; // Rethrow original error
      }
    } else {
      print('Database already contains data. Skipping seed.');
    }
  }

  Future<void> saveDownloadedCsv(String csvData) async {
    try {
      print(
        'Parsing downloaded CSV data for database update (using isolate)...',
      );
      final db = await dbHelper.database; // Get DB instance for path

      // Parse CSV on main thread
      print('[Main Thread] Parsing downloaded CSV...');
      final medicines = _parseCsvForSeed(csvData);
      print('[Main Thread] Parsed ${medicines.length} medicines.');
      // Perform DB operations in isolate
      print('[Main Thread] Starting database update in isolate...');
      try {
        await compute(_updateDatabaseIsolate, {
          'dbPath': db.path,
          'medicines': medicines,
        });
        print('[Main Thread] Isolate update completed successfully.');
      } catch (isolateError, isolateStacktrace) {
        print(
          '[Main Thread] Error received from update isolate: $isolateError',
        );
        print(isolateStacktrace);
        // Rethrow the error to be caught by the outer try-catch
        rethrow;
      }

      final prefs = await _prefs;
      await prefs.setInt(
        _prefsKeyLastUpdate,
        DateTime.now().millisecondsSinceEpoch,
      );

      print('Database updated successfully from downloaded CSV (via isolate).');
    } catch (e, s) {
      print('Error during downloaded CSV update process: $e');
      print(s);
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
