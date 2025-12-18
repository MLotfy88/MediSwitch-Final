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
  static const int _dbVersion = 4; // Bumping version for schema update
  static const String medicinesTable = 'medicines';

  // --- Column Names ---
  static const String colId = 'id'; // INTEGER PRIMARY KEY - NEW
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
  static const String colDosageFormAr = 'dosageForm_ar'; // NEW
  static const String colConcentration = 'concentration';
  static const String colUnit = 'unit';
  static const String colUsage = 'usage';
  static const String colUsageAr = 'usage_ar'; // NEW
  static const String colDescription = 'description';
  static const String colBarcode = 'barcode'; // NEW
  static const String colVisits = 'visits'; // NEW
  static const String colLastPriceUpdate = 'lastPriceUpdate';
  static const String colImageUrl = 'imageUrl';

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

    // Aggressive migration for Version 4: Re-create tables to ensure schema compliance
    // We drop checking previous versions intricately because the schema changed significantly.
    if (newVersion >= 4) {
      debugPrint('Performing full schema reset for Version 4...');
      await db.execute('DROP TABLE IF EXISTS $medicinesTable');
      await db.execute('DROP TABLE IF EXISTS dosage_guidelines');
      await _onCreate(db, newVersion);
      return;
    }

    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS $medicinesTable');
      await _onCreate(db, newVersion);
    }

    if (oldVersion < 3) {
      await _onCreateV3(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database tables and indices...');

    // Updated Medicine Table with ALL columns
    await db.execute('''
          CREATE TABLE $medicinesTable (
            $colTradeName TEXT PRIMARY KEY,
            $colId INTEGER, -- Optional ID linkage
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
            $colBarcode TEXT,
            $colVisits INTEGER,
            $colLastPriceUpdate TEXT,
            $colImageUrl TEXT
          )
          ''');
    debugPrint('Medicines table created');

    // Create indices
    await db.execute(
      'CREATE INDEX idx_trade_name ON $medicinesTable ($colTradeName)',
    );
    await db.execute(
      'CREATE INDEX idx_arabic_name ON $medicinesTable ($colArabicName)',
    );
    await db.execute('CREATE INDEX idx_active ON $medicinesTable ($colActive)');
    await db.execute(
      'CREATE INDEX idx_category ON $medicinesTable ($colCategory)',
    );
    await db.execute('CREATE INDEX idx_price ON $medicinesTable ($colPrice)');

    // Create Dosage Guidelines Table (Updated Schema)
    await _onCreateDosages(db);

    // Create Drug Interactions Table (New Schema)
    await _onCreateInteractions(db);

    debugPrint('Database tables and indices created.');
  }

  Future<void> _onCreateV3(Database db) async {
    // Legacy keeper, redirect to new creators
    await _onCreateDosages(db);
    await _onCreateInteractions(db);
  }

  Future<void> _onCreateDosages(Database db) async {
    debugPrint('Creating dosage_guidelines table...');
    await db.execute('''
      CREATE TABLE dosage_guidelines (
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
      'CREATE INDEX idx_guideline_med_id ON dosage_guidelines (med_id)',
    );
    debugPrint('dosage_guidelines table created');
  }

  Future<void> _onCreateInteractions(Database db) async {
    debugPrint('Creating drug_interactions table...');
    await db.execute('''
      CREATE TABLE drug_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER,
        interaction_drug_name TEXT,
        interaction_dailymed_id TEXT,
        severity TEXT,
        description TEXT,
        source TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_interaction_med_id ON drug_interactions (med_id)',
    );
    debugPrint('drug_interactions table created');
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
