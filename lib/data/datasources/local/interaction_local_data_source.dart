import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../domain/entities/drug_interaction.dart'; // Assuming path
import '../../../domain/entities/active_ingredient.dart'; // Assuming path

// Abstract class defining the contract
abstract class InteractionLocalDataSource {
  Future<List<DrugInteraction>> loadDrugInteractions();
  Future<List<ActiveIngredient>> loadActiveIngredients();
  Future<Map<String, List<String>>> loadMedicineToIngredientsMap();
}

// Implementation loading from asset JSON files
class InteractionLocalDataSourceImpl implements InteractionLocalDataSource {
  @override
  Future<List<DrugInteraction>> loadDrugInteractions() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/drug_interactions.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => DrugInteraction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading drug_interactions.json: $e');
      // Consider throwing a specific exception type
      throw Exception('Failed to load drug interactions data.');
    }
  }

  @override
  Future<List<ActiveIngredient>> loadActiveIngredients() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/active_ingredients.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      // Assuming ActiveIngredient.fromJson exists and takes Map<String, dynamic>
      return jsonList
          .map(
            (json) => ActiveIngredient.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error loading active_ingredients.json: $e');
      throw Exception('Failed to load active ingredients data.');
    }
  }

  @override
  Future<Map<String, List<String>>> loadMedicineToIngredientsMap() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/medicine_ingredients.json',
      );
      // The JSON structure is assumed to be Map<String, List<dynamic>> which needs conversion
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;
      // Convert the List<dynamic> to List<String> for each entry
      final Map<String, List<String>> resultMap = jsonMap.map(
        (key, value) =>
            MapEntry(key, List<String>.from(value as List<dynamic>)),
      );
      return resultMap;
    } catch (e) {
      print('Error loading medicine_ingredients.json: $e');
      throw Exception('Failed to load medicine to ingredients mapping.');
    }
  }
}
