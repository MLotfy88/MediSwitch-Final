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
  static const int _dbVersion =
      16; // Added enriched interaction columns (was 15)
  static const String medicinesTable = 'drugs'; // Renamed from 'medicines'
  static const String interactionsTable =
      'drug_interactions'; // Renamed from 'interaction_rules'
  static const String foodInteractionsTable = 'food_interactions';
  static const String diseaseInteractionsTable = 'disease_interactions';
  static const String homeCacheTable = 'home_sections_cache';

  // --- Column Names (Strictly snake_case to match D1 & Assets) ---
  static const String colId = 'id';
  static const String colTradeName = 'trade_name';
  static const String colArabicName = 'arabic_name';
  static const String colPrice = 'price';
  static const String colOldPrice = 'old_price';
  static const String colCategory = 'category';
  static const String colActive = 'active';
  static const String colCompany = 'company';
  static const String colDosageForm = 'dosage_form';
  static const String colDosageFormAr = 'dosage_form_ar';
  static const String colConcentration = 'concentration';
  static const String colUnit = 'unit';
  static const String colUsage = 'usage';
  static const String colPharmacology = 'pharmacology';
  static const String colBarcode = 'barcode';
  static const String colQrCode = 'qr_code';
  static const String colVisits = 'visits';
  static const String colLastPriceUpdate = 'last_price_update';
  static const String colIndication = 'indication';
  static const String colMechanismOfAction = 'mechanism_of_action';
  static const String colPharmacodynamics = 'pharmacodynamics';
  static const String colDataSourcePharmacology = 'data_source_pharmacology';
  static const String colUpdatedAt = 'updated_at';

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
      await db.execute('DROP TABLE IF EXISTS $diseaseInteractionsTable');
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
      // Drop and recreate to ensure clean state
      await db.execute('DROP TABLE IF EXISTS $foodInteractionsTable');
      await _onCreateFoodInteractions(db);
      // Set flag to trigger seeding after upgrade
      debugPrint('Food interactions table created. Seeding will be triggered.');
    }

    if (oldVersion < 9) {
      debugPrint(
        'Upgrading to Version 9: Adding updated_at to med_ingredients...',
      );
      try {
        await db.execute(
          'ALTER TABLE med_ingredients ADD COLUMN updated_at INTEGER DEFAULT 0',
        );
      } catch (e) {
        debugPrint(
          'Note: updated_at might already exist in med_ingredients: $e',
        );
      }
    }

    if (oldVersion < 11) {
      debugPrint('Upgrading to Version 11: Full Schema Reset for Unity...');
      await db.execute('DROP TABLE IF EXISTS drugs');
      await db.execute('DROP TABLE IF EXISTS dosage_guidelines');
      await db.execute('DROP TABLE IF EXISTS drug_interactions');
      await db.execute('DROP TABLE IF EXISTS med_ingredients');
      await db.execute('DROP TABLE IF EXISTS food_interactions');
      await db.execute(
        'DROP TABLE IF EXISTS $diseaseInteractionsTable',
      ); // Add drop for disease interactions
      await _onCreate(db, newVersion);
      return;
    }

    if (oldVersion < 12) {
      debugPrint(
        'Upgrading to Version 12: Adding disease_interactions table...',
      );
      await db.execute('DROP TABLE IF EXISTS $diseaseInteractionsTable');
      await _onCreateDiseaseInteractions(db);
      // Add has_disease_interaction column to drugs table
      try {
        await db.execute(
          'ALTER TABLE $medicinesTable ADD COLUMN has_disease_interaction INTEGER DEFAULT 0',
        );
      } catch (e) {
        debugPrint('Note: has_disease_interaction might already exist: $e');
      }
    }

    if (oldVersion < 13) {
      debugPrint(
        'Upgrading to Version 13: Rebuilding interactions with full data...',
      );
      // Drop and recreate interactions table to ensure all fields are populated
      await db.execute('DROP TABLE IF EXISTS $interactionsTable');
      await _onCreateInteractions(db);
      // Seeding will be triggered automatically by SqliteLocalDataSource
      debugPrint(
        'Interactions table reset. Fresh seeding will populate all fields.',
      );
    }

    if (oldVersion < 15) {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS $homeCacheTable (key TEXT PRIMARY KEY, data TEXT)',
      );
    }

    if (oldVersion < 16) {
      debugPrint(
        'Upgrading to Version 16: Enriching interaction data schema...',
      );
      // 1. Drugs Table
      await db.execute(
        'ALTER TABLE $medicinesTable ADD COLUMN description TEXT',
      );
      await db.execute('ALTER TABLE $medicinesTable ADD COLUMN atc_codes TEXT');
      await db.execute(
        'ALTER TABLE $medicinesTable ADD COLUMN external_links TEXT',
      );

      // 2. Drug Interactions Table
      await db.execute(
        'ALTER TABLE $interactionsTable ADD COLUMN metabolism_info TEXT',
      );
      await db.execute(
        'ALTER TABLE $interactionsTable ADD COLUMN source_url TEXT',
      );
      await db.execute(
        'ALTER TABLE $interactionsTable ADD COLUMN reference_text TEXT',
      );

      // 3. Food Interactions Table
      await db.execute(
        'ALTER TABLE $foodInteractionsTable ADD COLUMN ingredient TEXT',
      );
      await db.execute(
        'ALTER TABLE $foodInteractionsTable ADD COLUMN severity TEXT',
      );
      await db.execute(
        'ALTER TABLE $foodInteractionsTable ADD COLUMN management_text TEXT',
      );
      await db.execute(
        'ALTER TABLE $foodInteractionsTable ADD COLUMN mechanism_text TEXT',
      );
      await db.execute(
        'ALTER TABLE $foodInteractionsTable ADD COLUMN reference_text TEXT',
      );

      // 4. Disease Interactions Table
      await db.execute(
        'ALTER TABLE $diseaseInteractionsTable ADD COLUMN reference_text TEXT',
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database tables and indices...');

    // Updated Medicine Table (Renamed to drugs)
    await db.execute('''
          CREATE TABLE IF NOT EXISTS $medicinesTable (
            $colId INTEGER PRIMARY KEY,
            $colTradeName TEXT,
            $colArabicName TEXT,
            $colPrice TEXT,
            $colOldPrice TEXT,
            $colCategory TEXT,
            $colActive TEXT,
            $colCompany TEXT,
            $colDosageForm TEXT,
            $colDosageFormAr TEXT,
            $colConcentration REAL,
            $colUnit TEXT,
            $colUsage TEXT,
            $colPharmacology TEXT,
            $colBarcode TEXT,
            $colQrCode TEXT,
            $colVisits INTEGER,
            $colLastPriceUpdate TEXT,
            $colUpdatedAt INTEGER DEFAULT 0,
            $colIndication TEXT,
            $colMechanismOfAction TEXT,
            $colPharmacodynamics TEXT,
            $colDataSourcePharmacology TEXT,
            has_drug_interaction INTEGER DEFAULT 0,
            has_food_interaction INTEGER DEFAULT 0,
            has_disease_interaction INTEGER DEFAULT 0,
            description TEXT,
            atc_codes TEXT,
            external_links TEXT
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

    // Create Disease Interactions Table
    await _onCreateDiseaseInteractions(db);

    // Create Home Cache Table
    await db.execute(
      'CREATE TABLE IF NOT EXISTS $homeCacheTable (key TEXT PRIMARY KEY, data TEXT)',
    );

    debugPrint('Database tables and indices created.');
  }

  Future<void> _onCreateDosages(Database db) async {
    debugPrint('Creating dosage_guidelines table...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dosage_guidelines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL,
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
        ingredient1 TEXT COLLATE NOCASE,
        ingredient2 TEXT COLLATE NOCASE,
        severity TEXT,
        effect TEXT,
        arabic_effect TEXT,
        recommendation TEXT,
        arabic_recommendation TEXT,
        management_text TEXT,
        mechanism_text TEXT,
        alternatives_a TEXT,
        alternatives_b TEXT,
        risk_level TEXT,
        ddinter_id TEXT,
        source TEXT,
        type TEXT,
        metabolism_info TEXT,
        source_url TEXT,
        reference_text TEXT,
        updated_at INTEGER DEFAULT 0
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
        ingredient TEXT COLLATE NOCASE,
        updated_at INTEGER DEFAULT 0, -- For Sync support
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
        med_id INTEGER NOT NULL,
        trade_name TEXT,
        interaction TEXT NOT NULL,
        ingredient TEXT,
        severity TEXT,
        management_text TEXT,
        mechanism_text TEXT,
        reference_text TEXT,
        source TEXT DEFAULT 'DrugBank',
        created_at INTEGER DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_food_med_id ON $foodInteractionsTable(med_id)',
    );
    debugPrint('$foodInteractionsTable table created');
  }

  Future<void> _onCreateDiseaseInteractions(Database db) async {
    debugPrint('Creating $diseaseInteractionsTable table...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $diseaseInteractionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL,
        trade_name TEXT,
        disease_name TEXT NOT NULL,
        interaction_text TEXT NOT NULL,
        severity TEXT,
        reference_text TEXT,
        source TEXT DEFAULT 'DDInter',
        created_at INTEGER DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_disease_med_id ON $diseaseInteractionsTable(med_id)',
    );
    debugPrint('$diseaseInteractionsTable table created');
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
        colCategory,
        colActive,
        colCompany,
        colDosageForm,
        colDosageFormAr,
        colConcentration,
        colUnit,
        colUsage,
        colPharmacology,
        colBarcode,
        colVisits,
        colLastPriceUpdate,
        colQrCode,
        colIndication,
        colMechanismOfAction,
        colPharmacodynamics,
        colDataSourcePharmacology,
        colUpdatedAt,
        'has_drug_interaction',
        'has_food_interaction',
        'has_disease_interaction',
        'description',
        'atc_codes',
        'external_links',
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
