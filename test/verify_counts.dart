import 'package:flutter/widgets.dart';
import 'package:mediswitch/core/database/database_helper.dart';
import 'package:mediswitch/data/datasources/local/sqlite_local_data_source.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();
  final ds = SqliteLocalDataSource(dbHelper: dbHelper);

  print("--- Checking High Risk Ingredients Metrics ---");
  try {
    final metrics = await ds.getHighRiskIngredientsWithMetrics(limit: 5);
    for (var m in metrics) {
      print("Ingredient: ${m['name']}, Count: ${m['totalInteractions']}");
    }
  } catch (e) {
    print("Error: $e");
  }

  print("\n--- Checking Food Interactions ---");
  // We don't have getFoodInteractionCounts yet, checking getDrugsWithFoodInteractions
  try {
    final drugs = await ds.getDrugsWithFoodInteractions(5);
    for (var d in drugs) {
      print("Drug: ${d.tradeName}, Active: ${d.active}");
    }
  } catch (e) {
    print("Error: $e");
  }
}
