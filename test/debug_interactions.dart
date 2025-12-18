import 'package:flutter_test/flutter_test.dart';
import 'package:mediswitch/core/database/database_helper.dart';
import 'package:mediswitch/data/datasources/local/sqlite_local_data_source.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  print('\n=== Interaction Data Debug Script ===\n');

  // Initialize database
  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;

  // Check interaction_rules table
  print('1. Checking interaction_rules table...');
  final rulesCount =
      Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM interaction_rules'),
      ) ??
      0;
  print('   Total rules: $rulesCount');

  if (rulesCount > 0) {
    final sampleRules = await db.query('interaction_rules', limit: 3);
    print('   Sample rules:');
    for (var rule in sampleRules) {
      print(
        '      ${rule['ingredient1']} + ${rule['ingredient2']} = ${rule['severity']}',
      );
    }
  }

  // Check med_ingredients table
  print('\n2. Checking med_ingredients table...');
  final ingredientsCount =
      Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM med_ingredients'),
      ) ??
      0;
  print('   Total ingredient mappings: $ingredientsCount');

  if (ingredientsCount > 0) {
    final sampleIngredients = await db.query('med_ingredients', limit: 5);
    print('   Sample mappings:');
    for (var ing in sampleIngredients) {
      print('      med_id=${ing['med_id']}, ingredient=${ing['ingredient']}');
    }
  }

  // Check drugs table
  print('\n3. Checking drugs table...');
  final drugsCount =
      Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.medicinesTable}',
        ),
      ) ??
      0;
  print('   Total drugs: $drugsCount');

  // Test interaction query for a specific drug
  if (drugsCount > 0 && rulesCount > 0) {
    print('\n4. Testing interaction query for drug ID 1...');
    final testQuery = await db.rawQuery(
      '''
      SELECT 
        r.id, 
        r.severity, 
        r.effect as description, 
        r.source, 
        CASE 
          WHEN r.ingredient1 = mi.ingredient THEN r.ingredient2 
          ELSE r.ingredient1 
        END as interaction_drug_name
      FROM med_ingredients mi
      JOIN interaction_rules r ON (r.ingredient1 = mi.ingredient OR r.ingredient2 = mi.ingredient)
      WHERE mi.med_id = ?
      LIMIT 5
    ''',
      [1],
    );

    print('   Found ${testQuery.length} interactions for drug ID 1');
    if (testQuery.isNotEmpty) {
      for (var interaction in testQuery) {
        print(
          '      ${interaction['interaction_drug_name']} (${interaction['severity']})',
        );
      }
    }
  }

  // Check if seeding is needed
  print('\n5. Checking if re-seeding is needed...');
  final dataSource = SqliteLocalDataSource(dbHelper: dbHelper);
  final hasMeds = await dataSource.hasMedicines();
  final hasInteractions = await dataSource.hasInteractions();

  print('   Has medicines: $hasMeds');
  print('   Has interactions: $hasInteractions');

  if (!hasMeds || !hasInteractions) {
    print('\n⚠️  PROBLEM DETECTED: Missing data!');
    print('   Triggering seedDatabaseFromAssetIfNeeded...');
    await dataSource.seedDatabaseFromAssetIfNeeded();

    // Re-check counts
    final newRulesCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM interaction_rules'),
        ) ??
        0;
    print('   Rules after seeding: $newRulesCount');
  }

  print('\n=== Debug Complete ===\n');
}
