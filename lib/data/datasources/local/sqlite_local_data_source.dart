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
List<MedicineModel> _parseMedicines(String csv) {
  final List<List<dynamic>> csvTable = const CsvToListConverter(
    fieldDelimiter: ',',
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(csv);
  if (csvTable.isNotEmpty) csvTable.removeAt(0);
  return csvTable.map((row) => MedicineModel.fromCsv(row)).toList();
}

List<MedicineModel> _parseCsvData(String rawCsv) {
  return _parseMedicines(rawCsv);
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
  final FileLoggerService _logger;

  // Keep the completer to signal when seeding (if performed) is done.
  Future<void> get seedingComplete => _seedingCompleter.future;
  bool get isSeedingCompleted => _seedingCompleter.isCompleted;

  SqliteLocalDataSource({required this.dbHelper, FileLoggerService? logger})
    : _logger = logger ?? FileLoggerService();

  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // --- Core Logic ---

  Future<int?> getLastUpdateTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_prefsKeyLastUpdate);
    return timestamp ?? _initialDataTimestamp;
  }

  Future<String?> getHomeCache(String key) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.homeCacheTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['data'] as String?;
    }
    return null;
  }

  Future<void> saveHomeCache(String key, String data) async {
    final db = await dbHelper.database;
    await db.insert(DatabaseHelper.homeCacheTable, {
      'key': key,
      'data': data,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Recalculates interaction flags - Optimized for NOCASE
  Future<void> recalculateInteractionFlags() async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      _logger.i('Starting interaction flags recalculation...');

      await txn.execute('''
        UPDATE ${DatabaseHelper.medicinesTable} 
        SET has_drug_interaction = 0, 
            has_food_interaction = 0, 
            has_disease_interaction = 0
      ''');

      // Optimized joins using NOCASE (removed LOWER)
      await txn.execute('''
        UPDATE ${DatabaseHelper.medicinesTable}
        SET has_drug_interaction = 1
        WHERE id IN (
          SELECT DISTINCT mi.med_id
          FROM med_ingredients mi
          JOIN ${DatabaseHelper.interactionsTable} ri 
          ON (mi.ingredient = ri.ingredient1 OR mi.ingredient = ri.ingredient2)
        )
      ''');

      await txn.execute('''
        UPDATE ${DatabaseHelper.medicinesTable}
        SET has_food_interaction = 1
        WHERE id IN (SELECT med_id FROM ${DatabaseHelper.foodInteractionsTable})
        OR id IN (
          SELECT DISTINCT mi.med_id
          FROM med_ingredients mi
          JOIN ${DatabaseHelper.foodInteractionsTable} fi
          ON mi.ingredient = fi.trade_name
        )
      ''');

      await txn.execute('''
        UPDATE ${DatabaseHelper.medicinesTable}
        SET has_disease_interaction = 1
        WHERE id IN (SELECT med_id FROM ${DatabaseHelper.diseaseInteractionsTable})
      ''');

      _logger.i('Interaction flags recalculation completed.');
    });
  }

  Future<void> ensureDatabaseInitialized() async {
    if (_seedingCompleter.isCompleted) return;

    try {
      final db = await dbHelper.database;
      final medsCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM ${DatabaseHelper.medicinesTable}',
            ),
          ) ??
          0;

      if (medsCount == 0) {
        _logger.i(
          '[ensureDatabaseInitialized] Database empty, performing initial seeding...',
        );
        await performInitialSeeding();
      } else {
        _logger.i(
          '[ensureDatabaseInitialized] Core data exists, checking maintenance...',
        );
        // Ensure seeding logic is complete
        try {
          await _seedDosageGuidelines(db); // Always check dosages
          await _checkAndSeedInteractions(db); // Always check interactions
        } catch (_) {}

        if (!_seedingCompleter.isCompleted) _seedingCompleter.complete();
      }
    } catch (e, s) {
      _logger.e(
        '[ensureDatabaseInitialized] Critical failure during initialization',
        e,
        s,
      );
      if (!_seedingCompleter.isCompleted) {
        _seedingCompleter.completeError(e);
      }
    } finally {
      if (!_seedingCompleter.isCompleted) {
        _seedingCompleter.complete();
      }
    }
  }

  // Dummy method for unused call
  Future<void> seedDatabaseFromAssetIfNeeded() async {}

  // Performs initial seeding from the asset file.

  static List<Map<String, dynamic>> _prepareIngredients(
    Map<String, dynamic> args,
  ) {
    final List<MedicineModel> medicines =
        (args['medicines'] as List).cast<MedicineModel>();
    final String ingredientsJson = args['ingredientsJson'] as String;

    Map<String, dynamic> ingredientsMap = {};
    if (ingredientsJson.isNotEmpty) {
      try {
        ingredientsMap = json.decode(ingredientsJson) as Map<String, dynamic>;
      } catch (e) {
        print('Error decoding ingredients JSON in isolate: $e');
      }
    }

    final List<Map<String, dynamic>> allIngredients = [];

    for (final med in medicines) {
      if (med.id == null || med.id == 0) continue;

      List<String> ingredients = [];
      if (ingredientsMap.containsKey(med.tradeName)) {
        final dynamic mapped = ingredientsMap[med.tradeName];
        if (mapped is List) {
          ingredients =
              mapped.map((e) => e.toString().trim().toLowerCase()).toList();
        }
      }

      if (ingredients.isEmpty && med.active.isNotEmpty) {
        ingredients = _parseIngredients(med.active);
      }

      for (final ing in ingredients) {
        // Use normalized lowercase for consistency even with NOCASE, safest
        allIngredients.add({'med_id': med.id, 'ingredient': ing});
      }
    }
    return allIngredients;
  }

  Future<bool> performInitialSeeding() async {
    if (_seedingCompleter.isCompleted) return false;

    _logger.i('🚀 Performing OPTIMIZED initial database seeding...');
    final stopwatch = Stopwatch()..start();
    Database? db;
    bool success = false;

    try {
      db = await dbHelper.database;
      final medsExist = await hasMedicines();
      final ingredientsCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM med_ingredients'),
          ) ??
          0;

      if (!medsExist || ingredientsCount == 0) {
        if (medsExist) {
          await db.delete('med_ingredients');
          await db.delete(DatabaseHelper.medicinesTable);
        }

        _logger.i('Loading assets...');
        final rawCsv = await rootBundle.loadString('assets/meds.csv');
        String ingredientsJson = '';
        try {
          ingredientsJson = await rootBundle.loadString(
            'assets/data/medicine_ingredients.json',
          );
        } catch (_) {}

        _logger.i('Parsing CSV in Isolate...');
        final medicines = await compute(_parseMedicines, rawCsv);

        _logger.i('Preparing ingredients in Isolate...');
        final ingredients = await compute(_prepareIngredients, {
          'medicines': medicines,
          'ingredientsJson': ingredientsJson,
        });

        await _batchCommitChunked(db, medicines, ingredients);
      }

      await _seedDosageGuidelines(db);
      await _checkAndSeedInteractions(db);

      final prefs = await _prefs;
      await prefs.setInt(
        _prefsKeyLastUpdate,
        DateTime.now().millisecondsSinceEpoch,
      );

      stopwatch.stop();
      _logger.i(
        '✅ Database seeding finished in ${stopwatch.elapsedMilliseconds}ms.',
      );
      success = true;
      if (!_seedingCompleter.isCompleted) _seedingCompleter.complete();
    } catch (e, s) {
      _logger.e('❌ Seeding failed', e, s);
      if (!_seedingCompleter.isCompleted) _seedingCompleter.completeError(e);
    }

    return success;
  }

  Future<void> _batchCommitChunked(
    Database db,
    List<MedicineModel> meds,
    List<Map<String, dynamic>> ings,
  ) async {
    const int batchSize = 2000;

    if (meds.isNotEmpty) {
      _logger.i('Inserting ${meds.length} medicines...');
      for (var i = 0; i < meds.length; i += batchSize) {
        final end = (i + batchSize < meds.length) ? i + batchSize : meds.length;
        final batch = db.batch();
        for (var j = i; j < end; j++) {
          batch.insert(
            DatabaseHelper.medicinesTable,
            meds[j].toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        await Future<void>.delayed(Duration.zero);
      }
    }

    if (ings.isNotEmpty) {
      _logger.i('Inserting ${ings.length} ingredient links...');
      for (var i = 0; i < ings.length; i += batchSize) {
        final end = (i + batchSize < ings.length) ? i + batchSize : ings.length;
        final batch = db.batch();
        for (var j = i; j < end; j++) {
          batch.insert(
            'med_ingredients',
            ings[j],
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  Future<void> _seedDosageGuidelines(Database db) async {
    try {
      _logger.i('[DOSAGE SEEDING] Checking/Seeding dosages...');
      // Verify table exists first (it should with v19)
      final count =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM sqlite_master WHERE type="table" AND name="${DatabaseHelper.dosageTable}"',
            ),
          ) ??
          0;

      if (count == 0) {
        _logger.e(
          '[DOSAGE SEEDING] Table MISSING implies schema update failed.',
        );
        return;
      }

      final dbCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM ${DatabaseHelper.dosageTable}',
            ),
          ) ??
          0;
      if (dbCount > 0) {
        _logger.i('[DOSAGE SEEDING] Already seeded ($dbCount entries).');
        return;
      }

      final dosageJson = await rootBundle.loadString(
        'assets/data/dosage_guidelines.json',
      );
      final List<dynamic> dosageList = json.decode(dosageJson) as List<dynamic>;
      if (dosageList.isNotEmpty) {
        final batch = db.batch();
        for (final item in dosageList) {
          batch.insert(
            DatabaseHelper.dosageTable, // Correct Table Name
            DosageGuidelinesModel.fromJson(
              item as Map<String, dynamic>,
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        _logger.i('[DOSAGE SEEDING] Seeded ${dosageList.length} dosages.');
      }
    } catch (e) {
      _logger.w('Dosage guidelines seeding skipped/failed: $e');
    }
  }

  // Gets dosage guidelines for a specific medicine
  Future<List<DosageGuidelinesModel>> getDosageGuidelines(int medId) async {
    await seedingComplete;
    final db = await dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.dosageTable,
        where: 'med_id = ?',
        whereArgs: [medId],
      );
      return maps.map((e) => DosageGuidelinesModel.fromMap(e)).toList();
    } catch (e) {
      _logger.e('Error fetching dosage guidelines', e);
      return [];
    }
  }

  Future<void> _checkAndSeedInteractions(Database db) async {
    _logger.i(
      '[INTERACTION SEEDING] Hybrid Mode: Skipping large offline assets seeding.',
    );
  }

  Future<void> _seedRelationalInteractions(Database db) async {}
  static List<dynamic> _parseJsonString(String jsonString) {
    return json.decode(jsonString) as List<dynamic>;
  }

  Future<void> _seedDiseaseInteractions(Database db) async {}
  Future<void> _seedFoodInteractions(Database db) async {}

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

    // Optimized Query: Removed LOWER(), relies on NOCASE
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
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT d.* 
        FROM ${DatabaseHelper.medicinesTable} d
        JOIN ${DatabaseHelper.foodInteractionsTable} fi ON d.id = fi.med_id
        GROUP BY d.id
        LIMIT ?
      ''',
        [limit],
      );
      return maps.map((m) => MedicineModel.fromMap(m)).toList();
    } catch (e, stackTrace) {
      _logger.e('[getDrugsWithFoodInteractions] ERROR', e, stackTrace);
      return [];
    }
  }

  // --- Interaction Methods ---

  Future<List<DrugInteractionModel>> getInteractionsForDrug(int medId) async {
    await seedingComplete;
    final db = await dbHelper.database;

    // Optimized Query: Removed LOWER()
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT r.*
      FROM med_ingredients mi
      JOIN ${DatabaseHelper.interactionsTable} r 
      ON (r.ingredient1 = mi.ingredient OR r.ingredient2 = mi.ingredient)
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

  Future<List<MedicineModel>> getHighRiskMedicines(int limit) async {
    await seedingComplete;
    final db = await dbHelper.database;

    try {
      // Step 1: Verify med_ingredients table has data
      final ingredientsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM med_ingredients'),
      );
      if (ingredientsCount == 0) return [];

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT DISTINCT d.* 
        FROM ${DatabaseHelper.medicinesTable} d
        JOIN med_ingredients mi ON d.id = mi.med_id
        JOIN ${DatabaseHelper.interactionsTable} r 
        ON (mi.ingredient = r.ingredient1 OR mi.ingredient = r.ingredient2)
        WHERE LOWER(r.severity) IN ('contraindicated', 'severe', 'major', 'high')
        LIMIT ?
      ''',
        [limit],
      );

      return List.generate(maps.length, (i) {
        return MedicineModel.fromMap(maps[i]);
      });
    } catch (e, stackTrace) {
      _logger.e('[getHighRiskMedicines] ERROR', e, stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getHighRiskIngredientsWithMetrics({
    int limit = 10,
  }) async {
    await seedingComplete;
    final db = await dbHelper.database;

    // COMPLEX QUERY OPTIMIZATION:
    // 1. Removed LOWER() on ingredients (NOCASE handles it).
    // 2. Simplified logic where possible.

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      WITH AffectedIngredients AS (
        SELECT 
          ingredient1 as original_name,
          -- Normalized key just trimming
          TRIM(REPLACE(REPLACE(ingredient1, '(', ''), ')', '')) as ingredient_key, 
          severity 
        FROM ${DatabaseHelper.interactionsTable}
        WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major', 'high', 'moderate', 'critical', 'serious')
        UNION ALL
        SELECT 
          ingredient2 as original_name,
          TRIM(REPLACE(REPLACE(ingredient2, '(', ''), ')', '')) as ingredient_key, 
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
      )
      SELECT 
        MAX(original_name) as name, -- Simplification for performance
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

  Future<List<DrugInteractionModel>> getInteractionsWith(
    String drugName,
  ) async {
    await seedingComplete;
    final db = await dbHelper.database;
    final normalizedQuery =
        drugName.trim(); // No need for toLowerCase with NOCASE

    // OPTIMIZED QUERY with NOCASE
    // We can use direct LIKE comparisons efficiently

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT * FROM ${DatabaseHelper.interactionsTable} 
      WHERE ingredient1 LIKE ? OR ingredient2 LIKE ?
      ORDER BY 
        CASE WHEN LOWER(severity) = 'contraindicated' THEN 1
             WHEN LOWER(severity) = 'severe' THEN 2
             WHEN LOWER(severity) = 'major' THEN 3
             ELSE 4 END
      LIMIT 100
      ''',
      ['%$normalizedQuery%', '%$normalizedQuery%'],
    );
    // Note: Prefix matching (query%) is faster but might miss '... sodium',
    // keeping %query% is acceptable if table isn't huge, but NOCASE index helps.
    // If strict prefix desired: ['$normalizedQuery%', '$normalizedQuery%']

    return List.generate(maps.length, (i) {
      final m = maps[i];
      final fullMap = Map<String, dynamic>.from(m);
      fullMap['med_id'] ??= 0;
      return DrugInteractionModel.fromMap(fullMap);
    });
  }

  String _normalizeIngredientName(String name) {
    if (name.isEmpty) return '';
    String processed = name.toLowerCase().trim();
    processed = processed.split('(').first.trim();
    return processed;
  }

  // --- Optimizing Search ---

  // Re-implement searchMedicinesByName with optimization
  Future<List<MedicineModel>> searchMedicinesByName(
    String query, {
    int? limit,
    int? offset,
  }) async {
    await seedingComplete;
    final db = await dbHelper.database;

    // 1. Try Prefix Search First (Use Index)
    // 'query%' uses the index on trade_name/active (NOCASE)
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: 'trade_name LIKE ? OR active LIKE ?',
      whereArgs: ['$query%', '$query%'],
      limit: limit,
      offset: offset,
    );

    if (maps.isEmpty && (offset == 0 || offset == null)) {
      // Only fallback on first page to avoid weirdness
      maps = await db.query(
        DatabaseHelper.medicinesTable,
        where: 'trade_name LIKE ? OR active LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        limit: limit,
      );
    }

    return maps.map((e) => MedicineModel.fromMap(e)).toList();
  }

  Future<List<int>> getNewestDrugIds(int limit) async {
    await seedingComplete;
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      columns: [DatabaseHelper.colId],
      orderBy: '${DatabaseHelper.colId} DESC',
      limit: limit,
    );
    return maps.map((map) => map[DatabaseHelper.colId] as int).toList();
  }

  Future<void> incrementVisits(int drugId) async {
    final db = await dbHelper.database;
    await db.rawUpdate(
      'UPDATE ${DatabaseHelper.medicinesTable} SET ${DatabaseHelper.colVisits} = ${DatabaseHelper.colVisits} + 1 WHERE ${DatabaseHelper.colId} = ?',
      [drugId],
    );
  }

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

  // --- Missing Methods Implementation (RESTORED) ---

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

  Future<List<MedicineModel>> findMedicines(String query) async {
    // Alias for searchMedicinesByName to fix 'findMedicines' error if used elsewhere intra-class
    return searchMedicinesByName(query);
  }

  // Backward compatibility alias if needed by Repos
  Future<List<MedicineModel>> searchMedicinesByNameOptimized(
    String query, {
    int? limit,
    int? offset,
  }) {
    return searchMedicinesByName(query, limit: limit, offset: offset);
  }

  Future<List<MedicineModel>> filterMedicinesByCategory(
    String category, {
    int? limit,
    int? offset,
  }) async {
    await seedingComplete;
    final db = await dbHelper.database;

    // Get keywords associated with this broad category (specialty)
    final keywords = CategoryMapperHelper.getKeywords(category);

    if (keywords.isEmpty) {
      // Fallback for categories without keywords or 'general' (if not handled explicitly)
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.medicinesTable,
        where: 'category = ?',
        whereArgs: [category],
        limit: limit,
        offset: offset,
      );
      if (maps.isNotEmpty)
        return maps.map((e) => MedicineModel.fromMap(e)).toList();

      return [];
    }

    // Build dynamic OR query: category LIKE '%key1%' OR category LIKE '%key2%' ...
    final whereClause = keywords.map((_) => 'category LIKE ?').join(' OR ');
    final args = keywords.map((k) => '%$k%').toList();

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: whereClause,
      whereArgs: args,
      limit: limit,
      offset: offset,
    );
    return maps.map((e) => MedicineModel.fromMap(e)).toList();
  }

  // Helper for DrugRepositoryImpl.saveDownloadedCsv
  Future<void> saveDownloadedCsv(List<int> fileData) async {
    final String rawCsv = String.fromCharCodes(fileData);
    final dbPath = await dbHelper.database.then((db) => db.path);
    await compute(_updateDatabaseIsolate, {'dbPath': dbPath, 'rawCsv': rawCsv});
    await markSeedingAsComplete();
  }

  // Dashboard Statistics
  Future<Map<String, int>> getDashboardStatistics() async {
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

    final ingredientsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM med_ingredients'),
        ) ??
        0;

    final foodCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseHelper.foodInteractionsTable}',
          ),
        ) ??
        0;

    return {
      'total_medicines': drugsCount,
      'total_interactions': interactionsCount,
      'active_ingredients': ingredientsCount,
      'food_interactions': foodCount,
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
      'SELECT DISTINCT category FROM ${DatabaseHelper.medicinesTable} ORDER BY category ASC',
    );
    return maps
        .map((e) => e['category'] as String?)
        .where((e) => e != null && e.isNotEmpty)
        .cast<String>()
        .toList();
  }

  Future<Map<String, int>> getCategoriesWithCount() async {
    await seedingComplete;
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM ${DatabaseHelper.medicinesTable} GROUP BY category',
    );
    final Map<String, int> categories = {};
    for (var row in result) {
      if (row['category'] != null) {
        categories[row['category'] as String] = row['count'] as int;
      }
    }
    return categories;
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

  // --- Hybrid Caching Methods ---

  Future<void> saveDrugInteractions(
    List<Map<String, dynamic>> interactions,
  ) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final interaction in interactions) {
      batch.insert(
        DatabaseHelper.interactionsTable,
        interaction,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _logger.i(
      '[SqliteLocalDataSource] Cached ${interactions.length} drug interactions.',
    );
  }

  Future<void> saveFoodInteractions(
    List<Map<String, dynamic>> interactions,
  ) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final interaction in interactions) {
      batch.insert(
        DatabaseHelper.foodInteractionsTable,
        interaction,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _logger.i(
      '[SqliteLocalDataSource] Cached ${interactions.length} food interactions.',
    );
  }

  Future<void> saveDiseaseInteractions(
    List<Map<String, dynamic>> interactions,
  ) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final interaction in interactions) {
      batch.insert(
        DatabaseHelper.diseaseInteractionsTable,
        interaction,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _logger.i(
      '[SqliteLocalDataSource] Cached ${interactions.length} disease interactions.',
    );
  }

  // Helper to check for existing medicines (for sync logic to avoid dupes if strictly needed)
  Future<List<MedicineModel>> findSimilars(
    String active,
    String tradeName,
  ) async {
    await seedingComplete;
    final db = await dbHelper.database;
    // Use active ingredient
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: 'active = ? AND trade_name != ?',
      whereArgs: [active, tradeName],
      limit: 10,
    );
    return maps.map((e) => MedicineModel.fromMap(e)).toList();
  }

  Future<List<MedicineModel>> findAlternatives(
    String category,
    String active,
  ) async {
    await seedingComplete;
    final db = await dbHelper.database;
    // Same category but different active
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.medicinesTable,
      where: 'category = ? AND active != ?',
      whereArgs: [category, active],
      limit: 10,
    );
    return maps.map((e) => MedicineModel.fromMap(e)).toList();
  }
}
