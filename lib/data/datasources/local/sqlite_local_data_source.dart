import 'dart:async';
import 'dart:convert'; // Import dart:convert

import 'package:csv/csv.dart'; // Restore csv import
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mediswitch/core/database/database_helper.dart';
import 'package:mediswitch/core/services/file_logger_service.dart';
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

  final FileLoggerService _logger;

  // Constructor no longer automatically triggers seeding
  SqliteLocalDataSource({required this.dbHelper, FileLoggerService? logger})
    : _logger = logger ?? FileLoggerService();

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
      _logger.i(
        'performInitialSeeding called, but completer is already completed. Skipping.',
      );
      return false; // Seeding was already done
    }

    _logger.i('Performing initial database seeding from asset...');
    Database? db;
    bool seedingPerformedSuccessfully = false;
    try {
      db = await dbHelper.database;

      _logger.i('Seeding database from asset ON MAIN THREAD (needed)...');
      final stopwatch = Stopwatch()..start();

      final medsExist = await hasMedicines();
      final ingredientsCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM med_ingredients'),
          ) ??
          0;
      _logger.i(
        '[Main Thread] Meds exist: $medsExist, Ingredients count: $ingredientsCount',
      );

      if (!medsExist || ingredientsCount == 0) {
        _logger.w('Missing medicines or ingredients. Starting full seeding...');

        if (medsExist) {
          _logger.w(
            '[Main Thread] clearing existing medicines and ingredients for clean slate...',
          );
          await db.delete('med_ingredients');
          await db.delete(DatabaseHelper.medicinesTable);
        }

        _logger.i('[Main Thread] Loading raw CSV asset...');
        String rawCsv;
        try {
          rawCsv = await rootBundle.loadString('assets/meds.csv');
          _logger.i(
            '[Main Thread] Raw CSV loaded successfully (${rawCsv.length} characters).',
          );
        } catch (e) {
          _logger.e(
            '[Main Thread] CRITICAL: Failed to load meds.csv from assets. This may indicate: '
            '1) Asset not bundled in APK/build, 2) File path incorrect, 3) Insufficient permissions. Error: $e',
          );
          throw Exception('Failed to load meds.csv asset: $e');
        }

        _logger.i('[Main Thread] Parsing CSV (in background isolate)...');
        final List<MedicineModel> medicines = await compute(
          _parseCsvData,
          rawCsv,
        );
        _logger.i('[Main Thread] Parsed ${medicines.length} medicines.');

        if (medicines.isEmpty) {
          _logger.e(
            '[Main Thread] WARNING: Parsed medicine list is empty. Check CSV.',
          );
        } else {
          _logger.i(
            '[Main Thread] Loading medicine_ingredients.json for precise mapping...',
          );
          Map<String, dynamic> ingredientsMap = {};
          try {
            final ingredientsJson = await rootBundle.loadString(
              'assets/data/medicine_ingredients.json',
            );
            ingredientsMap =
                json.decode(ingredientsJson) as Map<String, dynamic>;
            _logger.i(
              '[Main Thread] medicine_ingredients.json loaded successfully (${ingredientsMap.length} drugs mapped).',
            );
          } catch (e) {
            _logger.w(
              '[Main Thread] Could not load medicine_ingredients.json. '
              'Will use regex fallback for ingredient extraction. '
              'This is not critical but may reduce accuracy. Error: $e',
            );
          }

          _logger.i(
            '[Main Thread] Starting chunked batch insert (Meds & Ingredients)...',
          );

          const int chunkSize = 500;
          for (int i = 0; i < medicines.length; i += chunkSize) {
            final end =
                (i + chunkSize < medicines.length)
                    ? i + chunkSize
                    : medicines.length;
            final chunk = medicines.sublist(i, end);

            _logger.i(
              '[Main Thread] Inserting chunk ${i ~/ chunkSize + 1} (${chunk.length} items)...',
            );

            final batch = db.batch();
            for (final medicine in chunk) {
              try {
                batch.insert(
                  DatabaseHelper.medicinesTable,
                  medicine.toMap(),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );

                // Populate ingredients
                if (medicine.id != null && medicine.id != 0) {
                  List<String> ingredients = [];
                  // Try precise map first
                  if (ingredientsMap.containsKey(medicine.tradeName)) {
                    final dynamic mapped = ingredientsMap[medicine.tradeName];
                    if (mapped is List) {
                      ingredients =
                          mapped
                              .map((e) => e.toString().toLowerCase().trim())
                              .toList();
                    }
                  }

                  // Fallback to regex if precise map failed or empty but active string exists
                  if (ingredients.isEmpty && medicine.active.isNotEmpty) {
                    ingredients = _parseIngredients(medicine.active);
                  }

                  if (ingredients.isNotEmpty) {
                    for (final ing in ingredients) {
                      batch.insert(
                        'med_ingredients',
                        {
                          'med_id': medicine.id,
                          'ingredient': ing,
                          'updated_at': 0, // Fill for new column
                        },
                        conflictAlgorithm: ConflictAlgorithm.replace,
                      );
                    }
                  }
                }
              } catch (e) {
                _logger.e(
                  '[Main Thread] Skipping bad medicine record: ${medicine.tradeName}',
                  e,
                );
              }
            }
            await batch.commit(noResult: true);
            _logger.i('[Main Thread] Chunk ${i ~/ chunkSize + 1} committed.');
          }
          _logger.i('[Main Thread] All medicine chunks inserted successfully.');
        }

        // --- Seeding Dosage Guidelines ---
        _logger.i('[Main Thread] Seeding Dosage Guidelines...');
        try {
          final dosageJson = await rootBundle.loadString(
            'assets/data/dosage_guidelines.json',
          );
          final List<dynamic> dosageList =
              json.decode(dosageJson) as List<dynamic>;

          if (dosageList.isNotEmpty) {
            final batchDosage = db.batch();
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
            _logger.i(
              '[Main Thread] Dosage Guidelines seeded successfully: ${dosageList.length} items.',
            );
          } else {
            _logger.w('[Main Thread] Dosage guidelines JSON was empty.');
          }
        } catch (e) {
          _logger.w(
            '[Main Thread] ⚠️ Non-critical: Failed to seed dosage guidelines. '
            'App will function but dosage calculator may have limited data. Error: $e',
          );
          // This is non-critical, app can continue without dosage guidelines
        }

        // --- Seeding Interactions ---
        // (Handled below)
      } else {
        _logger.i(
          'Medicines and ingredients already exist. Skipping medicine seeding.',
        );
      }

      // --- Always check and seed Relational Interactions if empty ---
      _logger.i('[Main Thread] Checking Relational Interactions...');
      final interactionsCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.interactionsTable}',
        ),
      );
      _logger.i(
        '[Main Thread] Relational Interactions count in DB: $interactionsCount',
      );

      if (interactionsCount == null || interactionsCount == 0) {
        _logger.i(
          '[Main Thread] Relational Interactions table is EMPTY. Seeding NOW...',
        );
        await _seedRelationalInteractions(db);
      } else {
        _logger.i(
          '[Main Thread] Relational Interactions already exist ($interactionsCount records).',
        );
      }

      // --- Always check and seed Food Interactions if empty ---
      _logger.i('[Main Thread] Checking Food Interactions...');
      final foodInteractionsCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.foodInteractionsTable}',
        ),
      );
      _logger.i(
        '[Main Thread] Food Interactions count in DB: $foodInteractionsCount',
      );

      if (foodInteractionsCount == null || foodInteractionsCount == 0) {
        _logger.i(
          '[Main Thread] Food Interactions table is EMPTY. Seeding NOW...',
        );
        await _seedFoodInteractions(db);

        // Verify seeding succeeded
        final newCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseHelper.foodInteractionsTable}',
          ),
        );
        _logger.i(
          '[Main Thread] After seeding, food_interactions count: $newCount',
        );
      } else {
        _logger.i(
          '[Main Thread] Food Interactions already exist ($foodInteractionsCount records).',
        );
      }

      final prefs = await _prefs;
      await prefs.setInt(
        _prefsKeyLastUpdate,
        DateTime.now().millisecondsSinceEpoch,
      );
      stopwatch.stop();
      _logger.i(
        'Database seeding attempt finished in ${stopwatch.elapsedMilliseconds}ms.',
      );
      seedingPerformedSuccessfully = true;

      if (!_seedingCompleter.isCompleted) {
        _seedingCompleter.complete();
      }
    } catch (e, s) {
      _logger.e('Error during MAIN THREAD seeding process', e, s);
      seedingPerformedSuccessfully = false;
      if (!_seedingCompleter.isCompleted) {
        _seedingCompleter.completeError(e, s);
      }
    } finally {
      if (!_seedingCompleter.isCompleted) {
        _logger.w(
          'Completing seeding completer in finally block (unexpected state).',
        );
        _seedingCompleter.complete();
      }
      _logger.i('performInitialSeeding finished.');
    }
    return seedingPerformedSuccessfully;
  }

  // --- Relational Seeding Helper ---
  Future<void> _seedRelationalInteractions(Database db) async {
    try {
      _logger.i(
        '[INTERACTION SEEDING] Starting relational interaction data seeding...',
      );

      // 1. Seed Rules
      int chunk = 1;
      int totalRulesLoaded = 0;
      while (true) {
        try {
          final fname =
              'assets/data/interactions/rules_part_${chunk.toString().padLeft(3, '0')}.json';
          _logger.i(
            '[INTERACTION SEEDING] Loading rules chunk $chunk from: $fname',
          );

          final jsonString = await rootBundle.loadString(fname);
          _logger.i(
            '[INTERACTION SEEDING] Rules chunk $chunk loaded (${jsonString.length} bytes)',
          );

          final Map<String, dynamic> content =
              json.decode(jsonString) as Map<String, dynamic>;
          final List<dynamic> rules = (content['data'] as List?) ?? [];

          if (rules.isEmpty) {
            _logger.i(
              '[INTERACTION SEEDING] Rules chunk $chunk is empty, stopping.',
            );
            break;
          }

          _logger.i(
            '[INTERACTION SEEDING] Inserting ${rules.length} rules from chunk $chunk...',
          );
          final batch = db.batch();
          for (final r in rules) {
            final i1 = _normalizeIngredientName(
              r['ingredient1'] as String? ?? '',
            );
            final i2 = _normalizeIngredientName(
              r['ingredient2'] as String? ?? '',
            );
            // Filter out junk data and short names
            final junkWords = [
              'interactions',
              'uses',
              'side effects',
              'dosage',
              'precautions',
            ];
            if (i1.length < 3 || junkWords.contains(i1.toLowerCase())) continue;
            if (i2.length < 3 || junkWords.contains(i2.toLowerCase())) continue;

            if (i1.isEmpty || i2.isEmpty) continue;

            batch.insert(DatabaseHelper.interactionsTable, {
              'ingredient1': i1,
              'ingredient2': i2,
              'severity': r['severity'],
              'effect': r['effect'] ?? r['description'],
              'source': r['source'],
              'updated_at': 0,
            });
          }
          await batch.commit(noResult: true);
          totalRulesLoaded += rules.length;
          _logger.i(
            '[INTERACTION SEEDING] ✅ Loaded Rules Chunk $chunk (${rules.length} items, total: $totalRulesLoaded)',
          );
          chunk++;
        } catch (e) {
          if (e.toString().contains('Unable to load asset') ||
              e.toString().contains('404')) {
            _logger.i(
              '[INTERACTION SEEDING] No more rules chunks found. Total: $totalRulesLoaded',
            );
            break;
          }
          _logger.e(
            '[INTERACTION SEEDING] ❌ ERROR loading rules chunk $chunk',
            e,
          );
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
          _logger.i(
            '[INTERACTION SEEDING] Loading ingredients chunk $chunk from: $fname',
          );

          final jsonString = await rootBundle.loadString(fname);
          _logger.i(
            '[INTERACTION SEEDING] Ingredients chunk $chunk loaded (${jsonString.length} bytes)',
          );

          final Map<String, dynamic> content =
              json.decode(jsonString) as Map<String, dynamic>;
          final List<dynamic> items = (content['data'] as List?) ?? [];

          if (items.isEmpty) {
            _logger.i(
              '[INTERACTION SEEDING] Ingredients chunk $chunk is empty, stopping.',
            );
            break;
          }

          _logger.i(
            '[INTERACTION SEEDING] Inserting mappings from chunk $chunk (${items.length} drugs)...',
          );
          final batch = db.batch();
          int ingredientCount = 0;
          for (final item in items) {
            final int medId = item['med_id'] as int;
            final List<dynamic> ingredients =
                item['ingredients'] as List<dynamic>;
            for (final ing in ingredients) {
              final normalizedIng = _normalizeIngredientName(
                ing as String? ?? '',
              );
              if (normalizedIng.isEmpty) continue;

              batch.insert('med_ingredients', {
                'med_id': medId,
                'ingredient': normalizedIng,
                'updated_at': 0,
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
              ingredientCount++;
            }
          }
          await batch.commit(noResult: true);
          totalIngredientsLoaded += ingredientCount;
          _logger.i(
            '[INTERACTION SEEDING] ✅ Loaded Ingredients Chunk $chunk ($ingredientCount items, total: $totalIngredientsLoaded)',
          );
          chunk++;
        } catch (e) {
          if (e.toString().contains('Unable to load asset') ||
              e.toString().contains('404')) {
            _logger.i(
              '[INTERACTION SEEDING] No more ingredients chunks found. Total: $totalIngredientsLoaded',
            );
            break;
          }
          _logger.e(
            '[INTERACTION SEEDING] ❌ ERROR loading ingredients chunk $chunk',
            e,
          );
          break;
        }
      }

      _logger.i(
        '[INTERACTION SEEDING] ✅ SUCCESS! Rules: $totalRulesLoaded, Ingredients: $totalIngredientsLoaded',
      );
    } catch (e, stackTrace) {
      _logger.e('[INTERACTION SEEDING] CRITICAL ERROR', e, stackTrace);
    }
  }

  Future<void> _seedFoodInteractions(Database db) async {
    try {
      _logger.i(
        '[FOOD INTERACTION SEEDING] Starting food interaction seeding...',
      );
      final jsonString = await rootBundle.loadString(
        'assets/data/food_interactions.json',
      );
      final List<dynamic> interactions =
          json.decode(jsonString) as List<dynamic>;

      if (interactions.isNotEmpty) {
        final batch = db.batch();
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
        _logger.i(
          '[FOOD INTERACTION SEEDING] ✅ Seeded ${interactions.length} food interactions.',
        );
      }
    } catch (e, stackTrace) {
      _logger.e('[FOOD INTERACTION SEEDING] CRITICAL ERROR', e, stackTrace);
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
    final db = await dbHelper.database;
    final queryStr = 'SELECT * FROM ${DatabaseHelper.medicinesTable}';
    final List<Map<String, dynamic>> maps = await db.rawQuery(queryStr);
    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  Future<List<MedicineModel>> searchMedicinesByName(
    String query, {
    int? limit,
    int? offset,
  }) async {
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

    final queryStr = '''
      SELECT d.*,
        EXISTS(SELECT 1 FROM ${DatabaseHelper.foodInteractionsTable} fi WHERE fi.med_id = d.id) as has_food_interaction,
        EXISTS(
          SELECT 1 FROM med_ingredients mi 
          JOIN ${DatabaseHelper.interactionsTable} di 
          ON (mi.ingredient = di.ingredient1 OR mi.ingredient = di.ingredient2)
          WHERE mi.med_id = d.id AND LOWER(di.severity) IN ('contraindicated', 'severe', 'major', 'high')
        ) as has_drug_interaction
      FROM ${DatabaseHelper.medicinesTable} d
      WHERE $whereClause
      ORDER BY ${DatabaseHelper.colLastPriceUpdate} DESC
      LIMIT ? OFFSET ?
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(queryStr, [
      ...whereArgs,
      limit,
      offset,
    ]);

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

    final queryStr = '''
      SELECT d.*,
        EXISTS(SELECT 1 FROM ${DatabaseHelper.foodInteractionsTable} fi WHERE fi.med_id = d.id) as has_food_interaction,
        EXISTS(
          SELECT 1 FROM med_ingredients mi 
          JOIN ${DatabaseHelper.interactionsTable} di 
          ON (mi.ingredient = di.ingredient1 OR mi.ingredient = di.ingredient2)
          WHERE mi.med_id = d.id AND LOWER(di.severity) IN ('contraindicated', 'severe', 'major', 'high')
        ) as has_drug_interaction
      FROM ${DatabaseHelper.medicinesTable} d
      WHERE $whereClause
      LIMIT ? OFFSET ?
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(queryStr, [
      ...whereArgs,
      limit,
      offset,
    ]);

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
    final db = await dbHelper.database;
    final actualOffset = offset ?? 0; // Default to 0 if null
    final queryStr = '''
      SELECT d.*,
        EXISTS(SELECT 1 FROM ${DatabaseHelper.foodInteractionsTable} fi WHERE fi.med_id = d.id) as has_food_interaction,
        EXISTS(
          SELECT 1 FROM med_ingredients mi 
          JOIN ${DatabaseHelper.interactionsTable} di 
          ON (mi.ingredient = di.ingredient1 OR mi.ingredient = di.ingredient2)
          WHERE mi.med_id = d.id AND LOWER(di.severity) IN ('contraindicated', 'severe', 'major', 'high')
        ) as has_drug_interaction
      FROM ${DatabaseHelper.medicinesTable} d
      WHERE d.${DatabaseHelper.colLastPriceUpdate} IS NOT NULL 
        AND d.${DatabaseHelper.colLastPriceUpdate} != ''
      ORDER BY d.${DatabaseHelper.colLastPriceUpdate} DESC
      LIMIT ? OFFSET ?
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(queryStr, [
      limit,
      actualOffset,
    ]);
    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  Future<List<MedicineModel>> getRandomMedicines({required int limit}) async {
    await seedingComplete; // Wait for seeding
    final db = await dbHelper.database;
    final queryStr = '''
      SELECT d.*,
        EXISTS(SELECT 1 FROM ${DatabaseHelper.foodInteractionsTable} fi WHERE fi.med_id = d.id) as has_food_interaction,
        EXISTS(
          SELECT 1 FROM med_ingredients mi 
          JOIN ${DatabaseHelper.interactionsTable} di 
          ON (mi.ingredient = di.ingredient1 OR mi.ingredient = di.ingredient2)
          WHERE mi.med_id = d.id AND LOWER(di.severity) IN ('contraindicated', 'severe', 'major', 'high')
        ) as has_drug_interaction
      FROM ${DatabaseHelper.medicinesTable} d
      ORDER BY RANDOM()
      LIMIT ?
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(queryStr, [
      limit,
    ]);
    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  /// Get top popular medicines based on visits count
  /// If all have 0 visits, returns by newest ID
  Future<List<MedicineModel>> getPopularMedicines({int limit = 50}) async {
    await seedingComplete; // Wait for seeding
    final db = await dbHelper.database;
    final queryStr = '''
      SELECT *
      FROM ${DatabaseHelper.medicinesTable}
      ORDER BY ${DatabaseHelper.colVisits} DESC, ${DatabaseHelper.colId} DESC
      LIMIT ?
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(queryStr, [
      limit,
    ]);
    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }

  /// Checks if the medicines table has any data.

  Future<bool> hasMedicines() async {
    try {
      final db = await dbHelper.database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.medicinesTable}',
        ),
      );
      _logger.i("Checking if database has medicines. Count: $count");
      return count != null && count > 0;
    } catch (e, s) {
      _logger.e("Error checking medicine count", e, s);
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
      _logger.i(
        "Checking interactions: Rules=$rulesCount, Ingredients=$ingredientsCount",
      );
      return (rulesCount ?? 0) > 0 && (ingredientsCount ?? 0) > 0;
    } catch (e, s) {
      _logger.e("Error checking hasInteractions", e, s);
      return false;
    }
  }

  Future<void> seedDatabaseFromAssetIfNeeded() async {
    _logger.i("[seedDatabaseFromAssetIfNeeded] checking database state...");

    try {
      final db = await dbHelper.database;

      // Check Medicines
      bool medsExist = await hasMedicines();

      // Check Ingredients (High Risk & Food Interactions depend on this)
      final ingredientsCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM med_ingredients'),
          ) ??
          0;

      // Check Relational Interactions (Rules)
      final interactionsCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM ${DatabaseHelper.interactionsTable}',
            ),
          ) ??
          0;

      _logger.i(
        "[seedDatabaseFromAssetIfNeeded] Status: Meds=$medsExist, Ingredients=$ingredientsCount, Interactions=$interactionsCount",
      );

      // CRITICAL CHECK: If any basic building block is missing, trigger FULL seeding/repair
      if (!medsExist || ingredientsCount == 0 || interactionsCount == 0) {
        _logger.w(
          "[seedDatabaseFromAssetIfNeeded] MISSING CRITICAL DATA. Triggering REPAIR/SEEDING...",
        );
        // performInitialSeeding now handles clearing tables if needed (based on previous fix)
        await performInitialSeeding();
      } else {
        _logger.i(
          "[seedDatabaseFromAssetIfNeeded] Core data exists. Checking food_interactions...",
        );

        // Check Food Interactions
        final foodInteractionsCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseHelper.foodInteractionsTable}',
          ),
        );
        _logger.i(
          '[seedDatabaseFromAssetIfNeeded] Food interactions count: $foodInteractionsCount',
        );

        if (foodInteractionsCount == null || foodInteractionsCount == 0) {
          _logger.i(
            '[seedDatabaseFromAssetIfNeeded] Food interactions EMPTY! Seeding NOW...',
          );
          await _seedFoodInteractions(db);

          final newCount = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM ${DatabaseHelper.foodInteractionsTable}',
            ),
          );
          _logger.i(
            '[seedDatabaseFromAssetIfNeeded] After seeding: $newCount food interactions',
          );
        } else {
          _logger.i('[seedDatabaseFromAssetIfNeeded] Food interactions OK.');
        }

        markSeedingAsComplete();
      }
    } catch (e, s) {
      _logger.e(
        "[seedDatabaseFromAssetIfNeeded] ERROR during check/seed",
        e,
        s,
      );
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

    final queryStr = '''
      SELECT d.*,
        EXISTS(SELECT 1 FROM ${DatabaseHelper.foodInteractionsTable} fi WHERE fi.med_id = d.id) as has_food_interaction,
        EXISTS(
          SELECT 1 FROM med_ingredients mi 
          JOIN ${DatabaseHelper.interactionsTable} di 
          ON (mi.ingredient = di.ingredient1 OR mi.ingredient = di.ingredient2)
          WHERE mi.med_id = d.id AND LOWER(di.severity) IN ('contraindicated', 'severe', 'major', 'high')
        ) as has_drug_interaction
      FROM ${DatabaseHelper.medicinesTable} d
      WHERE LOWER(${DatabaseHelper.colActive}) = ? AND LOWER(${DatabaseHelper.colTradeName}) != ?
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(queryStr, [
      lowerCaseActive,
      lowerCaseTradeName,
    ]);

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

    final queryStr = '''
      SELECT d.*,
        EXISTS(SELECT 1 FROM ${DatabaseHelper.foodInteractionsTable} fi WHERE fi.med_id = d.id) as has_food_interaction,
        EXISTS(
          SELECT 1 FROM med_ingredients mi 
          JOIN ${DatabaseHelper.interactionsTable} di 
          ON (mi.ingredient = di.ingredient1 OR mi.ingredient = di.ingredient2)
          WHERE mi.med_id = d.id AND LOWER(di.severity) IN ('contraindicated', 'severe', 'major', 'high')
        ) as has_drug_interaction
      FROM ${DatabaseHelper.medicinesTable} d
      WHERE $whereClause
      LIMIT 50
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(queryStr, [
      ...whereArgs,
    ]);

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

  /// Finds food interactions by matching the active ingredient.
  /// Steps:
  /// 1. Find all med_ids that contain the target [ingredient].
  /// 2. Check if any of those med_ids exist in [food_interactions] table.
  /// 3. Return the interaction text.
  Future<List<String>> getFoodInteractionsForIngredient(
    String ingredient,
  ) async {
    await seedingComplete;
    if (ingredient.isEmpty) return [];

    final db = await dbHelper.database;
    final normalized = _normalizeIngredientName(ingredient);
    if (normalized.isEmpty) return [];

    // Query: Join food_interactions with med_ingredients on med_id
    // Select interaction where med_ingredients.ingredient = ?
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT DISTINCT f.interaction 
      FROM ${DatabaseHelper.foodInteractionsTable} f
      JOIN med_ingredients mi ON f.med_id = mi.med_id
      WHERE mi.ingredient = ?
      ''',
      [normalized],
    );

    return maps.map((e) => e['interaction'] as String).toList();
  }

  Future<List<MedicineModel>> getDrugsWithFoodInteractions(int limit) async {
    await seedingComplete;
    final db = await dbHelper.database;

    try {
      // Check if food_interactions table has data
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.foodInteractionsTable}',
      );
      final totalFoodInteractions = Sqflite.firstIntValue(countResult) ?? 0;
      _logger.d(
        '[getDrugsWithFoodInteractions] Total food interactions in DB: $totalFoodInteractions',
      );

      if (totalFoodInteractions == 0) {
        _logger.w(
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

      _logger.d(
        '[getDrugsWithFoodInteractions] Found ${tradeNames.length} unique trade names with food interactions',
      );

      // DEBUG: Print first 5 trade names from food_interactions
      if (tradeNames.isNotEmpty) {
        _logger.d(
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
            _logger.d(
              '[getDrugsWithFoodInteractions] Exact match failed for "$tradeName". LIKE match found: ${drugs.length}',
            );
          }
        } else {
          if (logDetail) {
            _logger.d(
              '[getDrugsWithFoodInteractions] Exact match success for "$tradeName"',
            );
          }
        }

        if (drugs.isNotEmpty) {
          matchesFound++;
          results.add(MedicineModel.fromMap(drugs.first));
        }
      }

      _logger.i(
        '[getDrugsWithFoodInteractions] Match summary: Attempts=$matchAttempts, Matches=$matchesFound',
      );
      _logger.i(
        '[getDrugsWithFoodInteractions] Successfully matched ${results.length} drugs',
      );
      return results;
    } catch (e, stackTrace) {
      _logger.e('[getDrugsWithFoodInteractions] ERROR', e, stackTrace);
      return [];
    }
  }

  // --- Interaction Methods ---

  Future<List<DrugInteractionModel>> getInteractionsForDrug(int medId) async {
    await seedingComplete;
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        r.*
      FROM med_ingredients mi
      JOIN ${DatabaseHelper.interactionsTable} r ON (r.ingredient1 = mi.ingredient OR r.ingredient2 = mi.ingredient)
      WHERE mi.med_id = ?
    ''',
      [medId],
    );

    final uniqueIds = <int>{};
    final List<DrugInteractionModel> results = [];

    for (final map in maps) {
      final id = map['id'] as int;
      if (uniqueIds.contains(id)) continue;
      uniqueIds.add(id);

      results.add(DrugInteractionModel.fromMap(map));
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
      _logger.d(
        '[getHighRiskMedicines] med_ingredients count: $ingredientsCount',
      );

      if (ingredientsCount == 0) {
        _logger.e(
          '[getHighRiskMedicines] FATAL: med_ingredients table is empty! Logic relying on ingredients will fail.',
        );
        // Debug: check text content of one medicine to see if ingredients are raw in there
        final sampleMed = await db.query(
          DatabaseHelper.medicinesTable,
          limit: 1,
        );
        if (sampleMed.isNotEmpty) {
          _logger.d(
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
      _logger.d(
        '[getHighRiskMedicines] drug_interactions count: $interactionsCount',
      );

      if (interactionsCount == 0) {
        _logger.w(
          '[getHighRiskMedicines] WARNING: No drug interactions in database!',
        );
        return [];
      }

      // Step 3: Check high-severity interactions
      final highSeverityCount = Sqflite.firstIntValue(
        await db.rawQuery(
          "SELECT COUNT(*) FROM ${DatabaseHelper.interactionsTable} WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major', 'high')",
        ),
      );
      _logger.d(
        '[getHighRiskMedicines] High-severity interactions: $highSeverityCount',
      );

      // Step 4: Run the main query
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT DISTINCT d.* 
        FROM ${DatabaseHelper.medicinesTable} d
        JOIN med_ingredients mi ON d.id = mi.med_id
        JOIN ${DatabaseHelper.interactionsTable} r ON (mi.ingredient = r.ingredient1 OR mi.ingredient = r.ingredient2)
        WHERE LOWER(r.severity) IN ('contraindicated', 'severe', 'major', 'high')
        LIMIT ?
      ''',
        [limit],
      );

      _logger.i(
        '[getHighRiskMedicines] Query returned ${maps.length} high-risk drugs',
      );

      if (maps.isNotEmpty) {
        // Sample first result
        _logger.d(
          '[getHighRiskMedicines] Sample drug: ${maps.first['tradeName']}',
        );
      }

      return List.generate(maps.length, (i) {
        return MedicineModel.fromMap(maps[i]);
      });
    } catch (e, stackTrace) {
      _logger.e('[getHighRiskMedicines] ERROR', e, stackTrace);
      return [];
    }
  }

  /// New method to get specialized ingredient high-risk metrics for Home Screen
  Future<List<Map<String, dynamic>>> getHighRiskIngredientsWithMetrics({
    int limit = 10,
  }) async {
    await seedingComplete;
    final db = await dbHelper.database;

    // Get high-risk ingredients with proper case names
    // We'll aggregate by lowercase for counting, but preserve original case for display
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      WITH AffectedIngredients AS (
        SELECT 
          ingredient1 as original_name,
          TRIM(LOWER(ingredient1)) as ingredient_key, 
          severity 
        FROM ${DatabaseHelper.interactionsTable}
        WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major', 'high', 'moderate', 'critical', 'serious')
        UNION ALL
        SELECT 
          ingredient2 as original_name,
          TRIM(LOWER(ingredient2)) as ingredient_key, 
          severity 
        FROM ${DatabaseHelper.interactionsTable}
        WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major', 'high', 'moderate', 'critical', 'serious')
      ),
      IngredientStats AS (
        SELECT 
          ingredient_key,
          COUNT(*) as totalInteractions,
          SUM(CASE WHEN LOWER(severity) IN ('contraindicated', 'severe', 'critical', 'high') THEN 1 ELSE 0 END) as severeCount,
          SUM(CASE WHEN LOWER(severity) IN ('major', 'moderate', 'serious') THEN 1 ELSE 0 END) as moderateCount,
          SUM(CASE WHEN LOWER(severity) = 'minor' THEN 1 ELSE 0 END) as minorCount,
          SUM(CASE 
            WHEN LOWER(severity) = 'contraindicated' THEN 10 
            WHEN LOWER(severity) IN ('severe', 'critical') THEN 8
            WHEN LOWER(severity) IN ('high', 'serious') THEN 7
            WHEN LOWER(severity) = 'major' THEN 5
            WHEN LOWER(severity) = 'moderate' THEN 3
            ELSE 1 
          END) as dangerScore
        FROM AffectedIngredients
        GROUP BY ingredient_key
      )
      SELECT 
        (SELECT original_name FROM AffectedIngredients ai WHERE ai.ingredient_key = stats.ingredient_key ORDER BY LENGTH(original_name) DESC LIMIT 1) as name,
        stats.totalInteractions,
        stats.severeCount,
        stats.moderateCount,
        stats.minorCount,
        stats.dangerScore
      FROM IngredientStats stats
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
      where:
          "LOWER(severity) IN ('contraindicated', 'severe', 'major', 'high')",
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      final m = maps[i];
      // Construct a generic model (med_id 0)
      return DrugInteractionModel.fromMap({
        'id': m['id'],
        'med_id': 0,
        'ingredient1': m['ingredient1'],
        'ingredient2': m['ingredient2'],
        'severity': m['severity'],
        'effect': m['effect'] ?? m['description'],
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
    final query = '%${drugName.trim().toLowerCase()}%';

    // Using rawQuery with explicit LOWER() for safety
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT * FROM ${DatabaseHelper.interactionsTable} 
      WHERE LOWER(ingredient1) LIKE ? OR LOWER(ingredient2) LIKE ?
      ''',
      [query, query],
    );

    return List.generate(maps.length, (i) {
      final m = maps[i];
      return DrugInteractionModel.fromMap({
        'id': m['id'],
        'med_id': 0,
        'ingredient1': m['ingredient1'],
        'ingredient2': m['ingredient2'],
        'severity': m['severity'],
        'effect': m['effect'] ?? m['description'],
        'source': m['source'],
      });
    });
  }

  /// Helper to normalize ingredient names for consistent matching
  String _normalizeIngredientName(String name) {
    if (name.isEmpty) return '';

    // 1. Lowercase and trim
    String processed = name.toLowerCase().trim();

    // 2. Remove parenthetical info: paracetamol(acetaminophen) -> paracetamol
    processed = processed.split('(').first.trim();

    // 3. Remove common pharmaceutical salt/form suffixes if they are separate words
    final suffixesToRemove = [
      ' tablets',
      ' tablet',
      ' capsule',
      ' capsules',
      ' hydrochloride',
      ' hcl',
      ' sodium',
      ' potassium',
      ' phosphate',
      ' sulfate',
      ' acetate',
      ' fumarate',
      ' suspension',
      ' oral solution',
      ' injection',
    ];

    for (final suffix in suffixesToRemove) {
      if (processed.endsWith(suffix)) {
        processed =
            processed.substring(0, processed.length - suffix.length).trim();
      }
    }

    return processed;
  }

  Future<List<Map<String, dynamic>>> getFoodInteractionCounts() async {
    await seedingComplete;
    final db = await dbHelper.database;

    // We need to link food interactions back to ingredients
    // food_interactions has med_id. med_ingredients has med_id and ingredient.
    // We want to count how many food interactions exist for each ingredient.

    /*
      food_interactions:
      med_id | interaction
      1      | No alcohol
      
      med_ingredients:
      med_id | ingredient
      1      | Paracetamol
      
      Result: Paracetamol -> 1
    */

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        LOWER(mi.ingredient) as name, 
        COUNT(DISTINCT fi.interaction) as count
      FROM ${DatabaseHelper.foodInteractionsTable} fi
      JOIN med_ingredients mi ON fi.med_id = mi.med_id
      GROUP BY LOWER(mi.ingredient)
      ORDER BY count DESC
      LIMIT 20
      ''');

    return maps;
  }

  Future<List<int>> getNewestDrugIds(int limit) async {
    await seedingComplete;
    final db = await dbHelper.database;

    // Sort by ID descending to get the newest drugs added
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      columns: [DatabaseHelper.colId],
      orderBy: '${DatabaseHelper.colId} DESC',
      limit: limit,
    );

    return maps.map((map) => map[DatabaseHelper.colId] as int).toList();
  }

  /// Increments the visits count for a specific drug.
  Future<void> incrementVisits(int drugId) async {
    final db = await dbHelper.database;
    await db.rawUpdate(
      'UPDATE ${DatabaseHelper.medicinesTable} SET ${DatabaseHelper.colVisits} = ${DatabaseHelper.colVisits} + 1 WHERE ${DatabaseHelper.colId} = ?',
      [drugId],
    );
  }

  /// Get the total count of interaction rules in the database.
  Future<int> getInteractionsCount() async {
    await seedingComplete;
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.interactionsTable}',
      ),
    );
    return count ?? 0;
  }
}
