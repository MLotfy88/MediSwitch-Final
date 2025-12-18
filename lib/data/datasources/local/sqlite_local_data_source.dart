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
      .split(RegExp(r'[+/,]'))
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

      // --- Seeding Logic (No count check) ---
      print(
        'Seeding database from asset ON MAIN THREAD (unconditional attempt)...',
      );
      final stopwatch = Stopwatch()..start();

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
        print('[Main Thread] ⚠️ Warning: Failed to seed dosage guidelines: $e');
        // Don't fail the whole seeding process if just this part fails (e.g. file missing)
      }

      // --- Seeding Interactions (Relational) ---
      print('[Main Thread] Seeding Relational Interactions...');
      await _seedRelationalInteractions(db);

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
      // 1. Seed Rules
      int chunk = 1;
      while (true) {
        try {
          final fname =
              'assets/data/interactions/rules_part_${chunk.toString().padLeft(3, '0')}.json';
          final jsonString = await rootBundle.loadString(fname);
          final Map<String, dynamic> content =
              json.decode(jsonString) as Map<String, dynamic>;
          final List<dynamic> rules =
              content['data']
                  as List<
                    dynamic
                  >; // Structure from py script directly uses 'data'

          if (rules.isEmpty) break;

          final batch = db.batch();
          for (final r in rules) {
            batch.insert('interaction_rules', {
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
          print('  Loaded Rules Chunk $chunk (${rules.length} items)');
          chunk++;
        } catch (e) {
          // Break on 404/Not Found (End of chunks)
          break;
        }
      }

      // 2. Seed Ingredients
      chunk = 1;
      while (true) {
        try {
          final fname =
              'assets/data/interactions/ingredients_part_${chunk.toString().padLeft(3, '0')}.json';
          final jsonString = await rootBundle.loadString(fname);
          final Map<String, dynamic> content =
              json.decode(jsonString) as Map<String, dynamic>;
          // Py script format: {"meta": ..., "data": [{"med_id": 1, "ingredients": ["a", "b"]}, ...]}
          final List<dynamic> items = content['data'] as List<dynamic>;

          if (items.isEmpty) break;

          final batch = db.batch();
          for (final item in items) {
            final int medId = item['med_id'] as int;
            final List<dynamic> ingredients =
                item['ingredients'] as List<dynamic>;
            for (final ing in ingredients) {
              batch.insert('med_ingredients', {
                'med_id': medId,
                'ingredient': ing,
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          }
          await batch.commit(noResult: true);
          print('  Loaded Ingredients Chunk $chunk (${items.length} items)');
          chunk++;
        } catch (e) {
          break;
        }
      }
      print('✅ Relational Interaction Data Seeded.');
    } catch (e) {
      print('⚠️ Error seeding relational interactions: $e');
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
    return categoryCounts;
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
    // Count high risk rules linked via ingredients
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT m.*, 
        SUM(CASE 
          WHEN r.severity = 'Contraindicated' THEN 10 
          WHEN r.severity = 'Severe' THEN 8
          WHEN r.severity = 'Major' THEN 5
          WHEN r.severity = 'Moderate' THEN 3
          ELSE 1 
        END) as risk_score
      FROM ${DatabaseHelper.medicinesTable} m
      JOIN med_ingredients mi ON m.id = mi.med_id
      JOIN ${DatabaseHelper.interactionsTable} r ON (r.ingredient1 = mi.ingredient OR r.ingredient2 = mi.ingredient)
      WHERE r.severity IN ('Contraindicated', 'Severe', 'Major')
      GROUP BY m.id
      ORDER BY risk_score DESC
      LIMIT ?
    ''',
      [limit],
    );

    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  Future<List<DrugInteractionModel>> getHighRiskInteractions({
    int limit = 50,
  }) async {
    await seedingComplete;
    final db = await dbHelper.database;
    // Just list rules
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.interactionsTable,
      where: "severity IN ('Contraindicated', 'Severe', 'Major')",
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
