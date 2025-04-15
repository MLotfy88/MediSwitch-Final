import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/medicine_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // --- Database Constants ---
  static const String dbName = 'mediswitch.db';
  static const int _dbVersion = 1; // Increment version if schema changes
  static const String medicinesTable = 'medicines';

  // --- Column Names ---
  static const String colTradeName = 'tradeName';
  static const String colArabicName = 'arabicName';
  static const String colPrice = 'price';
  static const String colOldPrice = 'oldPrice'; // Add column name constant
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

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, dbName);
    print('Database path: $path');
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // Implement if version increases
    );
  }

  Future _onCreate(Database db, int version) async {
    print('Creating database tables and indices...');
    await db.execute('''
          CREATE TABLE $medicinesTable (
            $colTradeName TEXT PRIMARY KEY,
            $colArabicName TEXT,
            $colPrice TEXT,
            $colOldPrice TEXT, -- Add oldPrice column
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
    print('Indices created');

    print(
      "Database tables and indices created. Seeding will be handled externally if needed.",
    );
  }

  // --- Basic CRUD Operations ---

  Future<void> insertMedicinesBatch(List<MedicineModel> medicines) async {
    final db = await database;
    Batch batch = db.batch();
    for (var med in medicines) {
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
    print('Inserted/Replaced ${medicines.length} medicines in batch.');
  }

  Future<void> clearMedicines() async {
    final db = await database;
    await db.delete(medicinesTable);
    print('Cleared medicines table.');
  }

  Future<List<MedicineModel>> getAllMedicines() async {
    final db = await database;
    // Ensure all columns including oldPrice are selected
    final List<String> columnsToSelect = [
      colTradeName,
      colArabicName,
      colPrice,
      colOldPrice,
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
      medicinesTable,
      columns: columnsToSelect,
    );
    return List.generate(maps.length, (i) {
      return MedicineModel.fromMap(maps[i]);
    });
  }
}
