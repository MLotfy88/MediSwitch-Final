import 'package:flutter/widgets.dart';
import 'package:mediswitch/core/database/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;

  print('--- DIAGNOSTIC SCRIPT START ---');

  // 1. Check Severity Values
  print('\n[1] Checking Interaction Severities:');
  final severities = await db.rawQuery(
    'SELECT DISTINCT severity FROM drug_interactions',
  );
  if (severities.isEmpty) {
    print('  NO INTERACTIONS FOUND!');
  } else {
    for (var s in severities) {
      print('  Found: "${s['severity']}"');
    }
  }

  // 2. Check High Risk Logic Query
  print('\n[2] Testing High Risk Ingredient Query:');
  try {
    final maps = await db.rawQuery('''
      WITH AffectedIngredients AS (
        SELECT ingredient1 as ingredient, severity FROM drug_interactions
        WHERE severity IN ('Contraindicated', 'contraindicated', 'CONTRAINDICATED', 'Severe', 'severe', 'SEVERE', 'Major', 'major', 'MAJOR')
        UNION ALL
        SELECT ingredient2 as ingredient, severity FROM drug_interactions
        WHERE severity IN ('Contraindicated', 'contraindicated', 'CONTRAINDICATED', 'Severe', 'severe', 'SEVERE', 'Major', 'major', 'MAJOR')
      )
      SELECT ingredient, COUNT(*) as c FROM AffectedIngredients GROUP BY ingredient ORDER BY c DESC LIMIT 5
      ''');
    print('  Query Result Count: ${maps.length}');
    for (var m in maps) {
      print('  Top: ${m['ingredient']} (${m['c']})');
    }
  } catch (e) {
    print('  QUERY FAILED: $e');
  }

  // 3. Check Medicines Table Columns (for pharmacology)
  print('\n[3] Checking Medicines Table Columns:');
  final columns = await db.rawQuery('PRAGMA table_info(drugs)');
  bool hasPharmacology = false;
  for (var c in columns) {
    if (c['name'] == 'pharmacology') hasPharmacology = true;
    if (c['name'] == 'usage') print('  Found column: usage');
  }
  print('  Has pharmacology column? $hasPharmacology');

  print('--- DIAGNOSTIC SCRIPT END ---');
}
