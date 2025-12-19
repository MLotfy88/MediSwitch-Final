import 'package:flutter/material.dart';
import 'package:mediswitch/core/database/database_helper.dart';
import 'package:mediswitch/core/di/locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  final dbHelper = locator<DatabaseHelper>();
  final db = await dbHelper.database;

  print('--- Sample Severities ---');
  final result = await db.rawQuery(
    'SELECT DISTINCT severity FROM ${DatabaseHelper.interactionsTable} LIMIT 10',
  );
  for (var row in result) {
    print('Severity: "${row['severity']}"');
  }

  print('--- Checking High Risk Query Result ---');
  final limit = 5;
  final maps = await db.rawQuery('''
      SELECT m.trade_name, r.severity
      FROM medicines m
      JOIN med_ingredients mi ON m.id = mi.med_id
      JOIN interaction_rules r ON (r.ingredient1 = mi.ingredient OR r.ingredient2 = mi.ingredient)
      LIMIT 10
    ''');

  print('Joined rows found: ${maps.length}');
  for (var row in maps) {
    print('Drug: ${row['trade_name']}, Severity: ${row['severity']}');
  }

  print('--- Checking High Risk Query with case-insensitive WHERE ---');
  final maps2 = await db.rawQuery('''
      SELECT m.trade_name, 
        SUM(CASE 
          WHEN LOWER(r.severity) = 'contraindicated' THEN 10 
          WHEN LOWER(r.severity) = 'severe' THEN 8
          WHEN LOWER(r.severity) = 'major' THEN 5
          WHEN LOWER(r.severity) = 'moderate' THEN 3
          ELSE 1 
        END) as risk_score
      FROM medicines m
      JOIN med_ingredients mi ON m.id = mi.med_id
      JOIN interaction_rules r ON (r.ingredient1 = mi.ingredient OR r.ingredient2 = mi.ingredient)
      WHERE LOWER(r.severity) IN ('contraindicated', 'severe', 'major')
      GROUP BY m.id
      ORDER BY risk_score DESC
      LIMIT 10
    ''');
  print('High risk drugs found with case-insensitive query: ${maps2.length}');
}
