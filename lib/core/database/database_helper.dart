import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/medicine_model.dart';

import 'package:flutter/foundation.dart';

/// Database helper class for managing SQLite database
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // --- Database Constants ---
  static const String dbName = 'mediswitch.db';
  static const int _dbVersion = 2; // Increment version if schema changes
  static const String medicinesTable = 'medicines';

  // --- Column Names ---
  static const String colTradeName = 'tradeName';
  static const String colArabicName = 'arabicName';
  static const String colPrice = 'price';
  static const String colOldPrice = 'oldPrice'; // Add column name constant
  static const String colMainCategory = 'mainCategory';
  static const String colCategory = 'category'; // Add category column name
  static const String colCategoryAr =
      'category_ar'; // Add category_ar column name
  static const String colActive = 'active';
  static const String colCompany = 'company';
  static const String colDosageForm = 'dosageForm';
  static const String colConcentration = 'concentration';
  static const String colUnit = 'unit';
  static const String colUsage = 'usage';
  static const String colDescription = 'description';
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
    if (oldVersion < 2) {
      // Version 2: Re-create table to fix date format in data
      await db.execute('DROP TABLE IF EXISTS $medicinesTable');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database tables and indices...');
    await db.execute('''
          CREATE TABLE $medicinesTable (
            $colTradeName TEXT PRIMARY KEY,
            $colArabicName TEXT,
            $colPrice TEXT,
            $colOldPrice TEXT, -- Add oldPrice column
            $colMainCategory TEXT,
            $colCategory TEXT, -- Add category column
            $colCategoryAr TEXT, -- Add category_ar column
            $colActive TEXT,
            $colCompany TEXT,
            $colDosageForm TEXT,
            $colConcentration REAL,
            $colUnit TEXT,
            $colUsage TEXT,
            $colDescription TEXT,
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
      'CREATE INDEX idx_main_category ON $medicinesTable ($colMainCategory)',
    );
    await db.execute('CREATE INDEX idx_price ON $medicinesTable ($colPrice)');
    // Add index for oldPrice if needed for querying/sorting later
    // await db.execute('CREATE INDEX idx_old_price ON $medicinesTable ($colOldPrice)');
    debugPrint('Indices created');

    debugPrint(
      'Database tables and indices created. Seeding will be handled externally if needed.',
    );
  }

  // --- Basic CRUD Operations ---

  /// Insert or replace a batch of medicines
  Future<void> insertMedicinesBatch(List<MedicineModel> medicines) async {
    final db = await database;
    final batch = db.batch();
    for (final med in medicines) {
      // Use the model's toMap which should now include oldPrice if the column exists
      final dbMap = med.toMap();
      // Ensure all keys in dbMap match columns in the table definition
      // (This filtering might be redundant if toMap is correct)
      dbMap.removeWhere(
        (key, value) =>
            ![
              colTradeName,
              colArabicName,
              colPrice,
              colOldPrice,
              colMainCategory,
              colCategory, // Add category to list of valid columns
              colCategoryAr, // Add category_ar to list of valid columns
              colActive,
              colCompany,
              colDosageForm,
              colConcentration,
              colUnit,
              colUsage,
              colDescription,
              colLastPriceUpdate,
              colImageUrl,
            ].contains(key),
      );

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
    // Ensure all columns including oldPrice are selected
    final columnsToSelect = [
      colTradeName,
      colArabicName,
      colPrice,
      colOldPrice,
      colMainCategory,
      colCategory, // Add category to selected columns
      colCategoryAr, // Add category_ar to selected columns
      colActive,
      colCompany,
      colDosageForm,
      colConcentration,
      colUnit,
      colUsage,
      colDescription,
      colLastPriceUpdate,
      colImageUrl,
    ];
    final List<Map<String, dynamic>> maps = await db.query(
      medicinesTable,
      columns: columnsToSelect,
    );
    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }
}
