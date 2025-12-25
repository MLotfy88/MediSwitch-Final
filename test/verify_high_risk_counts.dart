import 'package:flutter/widgets.dart';
import 'package:mediswitch/core/database/database_helper.dart';
import 'package:mediswitch/data/datasources/local/sqlite_local_data_source.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();
  final ds = SqliteLocalDataSource(dbHelper: dbHelper);
  await ds.seedingComplete;

  print("--- DB Verification Start ---");
  final db = await dbHelper.database;

  // 1. Check Raw Interactions Table
  final count = Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM drug_interactions'),
  );
  print('Total rows in drug_interactions: $count');

  final sample = await db.rawQuery('SELECT * FROM drug_interactions LIMIT 1');
  print('Sample interaction: $sample');

  // 2. Run the exact query from getHighRiskIngredientsWithMetrics
  print('\nRunning getHighRiskIngredientsWithMetrics query...');
  try {
    final maps = await db.rawQuery('''
      WITH AffectedIngredients AS (
        SELECT ingredient1 as ingredient, severity FROM drug_interactions
        WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major', 'high')
        UNION ALL
        SELECT ingredient2 as ingredient, severity FROM drug_interactions
        WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major', 'high')
      )
      SELECT 
        LOWER(ingredient) as name,
        COUNT(*) as totalInteractions,
        SUM(CASE WHEN LOWER(severity) IN ('contraindicated', 'severe', 'high') THEN 1 ELSE 0 END) as severeCount,
        SUM(CASE WHEN LOWER(severity) IN ('major', 'moderate') THEN 1 ELSE 0 END) as moderateCount,
        SUM(CASE WHEN LOWER(severity) = 'minor' THEN 1 ELSE 0 END) as minorCount,
        SUM(CASE 
          WHEN LOWER(severity) = 'contraindicated' THEN 10 
          WHEN LOWER(severity) IN ('severe', 'high') THEN 8
          WHEN LOWER(severity) = 'major' THEN 5
          WHEN LOWER(severity) = 'moderate' THEN 3
          ELSE 1 
        END) as dangerScore
      FROM AffectedIngredients
      GROUP BY LOWER(ingredient)
      ORDER BY dangerScore DESC
      LIMIT 10
      ''');

    if (maps.isEmpty) {
      print("Query returned NO results.");
    } else {
      for (var m in maps) {
        print(
          "Ingredient: ${m['name']}, Count: ${m['totalInteractions']}, DangerScore: ${m['dangerScore']}",
        );
      }
    }
  } catch (e) {
    print("Query Error: $e");
  }
  print("--- DB Verification End ---");
}
