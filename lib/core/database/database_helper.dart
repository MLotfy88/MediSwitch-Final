import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/medicine_model.dart'; // Import MedicineModel

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // --- Database Constants ---
  static const String dbName = 'mediswitch.db'; // Made public
  static const int _dbVersion = 1;
  static const String medicinesTable = 'medicines'; // Made public

  // --- Column Names (Match MedicineModel properties used in DB) ---
  static const String colTradeName = 'tradeName'; // PRIMARY KEY
  static const String colArabicName = 'arabicName';
  static const String colPrice = 'price';
  static const String colMainCategory = 'mainCategory';
  static const String colActive = 'active';
  static const String colCompany = 'company';
  static const String colDosageForm = 'dosageForm';
  static const String colConcentration = 'concentration';
  static const String colUnit = 'unit';
  static const String colUsage = 'usage';
  static const String colDescription = 'description';
  static const String colLastPriceUpdate = 'lastPriceUpdate';
  static const String colImageUrl = 'imageUrl';
  // Note: We are NOT storing fields like oldPrice, category, *_ar fields directly

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, dbName); // Use public name
    print('Database path: $path'); // Log path for debugging
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // Add if schema changes later
    );
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    // Use public table name
    await db.execute('''
          CREATE TABLE $medicinesTable (
            $colTradeName TEXT PRIMARY KEY,
            $colArabicName TEXT,
            $colPrice TEXT,
            $colMainCategory TEXT,
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
    print('Medicines table created');

    // Create indices for faster searching
    await db.execute(
      'CREATE INDEX idx_arabic_name ON $medicinesTable ($colArabicName)',
    ); // Use public name
    await db.execute(
      'CREATE INDEX idx_active ON $medicinesTable ($colActive)',
    ); // Use public name
    await db.execute(
      'CREATE INDEX idx_main_category ON $medicinesTable ($colMainCategory)',
    ); // Use public name
    // Consider adding index on price if filtering/sorting by price is frequent
    // await db.execute('CREATE INDEX idx_price ON $medicinesTable ($colPrice)');
    print('Indices created');
  }

  // --- Basic CRUD Operations (will be expanded) ---

  // Insert a list of medicines (typically used after parsing CSV)
  // Uses batch for efficiency
  Future<void> insertMedicinesBatch(List<MedicineModel> medicines) async {
    final db = await database;
    // Use Batch for bulk inserts
    Batch batch = db.batch();
    for (var med in medicines) {
      // Use the existing toMap method from MedicineModel
      // Filter the map to only include columns defined in the DB schema
      final dbMap =
          med.toMap()..removeWhere(
            (key, value) =>
                ![
                  colTradeName,
                  colArabicName,
                  colPrice,
                  colMainCategory,
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
          ); // Ensure only DB columns are included

      batch.insert(
        medicinesTable, // Use public name
        dbMap,
        conflictAlgorithm:
            ConflictAlgorithm.replace, // Replace if tradeName exists
      );
    }
    await batch.commit(noResult: true);
    print('Inserted/Replaced ${medicines.length} medicines in batch.');
  }

  // Clear all medicines (used before inserting new data)
  Future<void> clearMedicines() async {
    final db = await database;
    await db.delete(medicinesTable); // Use public name
    print('Cleared medicines table.');
  }

  // Get all medicines (example query)
  Future<List<MedicineModel>> getAllMedicines() async {
    final db = await database;
    // Define columns to retrieve (match the ones used in fromMap)
    final List<String> columnsToSelect = [
      colTradeName,
      colArabicName,
      colPrice,
      colMainCategory,
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
      medicinesTable, // Use public name
      columns: columnsToSelect,
    );

    return List.generate(maps.length, (i) {
      // Use the existing factory constructor from MedicineModel
      return MedicineModel.fromMap(maps[i]);
    });
  }

  // TODO: Add methods for search, filter, get categories etc. using SQL queries
}

// Removed the extension methods as they are already present (or similar) in MedicineModel
