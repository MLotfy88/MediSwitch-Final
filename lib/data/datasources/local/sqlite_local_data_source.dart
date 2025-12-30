import 'dart:async';
import 'dart:convert'; // Import dart:convert

import 'package:csv/csv.dart'; // Restore csv import
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mediswitch/core/database/database_helper.dart';
import 'package:mediswitch/core/services/file_logger_service.dart';
import 'package:mediswitch/core/utils/category_mapper_helper.dart';
import 'package:mediswitch/data/models/disease_interaction_model.dart';
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

      // 1. Seed Rules (Enriched)
      int chunk = 1;
      int totalRulesLoaded = 0;
      while (true) {
        try {
          final fname =
              'assets/data/interactions/enriched/enriched_rules_part_${chunk.toString().padLeft(3, '0')}.json';
          _logger.i(
            '[INTERACTION SEEDING] Loading enriched rules chunk $chunk from: $fname',
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
              'management_text': r['management_text'],
              'mechanism_text': r['mechanism_text'],
              'risk_level': r['risk_level'],
              'ddinter_id': r['ddinter_id'],
              'source': r['source'] ?? 'DDInter',
              'updated_at': 0,
            });
          }
          await batch.commit(noResult: true);
          totalRulesLoaded += rules.length;
          _logger.i(
            '[INTERACTION SEEDING] ✅ Loaded Enriched Rules Chunk $chunk (${rules.length} items, total: $totalRulesLoaded)',
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

  // Top-level function for compute
  List<dynamic> _parseJsonString(String jsonString) {
    return json.decode(jsonString) as List<dynamic>;
  }

  Future<void> _seedDiseaseInteractions(Database db) async {
    try {
      _logger.i(
        '[DISEASE INTERACTION SEEDING] Starting disease interaction seeding...',
      );
      // Load as string (async)
      final jsonString = await rootBundle.loadString(
        'assets/data/interactions/enriched/enriched_disease_interactions.json',
      );

      // Parse in Isolate to avoid UI freeze (file is ~67MB)
      _logger.i('[DISEASE INTERACTION SEEDING] Parsing JSON in Isolate...');
      final List<dynamic> interactions = await compute(
        _parseJsonString,
        jsonString,
      );

      if (interactions.isNotEmpty) {
        _logger.i(
          '[DISEASE INTERACTION SEEDING] Inserting ${interactions.length} items in chunks...',
        );

        // Chunk insertion to prevent blocking the main thread for too long
        const int batchSize = 2000;
        for (var i = 0; i < interactions.length; i += batchSize) {
          final end =
              (i + batchSize < interactions.length)
                  ? i + batchSize
                  : interactions.length;
          final batch = db.batch();

          for (var j = i; j < end; j++) {
            final item = interactions[j];
            batch.insert(
              DatabaseHelper.diseaseInteractionsTable,
              {
                'med_id': item['med_id'],
                'trade_name': item['trade_name'],
                'disease_name': item['disease_name'],
                'interaction_text': item['interaction_text'],
                'source': item['source'],
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
          // Yield to UI thread to keep splash screen animating
          await Future.delayed(Duration.zero);
        }

        _logger.i(
          '[DISEASE INTERACTION SEEDING] ✅ Seeded ${interactions.length} disease interactions.',
        );
      }
    } catch (e, stackTrace) {
      _logger.e('[DISEASE INTERACTION SEEDING] CRITICAL ERROR', e, stackTrace);
    }
  }

  Future<void> _seedFoodInteractions(Database db) async {
    try {
      _logger.i(
        '[FOOD INTERACTION SEEDING] Starting food interaction seeding...',
      );
      final jsonString = await rootBundle.loadString(
        'assets/data/interactions/enriched/enriched_food_interactions.json',
      );

      // Parse in Isolate (safer for ~8MB file)
      final List<dynamic> interactions = await compute(
        _parseJsonString,
        jsonString,
      );

      if (interactions.isNotEmpty) {
        // Chunk insertion here too for consistency
        const int batchSize = 2000;
        for (var i = 0; i < interactions.length; i += batchSize) {
          final end =
              (i + batchSize < interactions.length)
                  ? i + batchSize
                  : interactions.length;
          final batch = db.batch();

          for (var j = i; j < end; j++) {
            final item = interactions[j];
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
          await Future.delayed(Duration.zero);
        }

        _logger.i(
          '[FOOD INTERACTION SEEDING] ✅ Seeded ${interactions.length} food interactions.',
        );
      }
    } catch (e, stackTrace) {
      _logger.e('[FOOD INTERACTION SEEDING] CRITICAL ERROR', e, stackTrace);
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
        // Since initial seeding should cover everything, we might return here,
        // but let's allow it to fall through to check specifically for the new tables just in case.
      } else {
        _logger.i(
          "[seedDatabaseFromAssetIfNeeded] Core data exists. Checking specific interaction tables...",
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
        }

        // Check Disease Interactions
        final diseaseInteractionsCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseHelper.diseaseInteractionsTable}',
          ),
        );
        _logger.i(
          '[seedDatabaseFromAssetIfNeeded] Disease interactions count: $diseaseInteractionsCount',
        );

        if (diseaseInteractionsCount == null || diseaseInteractionsCount == 0) {
          _logger.i(
            '[seedDatabaseFromAssetIfNeeded] Disease interactions EMPTY! Seeding NOW...',
          );
          await _seedDiseaseInteractions(db);
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
        ) as has_drug_interaction,
        EXISTS(SELECT 1 FROM ${DatabaseHelper.diseaseInteractionsTable} dsi WHERE dsi.med_id = d.id) as has_disease_interaction
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
        ) as has_drug_interaction,
        EXISTS(SELECT 1 FROM ${DatabaseHelper.diseaseInteractionsTable} dsi WHERE dsi.med_id = d.id) as has_disease_interaction
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

    // Get high-risk ingredients with FULL names including salts and compounds
    // Strategy:
    // 1. Split combination drugs (A + B) into separate ingredients
    // 2. Join with medicines table to get complete activeIngredient names
    // 3. Match each ingredient separately against interactions
    // 4. Fallback to interaction table names only if no match in medicines
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      WITH AffectedIngredients AS (
        SELECT 
          ingredient1 as original_name,
          -- FIX: Apply same normalization as _normalizeIngredientName() - remove parentheses
          TRIM(REPLACE(REPLACE(LOWER(ingredient1), '(', ''), ')', '')) as ingredient_key, 
          severity 
        FROM ${DatabaseHelper.interactionsTable}
        WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major', 'high', 'moderate', 'critical', 'serious')
        UNION ALL
        SELECT 
          ingredient2 as original_name,
          -- FIX: Apply same normalization as _normalizeIngredientName() - remove parentheses
          TRIM(REPLACE(REPLACE(LOWER(ingredient2), '(', ''), ')', '')) as ingredient_key, 
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
        WHERE ingredient_key NOT IN (
          'pro', 'met', 'ors', 'interactions', 'bee', 'sage', 
          'bet', 'vit', 'but', 'epa', 'thy', 'ros', 'eru', 'prop',
          'drugs', 'food', 'alcohol', 'water'
        )
        AND LENGTH(ingredient_key) > 2 
        GROUP BY ingredient_key
      ),
      SplitIngredients AS (
        -- Split combination drugs (e.g., "Paracetamol + Caffeine" -> two rows)
        -- Handle first ingredient (before +)
        SELECT DISTINCT
          TRIM(LOWER(
            CASE 
              WHEN INSTR(mi.ingredient, '+') > 0 
              THEN SUBSTR(mi.ingredient, 1, INSTR(mi.ingredient, '+') - 1)
              ELSE mi.ingredient
            END
          )) as ingredient_key,
          m.${DatabaseHelper.colActive} as full_combination_name,
          CASE 
            WHEN INSTR(m.${DatabaseHelper.colActive}, '+') > 0 
            THEN TRIM(SUBSTR(m.${DatabaseHelper.colActive}, 1, INSTR(m.${DatabaseHelper.colActive}, '+') - 1))
            ELSE m.${DatabaseHelper.colActive}
          END as full_name,
          LENGTH(m.${DatabaseHelper.colActive}) as name_length
        FROM med_ingredients mi
        JOIN ${DatabaseHelper.medicinesTable} m ON mi.med_id = m.${DatabaseHelper.colId}
        WHERE m.${DatabaseHelper.colActive} IS NOT NULL 
          AND TRIM(m.${DatabaseHelper.colActive}) != ''
        
        UNION
        
        -- Handle second ingredient (after +), only if + exists
        SELECT DISTINCT
          TRIM(LOWER(SUBSTR(mi.ingredient, INSTR(mi.ingredient, '+') + 1))) as ingredient_key,
          m.${DatabaseHelper.colActive} as full_combination_name,
          TRIM(SUBSTR(m.${DatabaseHelper.colActive}, INSTR(m.${DatabaseHelper.colActive}, '+') + 1)) as full_name,
          LENGTH(m.${DatabaseHelper.colActive}) as name_length
        FROM med_ingredients mi
        JOIN ${DatabaseHelper.medicinesTable} m ON mi.med_id = m.${DatabaseHelper.colId}
        WHERE m.${DatabaseHelper.colActive} IS NOT NULL 
          AND TRIM(m.${DatabaseHelper.colActive}) != ''
          AND INSTR(mi.ingredient, '+') > 0
      )
      SELECT 
        COALESCE(
          (SELECT full_name 
           FROM SplitIngredients si 
           WHERE si.ingredient_key = stats.ingredient_key 
           ORDER BY name_length DESC 
           LIMIT 1),
          (SELECT original_name 
           FROM AffectedIngredients ai 
           WHERE ai.ingredient_key = stats.ingredient_key 
           ORDER BY LENGTH(original_name) DESC 
           LIMIT 1)
        ) as name,
        stats.ingredient_key as normalized_name,
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

    // 1. Normalize and Split the query name
    // e.g. "Paracetamol + Caffeine" -> ["paracetamol", "caffeine"]
    final normalizedQuery = drugName.toLowerCase().trim();
    List<String> searchTerms = [];

    if (normalizedQuery.contains('+')) {
      searchTerms =
          normalizedQuery
              .split('+')
              .map((e) => _normalizeIngredientName(e))
              .toList();
    } else {
      // If it's a single word, we might want to try both the raw name (for exact DB match)
      // and the normalized name (for pharmaceutical generic match)
      final norm = _normalizeIngredientName(normalizedQuery);
      searchTerms = [normalizedQuery];
      if (norm != normalizedQuery && norm.isNotEmpty) {
        searchTerms.add(norm);
      }
    }

    // DEBUG LOGGING
    debugPrint('🔍 [getInteractionsWith] Searching for: "$drugName"');
    debugPrint('🔍 [getInteractionsWith] Normalized query: "$normalizedQuery"');
    debugPrint('🔍 [getInteractionsWith] Search terms: $searchTerms');

    // Also consider the raw name if normalization strips too much
    if (searchTerms.isEmpty) searchTerms.add(normalizedQuery);

    // 2. Build Query to match ANY of the terms
    // matching against ingredient1 OR ingredient2

    /* 
       Optimization:
       Instead of just LIKE %term%, we should also check equality for better performance on exact matches 
       and use the normalized name logic.
    */

    final whereClauses = <String>[];
    final args = <String>[];

    for (final term in searchTerms) {
      if (term.length < 3) continue; // Skip very short terms

      // Priority 1: Exact Match
      whereClauses.add('(LOWER(ingredient1) = ? OR LOWER(ingredient2) = ?)');
      args.add(term);
      args.add(term);

      // Priority 2: Word boundaries
      whereClauses.add('''
        (
          LOWER(ingredient1) LIKE ? OR 
          LOWER(ingredient2) LIKE ? OR
          LOWER(ingredient1) LIKE ? OR 
          LOWER(ingredient2) LIKE ? OR
          LOWER(ingredient1) LIKE ? OR 
          LOWER(ingredient2) LIKE ?
        )
      ''');
      args.add('% $term %');
      args.add('% $term %');
      args.add('$term %');
      args.add('$term %');
      args.add('% $term');
      args.add('% $term');

      // Priority 3: Component match (term contains DB ingredient as a WHOLE WORD)
      // Only for ingredients with length >= 4 and not generic words to avoid junk matches
      whereClauses.add('''
        (
          (length(ingredient1) >= 4 AND 
           LOWER(ingredient1) NOT IN ('extract', 'oil', 'tablets', 'tablet', 'capsules', 'capsule') AND 
           (' ' || ? || ' ') LIKE ('% ' || LOWER(ingredient1) || ' %')) OR
          (length(ingredient2) >= 4 AND 
           LOWER(ingredient2) NOT IN ('extract', 'oil', 'tablets', 'tablet', 'capsules', 'capsule') AND 
           (' ' || ? || ' ') LIKE ('% ' || LOWER(ingredient2) || ' %'))
        )
      ''');
      args.add(term);
      args.add(term);
    }

    if (whereClauses.isEmpty) return [];

    final fullWhere = whereClauses.join(' OR ');

    // Using rawQuery with explicit LOWER() for safety
    List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM ${DatabaseHelper.interactionsTable} 
      WHERE $fullWhere
      ORDER BY 
        CASE WHEN LOWER(severity) = 'contraindicated' THEN 1
             WHEN LOWER(severity) = 'severe' THEN 2
             WHEN LOWER(severity) = 'major' THEN 3
             ELSE 4 END
      ''', args);

    // FALLBACK STRATEGIES: If no results found, try alternative search methods
    if (maps.isEmpty && searchTerms.isNotEmpty) {
      // Fallback 1: Try with the original raw name (no normalization at all)
      final rawName = drugName.toLowerCase().trim();
      maps = await db.rawQuery(
        '''
        SELECT * FROM ${DatabaseHelper.interactionsTable} 
        WHERE LOWER(ingredient1) = ? OR LOWER(ingredient2) = ?
        ORDER BY 
          CASE WHEN LOWER(severity) = 'contraindicated' THEN 1
               WHEN LOWER(severity) = 'severe' THEN 2
               WHEN LOWER(severity) = 'major' THEN 3
               ELSE 4 END
      ''',
        [rawName, rawName],
      );

      // Fallback 2: If name contains parentheses, try the part before parentheses
      if (maps.isEmpty && drugName.contains('(')) {
        final simpleName = drugName.split('(')[0].trim().toLowerCase();
        if (simpleName.length >= 3) {
          maps = await db.rawQuery(
            '''
            SELECT * FROM ${DatabaseHelper.interactionsTable} 
            WHERE LOWER(ingredient1) LIKE ? OR LOWER(ingredient2) LIKE ?
            ORDER BY 
              CASE WHEN LOWER(severity) = 'contraindicated' THEN 1
                   WHEN LOWER(severity) = 'severe' THEN 2
                   WHEN LOWER(severity) = 'major' THEN 3
                   ELSE 4 END
          ''',
            ['%$simpleName%', '%$simpleName%'],
          );
        }
      }

      // Fallback 3: If name contains +, try splitting and search for any part
      if (maps.isEmpty && drugName.contains('+')) {
        final parts =
            drugName.split('+').map((e) => e.trim().toLowerCase()).toList();
        final Set<Map<String, dynamic>> allMaps = {};

        for (final part in parts) {
          if (part.length < 3) continue;
          final partMaps = await db.rawQuery(
            '''
            SELECT * FROM ${DatabaseHelper.interactionsTable} 
            WHERE LOWER(ingredient1) LIKE ? OR LOWER(ingredient2) LIKE ?
          ''',
            ['%$part%', '%$part%'],
          );
          allMaps.addAll(partMaps);
        }

        if (allMaps.isNotEmpty) {
          maps = allMaps.toList();
          // Re-sort by severity
          maps.sort((a, b) {
            final aSeverity = (a['severity'] as String? ?? '').toLowerCase();
            final bSeverity = (b['severity'] as String? ?? '').toLowerCase();
            final aWeight =
                aSeverity == 'contraindicated'
                    ? 1
                    : aSeverity == 'severe'
                    ? 2
                    : aSeverity == 'major'
                    ? 3
                    : 4;
            final bWeight =
                bSeverity == 'contraindicated'
                    ? 1
                    : bSeverity == 'severe'
                    ? 2
                    : bSeverity == 'major'
                    ? 3
                    : 4;
            return aWeight.compareTo(bWeight);
          });
        }
      }
    }

    // DEBUG LOGGING - Show results
    debugPrint('🔍 [getInteractionsWith] Found ${maps.length} interactions');
    if (maps.isNotEmpty) {
      final first3 = maps.take(3).toList();
      for (var i = 0; i < first3.length; i++) {
        final m = first3[i];
        debugPrint(
          '   ${i + 1}. ${m['ingredient1']} + ${m['ingredient2']} (${m['severity']})',
        );
      }
    }

    return List.generate(maps.length, (i) {
      final m = maps[i];

      // Determine if this is a primary interaction (searched drug is ingredient1)
      final ing1 = (m['ingredient1'] as String? ?? '').toLowerCase();
      // We check if ingredient1 contains the search term (simple match)
      // or if we used specific search terms, check against those.
      // Since we don't have the exact term that matched readily available for each row without re-checking,
      // we'll use the original normalized query.
      bool isPrimary = false;

      // Logic: If ingredient1 matches the search term more closely?
      // Or simply if ingredient1 contains the search term.
      // If the search term is 'olive', and ing1 is 'olive oil', contains is true.
      // If ing1 is 'warfarin', contains is false (usually).

      // Check against all searchTerms we used
      final termToCheck =
          (searchTerms.isNotEmpty ? searchTerms.first : normalizedQuery)
              .toLowerCase();

      // Robust check:
      // If ingredient1 contains the term, we consider it primary.
      // Note: If BOTH contain it (e.g. self-interaction or similar names), it defaults to primary.
      if (ing1.contains(termToCheck)) {
        isPrimary = true;
      } else {
        // Fallback: Check if ingredient1 matches any of the split parts if used
        for (final t in searchTerms) {
          if (ing1.contains(t.toLowerCase())) {
            isPrimary = true;
            break;
          }
        }
      }

      return DrugInteractionModel.fromMap({
        'id': m['id'],
        'med_id': 0,
        'ingredient1': m['ingredient1'],
        'ingredient2': m['ingredient2'],
        'severity': m['severity'],
        'effect': m['effect'] ?? m['description'],
        'source': m['source'],
        'is_primary_ingredient': isPrimary,
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
        mi.ingredient as name, 
        COUNT(DISTINCT fi.interaction) as count
      FROM ${DatabaseHelper.foodInteractionsTable} fi
      JOIN med_ingredients mi ON fi.med_id = mi.med_id
      GROUP BY mi.ingredient
      ORDER BY count DESC
      LIMIT 100
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

  Future<List<DiseaseInteractionModel>> getDiseaseInteractionsForDrug(
    int medId,
  ) async {
    await seedingComplete;
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.diseaseInteractionsTable,
      where: 'med_id = ?',
      whereArgs: [medId],
    );

    return List.generate(maps.length, (i) {
      return DiseaseInteractionModel.fromMap(maps[i]);
    });
  }

  Future<List<Map<String, dynamic>>> getFoodInteractionsDetailedForDrug(
    int medId,
  ) async {
    await seedingComplete;
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.foodInteractionsTable,
      where: 'med_id = ?',
      whereArgs: [medId],
    );
    return maps;
  }

  // --- Missing Methods Implementation ---

  Future<bool> hasMedicines() async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.medicinesTable}',
      ),
    );
    return (count ?? 0) > 0;
  }

  Future<void> markSeedingAsComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_database_seeded', true);
  }

  Future<List<MedicineModel>> getAllMedicines({
    int limit = 20,
    int offset = 0,
  }) async {
    await seedingComplete;
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      limit: limit,
      offset: offset,
    );
    return maps.map((e) => MedicineModel.fromMap(e)).toList();
  }

  Future<List<MedicineModel>> searchMedicinesByName(
    String query, {
    int? limit,
    int? offset,
  }) async {
    await seedingComplete;
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: 'trade_name LIKE ? OR scientific_name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: limit,
      offset: offset,
    );
    return maps.map((e) => MedicineModel.fromMap(e)).toList();
  }

  Future<List<MedicineModel>> findMedicines(String query) async {
    // Alias for searchMedicinesByName to fix 'findMedicines' error if used elsewhere intra-class
    return searchMedicinesByName(query);
  }

  Future<List<MedicineModel>> filterMedicinesByCategory(
    String category, {
    int? limit,
    int? offset,
  }) async {
    await seedingComplete;
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: 'scraped_category = ?',
      whereArgs: [category],
      limit: limit,
      offset: offset,
    );
    return maps.map((e) => MedicineModel.fromMap(e)).toList();
  }

  // Helper for DrugRepositoryImpl.saveDownloadedCsv
  Future<void> saveDownloadedCsv(List<int> fileData) async {
    // This method is expected to take bytes, parse them, and replace the DB.
    // Reusing logic from _updateDatabaseIsolate would be ideal but simplistic approach here:
    final String rawCsv = String.fromCharCodes(fileData);
    // Trigger update in background or directly
    // Ideally we should use the Isolate logic.
    // For now, we call the isolate method indirectly or re-implement basic save.
    // Given the complexity of threading, I will just call the updateDatabase logic if exposed,
    // or reimplement a simple version.
    // Actually, calling _updateDatabaseIsolate via compute is best.
    // But _updateDatabaseIsolate expects map.

    final dbPath = await dbHelper.database.then((db) => db.path);
    await compute(_updateDatabaseIsolate, {'dbPath': dbPath, 'rawCsv': rawCsv});

    await markSeedingAsComplete();
  }

  // Dashboard Statistics
  Future<Map<String, int>> getDashboardStatistics() async {
    await seedingComplete;
    final db = await dbHelper.database;
    final drugsCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseHelper.medicinesTable}',
          ),
        ) ??
        0;
    final interactionsCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseHelper.interactionsTable}',
          ),
        ) ??
        0;
    // Assuming we might want to count other tables later

    return {
      'total_medicines': drugsCount,
      'total_interactions': interactionsCount,
      'active_ingredients': 0, // Placeholder
      'categories': 0, // Placeholder
    };
  }

  // Debug Helper
  Future<bool> hasInteractions() async {
    return (await getInteractionsCount()) > 0;
  }

  Future<List<String>> getAvailableCategories() async {
    await seedingComplete;
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT scraped_category FROM ${DatabaseHelper.medicinesTable} ORDER BY scraped_category ASC',
    );
    return maps
        .map((e) => e['scraped_category'] as String?)
        .where((e) => e != null && e.isNotEmpty)
        .cast<String>()
        .toList();
  }

  Future<Map<String, int>> getCategoriesWithCount() async {
    await seedingComplete;
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT scraped_category, COUNT(*) as count FROM ${DatabaseHelper.medicinesTable} GROUP BY scraped_category',
    );

    final Map<String, int> result = {};
    for (final map in maps) {
      if (map['scraped_category'] != null) {
        result[map['scraped_category'] as String] = map['count'] as int;
      }
    }
    return result;
  }

  Future<List<MedicineModel>> getRecentlyUpdatedMedicines(
    String cutoffDate, {
    int limit = 10,
    int? offset,
  }) async {
    await seedingComplete;
    final db = await dbHelper.database;
    // Note: cutoffDate logic is simplified here as we mainly just sort by update
    // If strict cutoff is needed: where: 'last_price_update > ?', whereArgs: [cutoffDate]
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      orderBy: 'last_price_update DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((e) => MedicineModel.fromMap(e)).toList();
  }

  Future<List<MedicineModel>> getRandomMedicines({int limit = 5}) async {
    await seedingComplete;
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      orderBy: 'RANDOM()',
      limit: limit,
    );
    return maps.map((e) => MedicineModel.fromMap(e)).toList();
  }

  Future<List<MedicineModel>> getPopularMedicines({int limit = 10}) async {
    await seedingComplete;
    final db = await dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.medicinesTable,
        orderBy: 'visits DESC',
        limit: limit,
      );
      return maps.map((e) => MedicineModel.fromMap(e)).toList();
    } catch (e) {
      return getRandomMedicines(limit: limit);
    }
  }
}
