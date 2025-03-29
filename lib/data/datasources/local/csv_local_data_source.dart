import 'dart:async';
import 'package:flutter/foundation.dart'; // Import for compute
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../../models/medicine_model.dart'; // Corrected path and model name

// Top-level function for parsing CSV data in an isolate
List<MedicineModel> _parseCsvData(String rawCsv) {
  final List<List<dynamic>> csvTable = const CsvToListConverter(
    fieldDelimiter: ',',
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(rawCsv);

  // Remove header row if it exists
  if (csvTable.isNotEmpty) {
    csvTable.removeAt(0);
  }

  final medicines =
      csvTable.map((row) {
        // Map each row to a MedicineModel object
        return MedicineModel(
          tradeName: row.length > 0 ? row[0]?.toString() ?? '' : '',
          arabicName: row.length > 1 ? row[1]?.toString() ?? '' : '',
          oldPrice: row.length > 2 ? row[2]?.toString() ?? '' : '',
          price: row.length > 3 ? row[3]?.toString() ?? '' : '',
          active: row.length > 4 ? row[4]?.toString() ?? '' : '',
          mainCategory: row.length > 5 ? row[5]?.toString() ?? '' : '',
          mainCategoryAr: row.length > 6 ? row[6]?.toString() ?? '' : '',
          category: row.length > 7 ? row[7]?.toString() ?? '' : '',
          categoryAr: row.length > 8 ? row[8]?.toString() ?? '' : '',
          company: row.length > 9 ? row[9]?.toString() ?? '' : '',
          dosageForm: row.length > 10 ? row[10]?.toString() ?? '' : '',
          dosageFormAr: row.length > 11 ? row[11]?.toString() ?? '' : '',
          unit: row.length > 12 ? row[12]?.toString() ?? '' : '',
          usage: row.length > 13 ? row[13]?.toString() ?? '' : '',
          usageAr: row.length > 14 ? row[14]?.toString() ?? '' : '',
          description: row.length > 15 ? row[15]?.toString() ?? '' : '',
          lastPriceUpdate: row.length > 16 ? row[16]?.toString() ?? '' : '',
        );
      }).toList();

  print(
    'Parsed ${medicines.length} medicines from CSV in isolate.', // Updated print
  );
  return medicines;
}

class CsvLocalDataSource {
  static final CsvLocalDataSource _instance = CsvLocalDataSource._internal();
  List<MedicineModel>? _medicines; // Cache the parsed medicines

  factory CsvLocalDataSource() {
    return _instance;
  }

  CsvLocalDataSource._internal();

  // Load and parse the CSV data using compute
  Future<List<MedicineModel>> _loadMedicines() async {
    if (_medicines != null) {
      return _medicines!; // Return cached data if available
    }

    try {
      final rawCsv = await rootBundle.loadString('assets/meds.csv');
      // Use compute to parse the data in a separate isolate
      _medicines = await compute(_parseCsvData, rawCsv);
      return _medicines!;
    } catch (e) {
      print('Error loading or parsing CSV: $e');
      // Re-throw the error so the provider can catch it and display it
      rethrow;
    }
  }

  // Get all medicines
  Future<List<MedicineModel>> getAllMedicines() async {
    return await _loadMedicines();
  }

  // Search medicines by name (case-insensitive)
  Future<List<MedicineModel>> searchMedicinesByName(String query) async {
    final allMedicines = await _loadMedicines(); // Ensure data is loaded
    if (query.isEmpty) {
      return allMedicines;
    }
    final lowerCaseQuery = query.toLowerCase();
    // Add null safety checks here as well
    return allMedicines.where((med) {
      final tradeNameLower = (med.tradeName ?? '').toLowerCase();
      final arabicNameLower = (med.arabicName ?? '').toLowerCase();
      return tradeNameLower.contains(lowerCaseQuery) ||
          arabicNameLower.contains(lowerCaseQuery);
    }).toList();
  }

  // Filter medicines by category (case-insensitive)
  Future<List<MedicineModel>> filterMedicinesByCategory(String category) async {
    final allMedicines = await _loadMedicines(); // Ensure data is loaded
    if (category.isEmpty) {
      return allMedicines;
    }
    final lowerCaseCategory = category.toLowerCase();
    // Add null safety checks here as well
    return allMedicines.where((med) {
      final mainCatLower = (med.mainCategory ?? '').toLowerCase();
      final catLower = (med.category ?? '').toLowerCase();
      return mainCatLower == lowerCaseCategory || catLower == lowerCaseCategory;
    }).toList();
  }

  // Get unique main categories
  Future<List<String>> getAvailableCategories() async {
    final allMedicines = await _loadMedicines(); // Ensure data is loaded
    final categories =
        allMedicines
            .map((med) => med.mainCategory)
            // Add null safety check for category string before checking isNotEmpty
            .where((cat) => cat != null && cat.isNotEmpty)
            .toSet() // Get unique categories
            .toList();
    categories.sort(); // Optional: sort alphabetically
    return categories;
  }

  // Note: Getting medicine by ID is inefficient with CSV.
  // Consider searching by a unique field like tradeName if needed.
  // Future<Medicine?> getMedicationById(int id) async { ... }
}
