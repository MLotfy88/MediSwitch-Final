import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../models/medicine.dart'; // Assuming Medicine model exists

class CsvService {
  static final CsvService _instance = CsvService._internal();
  List<Medicine>? _medicines; // Cache the parsed medicines

  factory CsvService() {
    return _instance;
  }

  CsvService._internal();

  // Load and parse the CSV data
  Future<List<Medicine>> _loadMedicines() async {
    if (_medicines != null) {
      return _medicines!; // Return cached data if available
    }

    try {
      final rawCsv = await rootBundle.loadString('assets/meds.csv');
      // Use CsvToListConverter, explicitly set delimiter and eol
      final List<List<dynamic>> csvTable = const CsvToListConverter(
        fieldDelimiter: ',', // Explicitly set comma as delimiter
        eol: '\n', // Explicitly set newline as end-of-line
        shouldParseNumbers: false, // Treat all fields as strings initially
      ).convert(rawCsv);

      // Remove header row if it exists (assuming first row is header)
      if (csvTable.isNotEmpty) {
        csvTable.removeAt(0);
      }

      _medicines =
          csvTable.map((row) {
            // Map each row to a Medicine object
            // IMPORTANT: Adjust indices based on your CSV column order!
            return Medicine(
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
              // Add other fields as needed based on CSV structure
            );
          }).toList();

      print(
        'Parsed ${_medicines?.length ?? 0} medicines from CSV.',
      ); // Add print statement

      return _medicines!;
    } catch (e) {
      print('Error loading or parsing CSV: $e');
      // Re-throw the error so the provider can catch it and display it
      rethrow;
    }
  }

  // Get all medicines
  Future<List<Medicine>> getAllMedicines() async {
    return await _loadMedicines();
  }

  // Search medicines by name (case-insensitive)
  Future<List<Medicine>> searchMedicinesByName(String query) async {
    final allMedicines = await _loadMedicines();
    if (query.isEmpty) {
      return allMedicines;
    }
    final lowerCaseQuery = query.toLowerCase();
    return allMedicines.where((med) {
      return med.tradeName.toLowerCase().contains(lowerCaseQuery) ||
          med.arabicName.toLowerCase().contains(lowerCaseQuery);
    }).toList();
  }

  // Filter medicines by category (case-insensitive)
  Future<List<Medicine>> filterMedicinesByCategory(String category) async {
    final allMedicines = await _loadMedicines();
    if (category.isEmpty) {
      return allMedicines;
    }
    final lowerCaseCategory = category.toLowerCase();
    return allMedicines.where((med) {
      return med.mainCategory.toLowerCase() == lowerCaseCategory ||
          med.category.toLowerCase() == lowerCaseCategory;
    }).toList();
  }

  // Get unique main categories
  Future<List<String>> getAvailableCategories() async {
    final allMedicines = await _loadMedicines();
    final categories =
        allMedicines
            .map((med) => med.mainCategory)
            .where((cat) => cat.isNotEmpty) // Filter out empty categories
            .toSet() // Get unique categories
            .toList();
    categories.sort(); // Optional: sort alphabetically
    return categories;
  }

  // Note: Getting medicine by ID is inefficient with CSV.
  // Consider searching by a unique field like tradeName if needed.
  // Future<Medicine?> getMedicationById(int id) async { ... }
}
