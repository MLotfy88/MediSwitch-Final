import 'dart:async';
import 'dart:convert'; // Import dart:convert

import 'package:csv/csv.dart'; // Restore csv import
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mediswitch/core/database/database_helper.dart';
import 'package:mediswitch/core/utils/category_mapper_helper.dart';
import 'package:mediswitch/data/models/dosage_guidelines_model.dart';
import 'package:mediswitch/data/models/drug_interaction_model.dart'; // Added import
import 'package:mediswitch/data/models/medicine_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

// --- Constants ---
const String _prefsKeyLastUpdate = 'csv_last_update_timestamp';
// Represents the time the APK was built (or the CSV data was generated).
// This ensures we only fetch updates that happened AFTER the app was released.
// 0 means no initial data assumed, triggers full sync/download if no timestamp in prefs
const int _initialDataTimestamp = 0;

// --- Top-level Functions for Isolate ---

// Helper to parse ingredients from active string
List<String> _parseIngredients(String active) {
  if (active.isEmpty) return [];
  // Split by +, /, and ,
  return active
      .split(RegExp(r'[+;,/]'))
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();
}

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
    await db.delete('med_ingredients'); // Clear ingredients mapping

    final batch = db.batch();
    for (final medicine in medicines) {
      batch.insert(
        DatabaseHelper.medicinesTable,
        medicine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Populate ingredients if ID exists
      if (medicine.id != null && medicine.active.isNotEmpty) {
        final ingredients = _parseIngredients(medicine.active);
        for (final ing in ingredients) {
          batch.insert('med_ingredients', {
            'med_id': medicine.id,
            'ingredient': ing,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
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
    final timestamp = prefs.getInt(_prefsKeyLastUpdate);
    // If we have a stored timestamp, return it.
    // If not, it means we just seeded from the CSV.
    // Return the default timestamp of that CSV so we only delta-sync after it.
    return timestamp ?? _initialDataTimestamp;
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

      // --- Seeding Logic (Improved) ---
      print('Seeding database from asset ON MAIN THREAD (needed)...');
      final stopwatch = Stopwatch()..start();

      final medsExist = await hasMedicines();
      if (!medsExist) {
        // Only seed medicines if they don't exist
        print('No medicines found. Starting full seeding...');

        print('[Main Thread] Loading raw CSV asset...');
        final rawCsv = await rootBundle.loadString('assets/meds.csv');
        print('[Main Thread] Raw CSV loaded.');

        print('[Main Thread] Parsing CSV (in background isolate)...');
        // Use compute to unblock UI thread
        final List<MedicineModel> medicines = await compute(
          _parseCsvData,
          rawCsv,
        );
        print('[Main Thread] Parsed ${medicines.length} medicines.');

        if (medicines.isEmpty) {
          print(
            '[Main Thread] WARNING: Parsed medicine list is empty. Check CSV.',
          );
          // Still complete normally, but log warning. Might need error handling?
        } else {
          print('[Main Thread] Starting batch insert...');
          final batch = db.batch();
          // Also clear invalid ingredients if necessary, but this is initial seeding
          // db.delete('med_ingredients');

          for (final medicine in medicines) {
            batch.insert(
              DatabaseHelper.medicinesTable,
              medicine.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            // Populate ingredients if ID exists (Dynamic Linking)
            if (medicine.id != null && medicine.active.isNotEmpty) {
              final ingredients = _parseIngredients(medicine.active);
              for (final ing in ingredients) {
                batch.insert('med_ingredients', {
                  'med_id': medicine.id,
                  'ingredient': ing,
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
          }
          await batch.commit(noResult: true);
          print('[Main Thread] Batch insert completed.');
        }

        // --- Seeding Dosage Guidelines ---
        print('[Main Thread] Seeding Dosage Guidelines...');
        try {
          final dosageJson = await rootBundle.loadString(
            'assets/data/dosage_guidelines.json',
          );
          final List<dynamic> dosageList =
              json.decode(dosageJson) as List<dynamic>;

          if (dosageList.isNotEmpty) {
            final batchDosage = db.batch();
            // Clear existing first if needed? Or just replace. Replace is safer.
            // However, if we do incremental updates, we might want to check.
            // For initial seeding, let's assume clear or replace.
            // Since we don't have a clearDosages method yet, let's just insert with replace.

            for (final item in dosageList) {
              final model = DosageGuidelinesModel.fromJson(
                item as Map<String, dynamic>,
              );
              batchDosage.insert(
                'dosage_guidelines',
                model.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            await batchDosage.commit(noResult: true);
            print(
              '[Main Thread] Dosage Guidelines seeded: ${dosageList.length} items.',
            );
          }
        } catch (e) {
          print(
            '[Main Thread] ⚠️ Warning: Failed to seed dosage guidelines: $e',
          );
          // Don't fail the whole seeding process if just this part fails (e.g. file missing)
        }

        // --- Seeding Interactions (Relational) ---
        print('[Main Thread] Seeding Relational Interactions...');
        await _seedRelationalInteractions(db);
      } else {
        print('Medicines already exist. Skipping medicine seeding.');
      }

      // --- Always check and seed Food Interactions if empty ---
      print('[Main Thread] Checking Food Interactions...');
      final foodInteractionsCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.foodInteractionsTable}',
        ),
      );
      print(
        '[Main Thread] Food Interactions count in DB: $foodInteractionsCount',
      );

      if (foodInteractionsCount == null || foodInteractionsCount == 0) {
        print('[Main Thread] Food Interactions table is EMPTY. Seeding NOW...');
        await _seedFoodInteractions(db);

        // Verify seeding succeeded
        final newCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseHelper.foodInteractionsTable}',
          ),
        );
        print(
          '[Main Thread] After seeding, food_interactions count: $newCount',
        );

        // Sample a few records to verify
        final sample = await db.rawQuery(
          'SELECT trade_name FROM ${DatabaseHelper.foodInteractionsTable} LIMIT 3',
        );
        print(
          '[Main Thread] Sample food interaction drugs: ${sample.map((r) => r['trade_name']).join(", ")}',
        );
      } else {
        print(
          '[Main Thread] Food Interactions already exist ($foodInteractionsCount records).',
        );
        // Sample existing data
        final sample = await db.rawQuery(
          'SELECT trade_name FROM ${DatabaseHelper.foodInteractionsTable} LIMIT 3',
        );
        print(
          '[Main Thread] Sample existing food interaction drugs: ${sample.map((r) => r['trade_name']).join(", ")}',
        );
      }

      final prefs = await _prefs;
      // When we download a FULL updated CSV, we update the timestamp to NOW (or server time if available).
      // Here we use now() as a fallback for the "current version" of the data we just got.
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

  // --- Relational Seeding Helper ---
  Future<void> _seedRelationalInteractions(Database db) async {
    try {
      print(
        '[INTERACTION SEEDING] Starting relational interaction data seeding...',
      );

      // 1. Seed Rules
      int chunk = 1;
      int totalRulesLoaded = 0;
      while (true) {
        try {
          final fname =
              'assets/data/interactions/rules_part_${chunk.toString().padLeft(3, '0')}.json';
          print(
            '[INTERACTION SEEDING] Loading rules chunk $chunk from: $fname',
          );

          final jsonString = await rootBundle.loadString(fname);
          print(
            '[INTERACTION SEEDING] Rules chunk $chunk loaded (${jsonString.length} bytes)',
          );

          final Map<String, dynamic> content =
              json.decode(jsonString) as Map<String, dynamic>;
          final List<dynamic> rules =
              content['data']
                  as List<
                    dynamic
                  >; // Structure from py script directly uses 'data'

          if (rules.isEmpty) {
            print(
              '[INTERACTION SEEDING] Rules chunk $chunk is empty, stopping.',
            );
            break;
          }

          print(
            '[INTERACTION SEEDING] Inserting ${rules.length} rules from chunk $chunk...',
          );
          final batch = db.batch();
          for (final r in rules) {
            batch.insert(DatabaseHelper.interactionsTable, {
              'ingredient1': r['ingredient1'],
              'ingredient2': r['ingredient2'],
              'severity': r['severity'],
              'effect':
                  r['effect'] ??
                  r['description'], // Handle possibly missing key fallback
              'source': r['source'],
            });
          }
          await batch.commit(noResult: true);
          totalRulesLoaded += rules.length;
          print(
            '[INTERACTION SEEDING] ✅ Loaded Rules Chunk $chunk (${rules.length} items, total so far: $totalRulesLoaded)',
          );
          chunk++;
        } catch (e, stackTrace) {
          // Break on 404/Not Found (End of chunks)
          if (e.toString().contains('Unable to load asset') ||
              e.toString().contains('404')) {
            print(
              '[INTERACTION SEEDING] No more rules chunks found (chunk $chunk). Total loaded: $totalRulesLoaded',
            );
            break;
          }
          print('[INTERACTION SEEDING] ❌ ERROR loading rules chunk $chunk: $e');
          print('[INTERACTION SEEDING] Stack trace: $stackTrace');
          break;
        }
      }

      // 2. Seed Ingredients
      chunk = 1;
      int totalIngredientsLoaded = 0;
      while (true) {
        try {
          final fname =
              'assets/data/interactions/ingredients_part_${chunk.toString().padLeft(3, '0')}.json';
          print(
            '[INTERACTION SEEDING] Loading ingredients chunk $chunk from: $fname',
          );

          final jsonString = await rootBundle.loadString(fname);
          print(
            '[INTERACTION SEEDING] Ingredients chunk $chunk loaded (${jsonString.length} bytes)',
          );

          final Map<String, dynamic> content =
              json.decode(jsonString) as Map<String, dynamic>;
          // Py script format: {"meta": ..., "data": [{"med_id": 1, "ingredients": ["a", "b"]}, ...]}
          final List<dynamic> items = content['data'] as List<dynamic>;

          if (items.isEmpty) {
            print(
              '[INTERACTION SEEDING] Ingredients chunk $chunk is empty, stopping.',
            );
            break;
          }

          print(
            '[INTERACTION SEEDING] Inserting ingredient mappings from chunk $chunk (${items.length} drugs)...',
          );
          final batch = db.batch();
          int ingredientCount = 0;
          for (final item in items) {
            final int medId = item['med_id'] as int;
            final List<dynamic> ingredients =
                item['ingredients'] as List<dynamic>;
            for (final ing in ingredients) {
              batch.insert('med_ingredients', {
                'med_id': medId,
                'ingredient': ing,
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
              ingredientCount++;
            }
          }
          await batch.commit(noResult: true);
          totalIngredientsLoaded += ingredientCount;
          print(
            '[INTERACTION SEEDING] ✅ Loaded Ingredients Chunk $chunk (${items.length} drugs, $ingredientCount mappings, total so far: $totalIngredientsLoaded)',
          );
          chunk++;
        } catch (e, stackTrace) {
          if (e.toString().contains('Unable to load asset') ||
              e.toString().contains('404')) {
            print(
              '[INTERACTION SEEDING] No more ingredients chunks found (chunk $chunk). Total loaded: $totalIngredientsLoaded',
            );
            break;
          }
          print(
            '[INTERACTION SEEDING] ❌ ERROR loading ingredients chunk $chunk: $e',
          );
          print('[INTERACTION SEEDING] Stack trace: $stackTrace');
          break;
        }
      }

      print(
        '[INTERACTION SEEDING] ✅✅✅ Relational Interaction Data Seeding COMPLETE!',
      );
      print(
        '[INTERACTION SEEDING] Final totals: $totalRulesLoaded rules, $totalIngredientsLoaded ingredient mappings',
      );
    } catch (e, stackTrace) {
      print(
        '[INTERACTION SEEDING] ⚠️⚠️⚠️ CRITICAL ERROR seeding relational interactions: $e',
      );
      print('[INTERACTION SEEDING] Stack trace: $stackTrace');
    }
  }

  Future<void> _seedFoodInteractions(Database db) async {
    try {
      print('[FOOD INTERACTION SEEDING] Starting food interaction seeding...');
      final jsonString = await rootBundle.loadString(
        'assets/data/food_interactions.json',
      );
      final List<dynamic> interactions =
          json.decode(jsonString) as List<dynamic>;

      if (interactions.isNotEmpty) {
        final batch = db.batch();
        // Assuming partial updates isn't a thing for initial seeding, can replace.
        // But table might be empty.

        for (final item in interactions) {
          batch.insert(
            DatabaseHelper.foodInteractionsTable,
            {
              'med_id': item['med_id'],
              'trade_name': item['trade_name'],
              'interaction': item['interaction'],
              'source': item['source'],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        print(
          '[FOOD INTERACTION SEEDING] ✅ Seeded ${interactions.length} food interactions.',
        );
      }
    } catch (e, stackTrace) {
      print(
        '[FOOD INTERACTION SEEDING] ⚠️ CRITICAL ERROR seeding food interactions: $e',
      );
      print(stackTrace);
    }
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

    // Use CategoryMapperHelper to get keywords for the selected specialty
    final keywords = CategoryMapperHelper.getKeywords(category);

    String whereClause;
    List<dynamic> whereArgs;

    if (keywords.isNotEmpty) {
      // It's a specialty -> filter using keywords on the detailed category column
      // Construct: (lower(col) LIKE ? OR lower(col) LIKE ?)
      final conditions = List.generate(
        keywords.length,
        (index) => "LOWER(${DatabaseHelper.colCategory}) LIKE ?",
      ).join(' OR ');
      whereClause = "($conditions)";
      whereArgs = keywords.map((k) => '%$k%').toList();
    } else {
      // Fallback: Exact match or simple LIKE (if not a specialty)
      // We check colCategory, not colMainCategory which might be empty
      whereClause = 'LOWER(${DatabaseHelper.colCategory}) = ?';
      whereArgs = [category.toLowerCase()];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: whereClause,
      whereArgs: whereArgs,
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
  // --- Statistics ---

  /// Get categories with their drug counts
  /// The user requested to use 'category' (General Category) instead of 'mainCategory'.
  Future<Map<String, int>> getCategoriesWithCount() async {
    await seedingComplete; // Wait for seeding
    print("Fetching categories with counts from SQLite...");
    final db = await dbHelper.database;

    // Use SQL GROUP BY to get counts
    // CHANGED: Using DatabaseHelper.colCategory based on user feedback
    final List<Map<String, dynamic>> results = await db.rawQuery('''
    SELECT ${DatabaseHelper.colCategory} as category, COUNT(*) as count
    FROM ${DatabaseHelper.medicinesTable}
    WHERE ${DatabaseHelper.colCategory} IS NOT NULL 
      AND ${DatabaseHelper.colCategory} != ''
    GROUP BY ${DatabaseHelper.colCategory}
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
    print("Found ${categoryCounts.length} categories with counts.");
    return categoryCounts;
  }

  Future<Map<String, int>> getDashboardStatistics() async {
    await seedingComplete;
    final db = await dbHelper.database;
    final drugCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.medicinesTable}',
      ),
    );
    final pharmCount = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM ${DatabaseHelper.medicinesTable} WHERE ${DatabaseHelper.colPharmacology} IS NOT NULL AND ${DatabaseHelper.colPharmacology} != ''",
      ),
    );
    final foodCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.foodInteractionsTable}',
      ),
    );
    final dosageCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM dosage_guidelines'),
    );

    return {
      'drugs': drugCount ?? 0,
      'pharmacology': pharmCount ?? 0,
      'food_interactions': foodCount ?? 0,
      'dosage_guidelines': dosageCount ?? 0,
    };
  }

  Future<List<MedicineModel>> getRecentlyUpdatedMedicines(
    String cutoffDate, {
    required int limit,
    int? offset,
  }) async {
    await seedingComplete; // Wait for seeding
    print(
      "Fetching recently updated medicines from SQLite (since $cutoffDate, limit: $limit, offset: $offset)...",
    );
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: '${DatabaseHelper.colLastPriceUpdate} >= ?',
      whereArgs: [cutoffDate],
      orderBy:
          '${DatabaseHelper.colLastPriceUpdate} DESC', // Optional: Order by most recent
      limit: limit,
      offset: offset,
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

  Future<bool> hasInteractions() async {
    try {
      final db = await dbHelper.database;
      // Check Rules
      final rulesCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.interactionsTable}',
        ),
      );
      // Check Mappings
      final ingredientsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM med_ingredients'),
      );
      print(
        "Checking interactions: Rules=$rulesCount, Ingredients=$ingredientsCount",
      );
      return (rulesCount ?? 0) > 0 && (ingredientsCount ?? 0) > 0;
    } catch (e) {
      print("Error checking hasInteractions: $e");
      return false;
    }
  }

  Future<void> seedDatabaseFromAssetIfNeeded() async {
    print("[CRITICAL DEBUG] ==== seedDatabaseFromAssetIfNeeded() CALLED ====");
    bool medsExist = await hasMedicines();
    bool interactionsExist = await hasInteractions();

    if (!medsExist || !interactionsExist) {
      print(
        "Missing data (Meds: $medsExist, Interactions: $interactionsExist). Triggering FULL Seeding...",
      );
      await performInitialSeeding();
    } else {
      print("Database already seeded. Checking food_interactions...");

      // CRITICAL: Even if main seeding is done, check food_interactions
      // This ensures existing users get food_interactions table populated
      final db = await dbHelper.database;
      final foodInteractionsCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.foodInteractionsTable}',
        ),
      );

      print(
        '[seedDatabaseFromAssetIfNeeded] Food interactions count: $foodInteractionsCount',
      );

      if (foodInteractionsCount == null || foodInteractionsCount == 0) {
        print(
          '[seedDatabaseFromAssetIfNeeded] Food interactions table is EMPTY! Seeding NOW...',
        );
        await _seedFoodInteractions(db);

        // Verify
        final newCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseHelper.foodInteractionsTable}',
          ),
        );
        print(
          '[seedDatabaseFromAssetIfNeeded] After seeding: $newCount food interactions',
        );
      } else {
        print(
          '[seedDatabaseFromAssetIfNeeded] Food interactions already exist: $foodInteractionsCount',
        );
      }

      markSeedingAsComplete();
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
    final lowerCaseActive = activeIngredient.toLowerCase();

    // SMART MAPPING: Map detailed category to broad specialty, then get its keywords
    // This allows finding "Same Classification" drugs (e.g. all Cardiovascular) even if detailed category differs
    final specialtyId = CategoryMapperHelper.mapCategoryToSpecialty(category);
    final keywords = CategoryMapperHelper.getKeywords(specialtyId);

    String whereClause;
    List<dynamic> whereArgs;

    if (keywords.isNotEmpty) {
      // Broad match using specialty keywords
      final conditions = List.generate(
        keywords.length,
        (index) => "LOWER(${DatabaseHelper.colCategory}) LIKE ?",
      ).join(' OR ');
      whereClause = "($conditions) AND LOWER(${DatabaseHelper.colActive}) != ?";
      whereArgs = [...keywords.map((k) => '%$k%'), lowerCaseActive];
    } else {
      // Exact match fallback (if not a mapped specialty)
      whereClause =
          'LOWER(${DatabaseHelper.colCategory}) = ? AND LOWER(${DatabaseHelper.colActive}) != ?';
      whereArgs = [category.toLowerCase(), lowerCaseActive];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 50, // Limit results to avoid overwhelming the UI
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

  // --- Dosage Guidelines ---
  Future<List<DosageGuidelinesModel>> getDosageGuidelines(int medId) async {
    await seedingComplete;

    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dosage_guidelines',
      where: 'med_id = ?',
      whereArgs: [medId],
    );

    return List.generate(maps.length, (i) {
      return DosageGuidelinesModel.fromMap(maps[i]);
    });
  }

  Future<List<String>> getFoodInteractionsForDrug(int medId) async {
    await seedingComplete;
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.foodInteractionsTable,
      columns: ['interaction'],
      where: 'med_id = ?',
      whereArgs: [medId],
    );

    return maps.map((e) => e['interaction'] as String).toList();
  }

  Future<List<MedicineModel>> getDrugsWithFoodInteractions(int limit) async {
    await seedingComplete;
    final db = await dbHelper.database;

    try {
      // First check if food_interactions table has data
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.foodInteractionsTable}',
      );
      final totalFoodInteractions = Sqflite.firstIntValue(countResult) ?? 0;
      print(
        '[getDrugsWithFoodInteractions] Total food interactions in DB: $totalFoodInteractions',
      );

      if (totalFoodInteractions == 0) {
        print(
          '[getDrugsWithFoodInteractions] WARNING: No food interactions found in database!',
        );
        return [];
      }

      // Step 1: Get distinct trade_names from food_interactions table
      final List<Map<String, dynamic>> tradeNames = await db.rawQuery(
        '''
        SELECT DISTINCT trade_name 
        FROM ${DatabaseHelper.foodInteractionsTable}
        LIMIT ?
      ''',
        [limit],
      );

      print(
        '[getDrugsWithFoodInteractions] Found ${tradeNames.length} unique trade names with food interactions',
      );

      // DEBUG: Print first 5 trade names from food_interactions
      if (tradeNames.isNotEmpty) {
        print(
          '[getDrugsWithFoodInteractions] Sample food interaction trade names: ${tradeNames.take(5).map((e) => e['trade_name']).toList()}',
        );
      }

      if (tradeNames.isEmpty) {
        return [];
      }

      // Step 2: Fetch drugs matching these trade names
      final results = <MedicineModel>[];
      int matchAttempts = 0;
      int matchesFound = 0;

      for (final row in tradeNames) {
        final tradeName = row['trade_name'] as String?;
        if (tradeName == null || tradeName.isEmpty) continue;

        matchAttempts++;
        // Limit extensive logging to first 10 attempts
        final bool logDetail = matchAttempts <= 10;

        // Try exact match first (case-insensitive) -- Adding trim()
        var drugs = await db.query(
          DatabaseHelper.medicinesTable,
          where: 'LOWER(${DatabaseHelper.colTradeName}) = LOWER(?)',
          whereArgs: [tradeName.trim()],
          limit: 1,
        );

        if (drugs.isEmpty) {
          // Try LIKE match
          drugs = await db.query(
            DatabaseHelper.medicinesTable,
            where: 'LOWER(${DatabaseHelper.colTradeName}) LIKE LOWER(?)',
            whereArgs: ['%${tradeName.trim()}%'],
            limit: 1,
          );
          if (logDetail) {
            print(
              '[getDrugsWithFoodInteractions] Exact match failed for "$tradeName". LIKE match found: ${drugs.length}',
            );
          }
        } else {
          if (logDetail) {
            print(
              '[getDrugsWithFoodInteractions] Exact match success for "$tradeName"',
            );
          }
        }

        if (drugs.isNotEmpty) {
          matchesFound++;
          results.add(MedicineModel.fromMap(drugs.first));
        }
      }

      print(
        '[getDrugsWithFoodInteractions] Match summary: Attempts=$matchAttempts, Matches=$matchesFound',
      );
      print(
        '[getDrugsWithFoodInteractions] Successfully matched ${results.length} drugs',
      );
      return results;
    } catch (e, stackTrace) {
      print('[getDrugsWithFoodInteractions] ERROR: $e');
      print(stackTrace);
      return [];
    }
  }

  // --- Interaction Methods ---

  Future<List<DrugInteractionModel>> getInteractionsForDrug(int medId) async {
    await seedingComplete;
    final db = await dbHelper.database;

    // Relational Query: Find rules where one side matches any of this med's ingredients
    // We project 'other_drug' as the one that is NOT the med's ingredient
    // Note: If a med has BOTH ingredient1 and ingredient2 (A + B, and A interacts with B), it returns keys relative to row.

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        r.id, 
        r.severity, 
        r.effect as description, 
        r.source, 
        -- Determine which ingredient is the "other" one
        CASE 
          WHEN r.ingredient1 = mi.ingredient THEN r.ingredient2 
          ELSE r.ingredient1 
        END as interaction_drug_name
      FROM med_ingredients mi
      JOIN ${DatabaseHelper.interactionsTable} r ON (r.ingredient1 = mi.ingredient OR r.ingredient2 = mi.ingredient)
      WHERE mi.med_id = ?
    ''',
      [medId],
    );

    // Deduplicate? If med has Ing A and Ing B, and Rule is A-C, it appears once.
    // If Rule is A-B (internal interaction), it matches A (other=B) AND matches B (other=A).
    // We should probably distinct by rule ID.

    final uniqueIds = <int>{};
    final List<DrugInteractionModel> results = [];

    for (final map in maps) {
      final id = map['id'] as int;
      if (uniqueIds.contains(id)) continue;
      uniqueIds.add(id);

      results.add(
        DrugInteractionModel.fromMap({
          'id': map['id'],
          'med_id': medId, // Helper context
          'interaction_drug_name': map['interaction_drug_name'],
          'severity': map['severity'],
          'description': map['description'],
          'source': map['source'],
          'interaction_dailymed_id': null,
        }),
      );
    }
    return results;
  }

  // Deprecated: No longer inserting batch directly into exploded table.
  Future<void> insertInteractionsBatch(
    List<DrugInteractionModel> interactions,
  ) async {
    // No-op or throw
    print('⚠️ insertInteractionsBatch called but ignored in Relational Mode.');
  }

  Future<List<MedicineModel>> getHighRiskMedicines(int limit) async {
    await seedingComplete;
    final db = await dbHelper.database;

    try {
      // Step 1: Verify med_ingredients table has data
      final ingredientsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM med_ingredients'),
      );
      print('[getHighRiskMedicines] med_ingredients count: $ingredientsCount');

      if (ingredientsCount == 0) {
        print(
          '[getHighRiskMedicines] FATAL: med_ingredients table is empty! Logic relying on ingredients will fail.',
        );
        // Debug: check text content of one medicine to see if ingredients are raw in there
        final sampleMed = await db.query(
          DatabaseHelper.medicinesTable,
          limit: 1,
        );
        if (sampleMed.isNotEmpty) {
          print(
            '[getHighRiskMedicines] Sample Med Active Ingredient: ${sampleMed.first['activeIngredient']}',
          );
        }
      }

      // Step 2: Verify drug_interactions table has data
      final interactionsCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.interactionsTable}',
        ),
      );
      print(
        '[getHighRiskMedicines] drug_interactions count: $interactionsCount',
      );

      if (interactionsCount == 0) {
        print(
          '[getHighRiskMedicines] WARNING: No drug interactions in database!',
        );
        return [];
      }

      // Step 3: Check high-severity interactions
      final highSeverityCount = Sqflite.firstIntValue(
        await db.rawQuery(
          "SELECT COUNT(*) FROM ${DatabaseHelper.interactionsTable} WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major')",
        ),
      );
      print(
        '[getHighRiskMedicines] High-severity interactions: $highSeverityCount',
      );

      // Step 4: Run the main query
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT DISTINCT d.* 
        FROM ${DatabaseHelper.medicinesTable} d
        JOIN med_ingredients mi ON d.id = mi.med_id
        JOIN ${DatabaseHelper.interactionsTable} r ON (mi.ingredient = LOWER(r.ingredient1) OR mi.ingredient = LOWER(r.ingredient2))
        WHERE LOWER(r.severity) IN ('contraindicated', 'severe', 'major')
        LIMIT ?
      ''',
        [limit],
      );

      print(
        '[getHighRiskMedicines] Query returned ${maps.length} high-risk drugs',
      );

      if (maps.isNotEmpty) {
        // Sample first result
        print('[getHighRiskMedicines] Sample drug: ${maps.first['tradeName']}');
      }

      return List.generate(maps.length, (i) {
        return MedicineModel.fromMap(maps[i]);
      });
    } catch (e, stackTrace) {
      print('[getHighRiskMedicines] ERROR: $e');
      print(stackTrace);
      return [];
    }
  }

  /// New method to get specialized ingredient high-risk metrics for Home Screen
  Future<List<Map<String, dynamic>>> getHighRiskIngredientsWithMetrics({
    int limit = 10,
  }) async {
    await seedingComplete;
    final db = await dbHelper.database;

    // Use a CTE to find ingredients involved in high-risk interactions
    // and aggregate their stats. Interaction severity mapping:
    // contraindicated/severe/major -> high
    // OPTIMIZED QUERY: Check multiple cases.
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      WITH AffectedIngredients AS (
        SELECT ingredient1 as ingredient, severity FROM ${DatabaseHelper.interactionsTable}
        WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major')
        UNION ALL
        SELECT ingredient2 as ingredient, severity FROM ${DatabaseHelper.interactionsTable}
        WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major')
      )
      SELECT 
        LOWER(ingredient) as name,
        COUNT(*) as totalInteractions,
        SUM(CASE WHEN LOWER(severity) IN ('contraindicated', 'severe') THEN 1 ELSE 0 END) as severeCount,
        SUM(CASE WHEN LOWER(severity) IN ('major', 'moderate') THEN 1 ELSE 0 END) as moderateCount,
        SUM(CASE WHEN LOWER(severity) = 'minor' THEN 1 ELSE 0 END) as minorCount,
        SUM(CASE 
          WHEN LOWER(severity) = 'contraindicated' THEN 10 
          WHEN LOWER(severity) = 'severe' THEN 8
          WHEN LOWER(severity) = 'major' THEN 5
          WHEN LOWER(severity) = 'moderate' THEN 3
          ELSE 1 
        END) as dangerScore
      FROM AffectedIngredients
      GROUP BY LOWER(ingredient)
      ORDER BY dangerScore DESC
      LIMIT ?
      ''',
      [limit],
    );

    return maps;
  }

  Future<List<DrugInteractionModel>> getHighRiskInteractions({
    int limit = 50,
  }) async {
    await seedingComplete;
    final db = await dbHelper.database;
    // Just list rules
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.interactionsTable,
      where: "LOWER(severity) IN ('contraindicated', 'severe', 'major')",
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      final m = maps[i];
      // Construct a generic model (med_id 0)
      return DrugInteractionModel.fromMap({
        'id': m['id'],
        'med_id': 0,
        'interaction_drug_name':
            '${m['ingredient1']} + ${m['ingredient2']}', // Show pair
        'severity': m['severity'],
        'description': m['effect'] ?? m['description'],
        'source': m['source'],
      });
    });
  }

  Future<List<DrugInteractionModel>> getInteractionsWith(
    String drugName,
  ) async {
    await seedingComplete;
    final db = await dbHelper.database;
    // Search rules for ingredient
    final query = '%${drugName.toLowerCase()}%';
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.interactionsTable,
      where: 'ingredient1 LIKE ? OR ingredient2 LIKE ?',
      whereArgs: [query, query],
    );

    return List.generate(maps.length, (i) {
      final m = maps[i];
      return DrugInteractionModel.fromMap({
        'id': m['id'],
        'med_id': 0,
        'interaction_drug_name': '${m['ingredient1']} + ${m['ingredient2']}',
        'severity': m['severity'],
        'description': m['effect'] ?? m['description'],
        'source': m['source'],
      });
    });
  }
}
