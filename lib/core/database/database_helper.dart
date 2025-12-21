import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/models/medicine_model.dart';

/// Database helper class for managing SQLite database
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // --- Database Constants ---
  static const String dbName = 'mediswitch.db';
  static const int _dbVersion = 8; // Bumping version for food interactions
  static const String medicinesTable = 'drugs'; // Renamed from 'medicines'
  static const String interactionsTable =
      'drug_interactions'; // Renamed from 'interaction_rules'
  static const String foodInteractionsTable = 'food_interactions';

  // --- Column Names ---
  static const String colId = 'id';
  static const String colTradeName = 'tradeName';
  static const String colArabicName = 'arabicName';
  static const String colPrice = 'price';
  static const String colOldPrice = 'oldPrice';
  static const String colMainCategory = 'mainCategory';
  static const String colCategory = 'category';
  static const String colCategoryAr = 'category_ar';
  static const String colActive = 'active';
  static const String colCompany = 'company';
  static const String colDosageForm = 'dosageForm';
  static const String colDosageFormAr = 'dosageForm_ar';
  static const String colConcentration = 'concentration';
  static const String colUnit = 'unit';
  static const String colUsage = 'usage';
  static const String colUsageAr = 'usage_ar';
  static const String colDescription = 'description';
  static const String colPharmacology = 'pharmacology'; // New Column
  static const String colBarcode = 'barcode';
  static const String colVisits = 'visits';
  static const String colLastPriceUpdate = 'lastPriceUpdate';
  static const String colImageUrl = 'imageUrl';
  static const String colUpdatedAt = 'updatedAt'; // New for Delta Sync

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, dbName);
    debugPrint('Database path: $path');
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion...');

    if (oldVersion < 6) {
      debugPrint(
        'Performing full schema migration for Version 6 (Renaming)...',
      );
      // Full reset is safest for beta to ensure clean state with new naming
      await db.execute('DROP TABLE IF EXISTS medicines'); // Old name
      await db.execute('DROP TABLE IF EXISTS drugs'); // New name (if exists)
      await db.execute('DROP TABLE IF EXISTS dosage_guidelines');
      await db.execute('DROP TABLE IF EXISTS interaction_rules'); // Old name
      await db.execute('DROP TABLE IF EXISTS drug_interactions'); // New name
      await db.execute('DROP TABLE IF EXISTS med_ingredients');
      await db.execute('DROP TABLE IF EXISTS $foodInteractionsTable');
      await _onCreate(db, newVersion);
      return;
    }

    if (oldVersion < 7) {
      debugPrint(
        'Upgrading to Version 7: Resetting drugs table for new schema...',
      );
      await db.execute('DROP TABLE IF EXISTS $medicinesTable');
      await _onCreate(db, newVersion);
    }

    if (oldVersion < 8) {
      debugPrint('Upgrading to Version 8: Adding food_interactions table...');
      await _onCreateFoodInteractions(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database tables and indices...');

    // Updated Medicine Table (Renamed to drugs)
    await db.execute('''
          CREATE TABLE IF NOT EXISTS $medicinesTable (
            $colTradeName TEXT PRIMARY KEY,
            $colId INTEGER,
            $colArabicName TEXT,
            $colPrice TEXT,
            $colOldPrice TEXT,
            $colMainCategory TEXT,
            $colCategory TEXT,
            $colCategoryAr TEXT,
            $colActive TEXT,
            $colCompany TEXT,
            $colDosageForm TEXT,
            $colDosageFormAr TEXT,
            $colConcentration REAL,
            $colUnit TEXT,
            $colUsage TEXT,
            $colUsageAr TEXT,
            $colDescription TEXT,
            $colPharmacology TEXT,
            $colBarcode TEXT,
            $colVisits INTEGER,
            $colLastPriceUpdate TEXT,
            $colImageUrl TEXT,
            $colUpdatedAt INTEGER DEFAULT 0 -- For Sync logic
          )
          ''');
    debugPrint('Medicines table created');

    // Create indices
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_trade_name ON $medicinesTable ($colTradeName)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_arabic_name ON $medicinesTable ($colArabicName)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_active ON $medicinesTable ($colActive)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_category ON $medicinesTable ($colCategory)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_price ON $medicinesTable ($colPrice)',
    );

    // Create Dosage Guidelines Table (Updated Schema)
    await _onCreateDosages(db);

    // Create Drug Interactions Table (New Schema)
    await _onCreateInteractions(db);

    // Create Food Interactions Table
    await _onCreateFoodInteractions(db);

    debugPrint('Database tables and indices created.');
  }

  Future<void> _onCreateDosages(Database db) async {
    debugPrint('Creating dosage_guidelines table...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dosage_guidelines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER,
        dailymed_setid TEXT,
        min_dose REAL,
        max_dose REAL,
        frequency INTEGER,
        duration INTEGER,
        instructions TEXT,
        condition TEXT,
        source TEXT,
        is_pediatric INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_guideline_med_id ON dosage_guidelines (med_id)',
    );
    debugPrint('dosage_guidelines table created');
  }

  // ... (previous code)

  // ...

  Future<void> _onCreateInteractions(Database db) async {
    debugPrint('Creating $interactionsTable and med_ingredients tables...');

    // 1. Rules Table (Knowledge Base)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $interactionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredient1 TEXT,
        ingredient2 TEXT,
        severity TEXT,
        effect TEXT,
        source TEXT,
        updated_at INTEGER DEFAULT 0 -- For Sync
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_rules_i1 ON $interactionsTable(ingredient1)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_rules_i2 ON $interactionsTable(ingredient2)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_rules_pair ON $interactionsTable(ingredient1, ingredient2)',
    );

    // 2. Ingredients Index (Map)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS med_ingredients (
        med_id INTEGER,
        ingredient TEXT,
        PRIMARY KEY (med_id, ingredient)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_mi_mid ON med_ingredients(med_id)',
    );

    debugPrint('Relational interaction tables created');
  }

  Future<void> _onCreateFoodInteractions(Database db) async {
    debugPrint('Creating $foodInteractionsTable table...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $foodInteractionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER,
        trade_name TEXT,
        interaction TEXT,
        source TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_food_med_id ON $foodInteractionsTable(med_id)',
    );
    debugPrint('$foodInteractionsTable table created');
  }

  // --- Basic CRUD Operations ---

  /// Insert or replace a batch of medicines
  Future<void> insertMedicinesBatch(List<MedicineModel> medicines) async {
    final db = await database;
    final batch = db.batch();
    for (final med in medicines) {
      final dbMap = med.toMap();
      // Ensure strict column mapping manually if needed, but toMap() should be source of truth
      // Filter out unknown keys just in case
      final validColumns = [
        colTradeName,
        colId,
        colArabicName,
        colPrice,
        colOldPrice,
        colMainCategory,
        colCategory,
        colCategoryAr,
        colActive,
        colCompany,
        colDosageForm,
        colDosageFormAr,
        colConcentration,
        colUnit,
        colUsage,
        colUsageAr,
        colDescription,
        colBarcode,
        colVisits,
        colLastPriceUpdate,
        colImageUrl,
      ];

      dbMap.removeWhere((key, value) => !validColumns.contains(key));

      batch.insert(
        medicinesTable,
        dbMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('Inserted/Replaced ${medicines.length} medicines in batch.');
  }

  /// Clear all medicines
  Future<void> clearMedicines() async {
    final db = await database;
    await db.delete(medicinesTable);
    debugPrint('Cleared medicines table.');
  }

  /// Get all medicines
  Future<List<MedicineModel>> getAllMedicines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(medicinesTable);
    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }
}
