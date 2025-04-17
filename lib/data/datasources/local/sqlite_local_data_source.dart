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

// Function to parse CSV
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

// Isolate function for seeding - MODIFIED to accept rawCsv AND add internal try-catch
Future<void> _seedDatabaseIsolate(Map<String, dynamic> args) async {
  final String dbPath = args['dbPath'] as String;
  final String rawCsv = args['rawCsv'] as String;
  Database? db; // Declare db outside try block

  try {
    // print('[Isolate] Parsing CSV...');
    final List<MedicineModel> medicines = _parseCsvData(rawCsv);
    // print('[Isolate] Parsed ${medicines.length} medicines.');

    // Open the database within the isolate
    // print('[Isolate] Opening database at path: $dbPath');
    db = await openDatabase(dbPath);
    // print('[Isolate] Database opened.');

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
  } catch (e, s) {
    // Print error directly from isolate for better debugging visibility
    print('!!! ERROR INSIDE _seedDatabaseIsolate !!!');
    print('Error: $e');
    print('Stacktrace: $s');
    // Rethrow the error so compute() catches it and completes the future with error
    rethrow;
  } finally {
    // Ensure database is closed even if error occurred after opening
    if (db != null && db.isOpen) {
      // print('[Isolate] Closing database connection.');
      await db.close();
    } else {
      // print('[Isolate] Database connection was not opened or already closed.');
    }
  }
}

// Isolate function for updating from downloaded CSV - MODIFIED to accept rawCsv
Future<void> _updateDatabaseIsolate(Map<String, dynamic> args) async {
  final String dbPath = args['dbPath'] as String; // Cast to String
  final String rawCsv = args['rawCsv'] as String; // Receive raw CSV string
  Database? db; // Declare outside try

  try {
    // print('[Isolate] Parsing downloaded CSV...');
    final List<MedicineModel> medicines = _parseCsvData(
      rawCsv,
    ); // Parse inside isolate
    // print('[Isolate] Parsed ${medicines.length} medicines.');

    db = await openDatabase(dbPath);

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
  } catch (e, s) {
    print('!!! ERROR INSIDE _updateDatabaseIsolate !!!');
    print('Error: $e');
    print('Stacktrace: $s');
    rethrow;
  } finally {
    if (db != null && db.isOpen) {
      // print('[Isolate] Closing database connection (update).');
      await db.close();
    }
  }
}

// --- SqliteLocalDataSource Class ---
class SqliteLocalDataSource {
  final DatabaseHelper dbHelper;
  // Completer to signal when initial seeding (if needed) is done
  final Completer<void> _seedingCompleter = Completer<void>();

  // Public future that external classes can await
  Future<void> get seedingComplete => _seedingCompleter.future;

  SqliteLocalDataSource({required this.dbHelper}) {
    // Start the seeding check process asynchronously in the constructor
    _ensureSeedingDone();
  }

  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // --- Core Logic ---

  Future<int?> getLastUpdateTimestamp() async {
    await seedingComplete; // Ensure seeding is done before accessing prefs related to updates
    final prefs = await _prefs;
    return prefs.getInt(_prefsKeyLastUpdate);
  }

  // Renamed from seedDatabaseFromAssetIfNeeded to make its purpose clearer
  // REVERTED: Use compute again, but with better error handling in isolate
  Future<void> _ensureSeedingDone() async {
    // Check if seeding is already complete or in progress
    if (_seedingCompleter.isCompleted) {
      print('Seeding process already completed.');
      return;
    }

    Database? db; // Declare outside try block
    try {
      db = await dbHelper.database;
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
        // Load raw CSV string on main thread (faster)
        print('[Main Thread] Loading raw CSV asset...');
        final rawCsv = await rootBundle.loadString('assets/meds.csv');
        print('[Main Thread] Raw CSV loaded.');

        // Perform parsing and DB operations in isolate
        print(
          '[Main Thread] Starting database seeding in isolate (parsing + insert)...',
        );
        // Use compute again
        await compute(_seedDatabaseIsolate, {
          'dbPath': db.path, // Pass the database path
          'rawCsv': rawCsv, // Pass raw CSV string
        });
        print('[Main Thread] Isolate seeding completed successfully.');

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
        // Signal successful completion
        if (!_seedingCompleter.isCompleted) {
          _seedingCompleter.complete();
        }
      } else {
        print('Database already contains data. Skipping seed.');
        // Signal completion as seeding wasn't needed
        if (!_seedingCompleter.isCompleted) {
          _seedingCompleter.complete();
        }
      }
    } catch (e, s) {
      print('Error during seeding check/process (caught on main thread): $e');
      print(s); // Print stack trace for debugging
      // Signal completion with an error
      if (!_seedingCompleter.isCompleted) {
        _seedingCompleter.completeError(e, s);
      }
      // Optionally rethrow if the caller needs to handle it immediately
      // rethrow;
    }
    // Note: We are not closing the DB connection here as it's managed by dbHelper
  }

  Future<void> saveDownloadedCsv(String csvData) async {
    await seedingComplete; // Ensure initial seeding isn't running concurrently
    try {
      print(
        'Parsing downloaded CSV data for database update (using isolate)...',
      );
      final db = await dbHelper.database; // Get DB instance for path

      // Perform parsing and DB operations in isolate
      print(
        '[Main Thread] Starting database update in isolate (parsing + insert)...',
      );
      // Await the compute call directly
      await compute(_updateDatabaseIsolate, {
        'dbPath': db.path,
        'rawCsv': csvData, // Pass raw CSV string
      });
      print('[Main Thread] Isolate update completed successfully.');

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
    await seedingComplete; // Wait for seeding
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
    await seedingComplete; // Wait for seeding
    print(
      "Searching medicines in SQLite for query: '$query', limit: $limit, offset: $offset",
    );

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
            .where((cat) => cat.isNotEmpty) // Filter out empty categories
            .toList();
    categories.sort(); // Sort alphabetically
    return categories;
  }
}
