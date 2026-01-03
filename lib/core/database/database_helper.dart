import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Database helper class for managing SQLite database
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // --- Database Constants ---
  static const String dbName = 'mediswitch.db';
  static const int _dbVersion =
      17; // Force update to trigger normalized asset copy
  static const String medicinesTable = 'drugs'; // Renamed from 'medicines'
  static const String interactionsTable =
      'drug_interactions'; // Renamed from 'interaction_rules'
  static const String foodInteractionsTable = 'food_interactions';
  static const String diseaseInteractionsTable = 'disease_interactions';
  static const String homeCacheTable = 'home_sections_cache';

  // --- Column Names ---
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

    // --- PRE-PACKAGED DATABASE LOGIC ---
    // We check for a marker file to ensure we copy the new normalized DB even if the file exists
    final markerFile = File(join(documentsDirectory.path, 'db_v17_marker.txt'));

    if (!await databaseExists(path) || !await markerFile.exists()) {
      debugPrint(
        'Database marker missing or DB not found. Copying from assets...',
      );
      try {
        await Directory(dirname(path)).create(recursive: true);

        // Parts list (aa to aj)
        const partNames = [
          'aa',
          'ab',
          'ac',
          'ad',
          'ae',
          'af',
          'ag',
          'ah',
          'ai',
          'aj',
        ];

        List<int> allBytes = [];
        bool splitFound = true;

        for (var part in partNames) {
          try {
            final ByteData data = await rootBundle.load(
              'assets/database/parts/mediswitch.db.part-$part',
            );
            allBytes.addAll(
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            );
          } catch (e) {
            debugPrint('Error loading split part $part: $e');
            splitFound = false;
            break;
          }
        }

        if (splitFound && allBytes.isNotEmpty) {
          // If the database is currently open, we should close it (though in _init it shouldn't be)
          await File(path).writeAsBytes(allBytes, flush: true);
          await markerFile.create(); // Mark version 17 as ready
          debugPrint('Successfully joined and copied split database parts.');
        }
      } catch (e) {
        debugPrint('Error copying pre-packaged database: $e');
      }
    } else {
      debugPrint('Existing database found with version marker.');
    }

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Handle database creation
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database tables for version $version...');

    // Medications table
    await db.execute('''
      CREATE TABLE $medicinesTable (
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
        $colConcentration TEXT,
        $colUnit TEXT,
        $colUsage TEXT,
        $colPharmacology TEXT,
        $colBarcode TEXT,
        $colQrCode TEXT,
        $colVisits INTEGER DEFAULT 0,
        $colLastPriceUpdate TEXT,
        $colIndication TEXT,
        $colMechanismOfAction TEXT,
        $colPharmacodynamics TEXT,
        $colDataSourcePharmacology TEXT,
        $colUpdatedAt INTEGER DEFAULT 0,
        has_interaction INTEGER DEFAULT 0
      )
    ''');

    // Drug-Drug Interactions table
    await db.execute('''
      CREATE TABLE $interactionsTable (
        id INTEGER PRIMARY KEY,
        ingredient1 TEXT,
        ingredient2 TEXT,
        interaction_text TEXT,
        severity TEXT,
        source TEXT,
        created_at INTEGER DEFAULT 0
      )
    ''');

    // Ingredient bridge table for fast drug-interaction matching
    await db.execute('''
      CREATE TABLE med_ingredients (
        med_id INTEGER,
        ingredient TEXT,
        PRIMARY KEY (med_id, ingredient)
      )
    ''');

    // Indices for performance
    await db.execute(
      'CREATE INDEX idx_drugs_active ON $medicinesTable($colActive)',
    );
    await db.execute('CREATE INDEX idx_mi_med_id ON med_ingredients(med_id)');
    await db.execute(
      'CREATE INDEX idx_mi_ingredient ON med_ingredients(ingredient)',
    );
    await db.execute(
      'CREATE INDEX idx_di_ing1 ON $interactionsTable(ingredient1)',
    );
    await db.execute(
      'CREATE INDEX idx_di_ing2 ON $interactionsTable(ingredient2)',
    );

    // Food interactions
    await _onCreateFoodInteractions(db);

    // Disease interactions
    await _onCreateDiseaseInteractions(db);

    // Cache table
    await db.execute('''
      CREATE TABLE $homeCacheTable (
        section_key TEXT PRIMARY KEY,
        json_data TEXT,
        updated_at INTEGER
      )
    ''');
  }

  Future<void> _onCreateFoodInteractions(Database db) async {
    await db.execute('''
      CREATE TABLE $foodInteractionsTable (
        id INTEGER PRIMARY KEY,
        med_id INTEGER,
        trade_name TEXT,
        food_name TEXT,
        interaction_text TEXT,
        severity TEXT,
        source TEXT,
        created_at INTEGER DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_food_med_id ON $foodInteractionsTable(med_id)',
    );
  }

  Future<void> _onCreateDiseaseInteractions(Database db) async {
    await db.execute('''
      CREATE TABLE $diseaseInteractionsTable (
        id INTEGER PRIMARY KEY,
        med_id INTEGER,
        trade_name TEXT,
        disease_name TEXT,
        interaction_text TEXT,
        severity TEXT,
        source TEXT,
        created_at INTEGER DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_disease_med_id ON $diseaseInteractionsTable(med_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion...');
    // Asset copy is managed in _initDatabase via marker file for major logic changes.
    // Standard schema migrations can still go here if needed.
  }
}
