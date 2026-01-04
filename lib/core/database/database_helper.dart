import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../services/file_logger_service.dart';

/// Database helper class for managing SQLite database
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static Completer<Database>? _initCompleter;
  final FileLoggerService _logger = FileLoggerService();

  // --- Database Constants ---
  static const String dbName = 'mediswitch.db';
  static const int _dbVersion = 19; // Updated for Schema Fixes
  static const String medicinesTable = 'drugs';
  static const String interactionsTable = 'drug_interactions';
  static const String foodInteractionsTable = 'food_interactions';
  static const String diseaseInteractionsTable = 'disease_interactions';
  static const String homeCacheTable = 'home_sections_cache';
  static const String dosageTable = 'dosage_guidelines'; // NEW

  // --- Column Names for Drugs ---
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

    // Prevent race conditions with a completer
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<Database>();
    try {
      _database = await _initDatabase();
      _initCompleter!.complete(_database);
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null; // Allow retrying
      rethrow;
    }

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, dbName);
    _logger.i('DatabaseHelper: Initializing database at $path');

    // --- PRE-PACKAGED DATABASE LOGIC ---
    // v19 marker for the final schema alignment
    final markerFilePath = join(documentsDirectory.path, 'db_v19_nocase.txt');
    final markerFile = File(markerFilePath);

    final dbFile = File(path);
    bool needsCopy = !await dbFile.exists() || !await markerFile.exists();

    if (needsCopy) {
      _logger.i(
        'DatabaseHelper: Database marker missing (v19) or DB not found. Attempting asset copy...',
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

        // Explicitly delete old DB and any old markers to ensure clean state
        if (await dbFile.exists()) {
          _logger.i(
            'DatabaseHelper: Deleting existing database for fresh copy.',
          );
          await dbFile.delete();
        }

        // Use IOSink to stream parts directly to disk without loading entire DB into memory (STREAMS ONE AT A TIME)
        final IOSink sink = dbFile.openWrite(mode: FileMode.writeOnly);
        int totalBytes = 0;
        bool allPartsFound = true;

        for (var part in partNames) {
          final partPath = 'assets/database/parts/mediswitch.db.part-$part';
          try {
            // Loading 50MB into memory is much safer than 500MB
            final ByteData data = await rootBundle.load(partPath);
            final Uint8List bytes = data.buffer.asUint8List(
              data.offsetInBytes,
              data.lengthInBytes,
            );
            sink.add(bytes);
            totalBytes += bytes.length;
            _logger.d(
              'DatabaseHelper: Streamed part $part (${bytes.length} bytes)',
            );
          } catch (e) {
            _logger.e(
              'DatabaseHelper: FAILED to load/stream split part $part at $partPath: $e',
            );
            allPartsFound = false;
            break;
          }
        }

        await sink.flush();
        await sink.close();

        if (allPartsFound && totalBytes > 0) {
          await markerFile.create();
          _logger.i(
            'DatabaseHelper: SUCCESS! Joined and copied $totalBytes bytes to $path',
          );

          // FORCE SET VERSION to match app version (preventing immediate Upgrade/Create confusion)
          try {
            _logger.i(
              'DatabaseHelper: Setting localized user_version to $_dbVersion...',
            );
            final tempDb = await openDatabase(path, version: _dbVersion);
            await tempDb.close();
          } catch (_) {
            // Ignore temporary open errors
          }
        } else {
          _logger.w(
            'DatabaseHelper: Asset copy aborted or failed. Total bytes written: $totalBytes',
          );
          if (await dbFile.exists()) await dbFile.delete();
        }
      } catch (e, s) {
        _logger.e(
          'DatabaseHelper: CRITICAL error copying pre-packaged database',
          e,
          s,
        );
      }
    } else {
      _logger.i(
        'DatabaseHelper: Existing database found with v19 marker. Skipping copy.',
      );
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
    _logger.i('DatabaseHelper: _onCreate triggered for version $version');

    // Medications table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $medicinesTable (
        $colId INTEGER PRIMARY KEY,
        $colTradeName TEXT COLLATE NOCASE,
        $colArabicName TEXT,
        $colPrice TEXT,
        $colOldPrice TEXT,
        $colCategory TEXT COLLATE NOCASE, -- Indexed
        $colActive TEXT COLLATE NOCASE, -- Indexed
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
        $colLastPriceUpdate TEXT, -- Indexed
        $colIndication TEXT,
        $colMechanismOfAction TEXT,
        $colPharmacodynamics TEXT,
        $colDataSourcePharmacology TEXT,
        $colUpdatedAt INTEGER DEFAULT 0,
        has_drug_interaction INTEGER DEFAULT 0,
        has_food_interaction INTEGER DEFAULT 0,
        has_disease_interaction INTEGER DEFAULT 0,
        description TEXT,
        atc_codes TEXT,
        external_links TEXT
      )
    ''');

    // Drug-Drug Interactions table - COLLATE NOCASE for fast search
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $interactionsTable (
        id INTEGER PRIMARY KEY,
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
        updated_at INTEGER DEFAULT 0
      )
    ''');

    // Ingredient bridge table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS med_ingredients (
        med_id INTEGER,
        ingredient TEXT COLLATE NOCASE,
        PRIMARY KEY (med_id, ingredient)
      )
    ''');

    // NEW: Dosage Guidelines Table (Was missing)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $dosageTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER,
        population_group TEXT DEFAULT 'Adults',
        min_dose REAL DEFAULT 0.0,
        max_dose REAL DEFAULT 0.0,
        unit TEXT,
        frequency TEXT,
        max_daily_dose REAL DEFAULT 0.0,
        route TEXT DEFAULT 'Oral',
        conditions TEXT,
        source TEXT DEFAULT 'Manual/Aggregated',
        created_at INTEGER DEFAULT 0
      )
    ''');

    // Indices for performance - CRITICAL FIXES
    // 1. Medicines
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_trade_name ON $medicinesTable($colTradeName)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_drugs_active ON $medicinesTable($colActive)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_category ON $medicinesTable($colCategory)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_last_price ON $medicinesTable($colLastPriceUpdate)',
    );

    // 2. Ingredients
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_mi_med_id ON med_ingredients(med_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_mi_ingredient ON med_ingredients(ingredient)',
    );

    // 3. Dosages
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_dosage_med_id ON $dosageTable(med_id)',
    );

    // 4. Interactions
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_di_ing1 ON $interactionsTable(ingredient1)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_di_ing2 ON $interactionsTable(ingredient2)',
    );

    // Food interactions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $foodInteractionsTable (
        id INTEGER PRIMARY KEY,
        med_id INTEGER,
        trade_name TEXT COLLATE NOCASE,
        ingredient TEXT COLLATE NOCASE,
        interaction TEXT,
        severity TEXT,
        management_text TEXT,
        mechanism_text TEXT,
        reference_text TEXT,
        source TEXT,
        created_at INTEGER DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_food_med_id ON $foodInteractionsTable(med_id)',
    );

    // Disease interactions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $diseaseInteractionsTable (
        id INTEGER PRIMARY KEY,
        med_id INTEGER,
        trade_name TEXT COLLATE NOCASE,
        disease_name TEXT COLLATE NOCASE,
        interaction_text TEXT,
        severity TEXT,
        source TEXT,
        created_at INTEGER DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_disease_med_id ON $diseaseInteractionsTable(med_id)',
    );

    // Cache table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $homeCacheTable (
        "key" TEXT PRIMARY KEY,
        data TEXT,
        updated_at INTEGER
      )
    ''');

    _logger.i('DatabaseHelper: Tables verified/created successfully.');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('DatabaseHelper: Upgrading from $oldVersion to $newVersion...');
    // Asset copy is managed in _initDatabase via marker file for major logic changes.
    // If the tables don't exist, we create them (just in case)
    if (oldVersion == 0) {
      await _onCreate(db, newVersion);
    }
  }
}
