import 'package:flutter/widgets.dart';
import 'package:mediswitch/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;

  print("--- DUMPING drug_interactions SAMPLE ---");
  try {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM drug_interactions'),
    );
    print('Total rows: $count');

    final rows = await db.rawQuery('SELECT * FROM drug_interactions LIMIT 10');
    for (var row in rows) {
      print('Row: $row');
    }

    print("\n--- CHECKING DISTINCT SEVERITIES ---");
    final severities = await db.rawQuery(
      'SELECT DISTINCT severity FROM drug_interactions',
    );
    for (var s in severities) {
      print('Severity: "${s['severity']}"');
    }
  } catch (e) {
    print("Error: $e");
  }
}
