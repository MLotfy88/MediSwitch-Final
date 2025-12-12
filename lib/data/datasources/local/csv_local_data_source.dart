import 'dart:async';
import 'dart:io'; // Import for File operations

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart'; // Import for compute
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart'; // Import path_provider
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

import '../../models/medicine_model.dart';

// --- Constants ---
const String _localCsvFileName = 'meds_local.csv';
const String _prefsKeyLastUpdate = 'csv_last_update_timestamp';

// --- Data Structure for Parsed Data + Indices ---
class ParsedMedicineData {
  final List<MedicineModel> medicines;
  final Map<String, List<int>> indexByTradeName;
  final Map<String, List<int>> indexByArabicName;
  final Map<String, List<int>> indexByActiveIngredient;
  final Map<String, List<int>>
  indexByCategory; // Includes main and sub categories

  ParsedMedicineData({
    required this.medicines,
    required this.indexByTradeName,
    required this.indexByArabicName,
    required this.indexByActiveIngredient,
    required this.indexByCategory,
  });
}

// --- Top-level Parsing Function (Modified to return ParsedMedicineData) ---
ParsedMedicineData _parseCsvData(String rawCsv) {
  final List<List<dynamic>> csvTable = const CsvToListConverter(
    fieldDelimiter: ',',
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(rawCsv);

  if (csvTable.isNotEmpty) {
    csvTable.removeAt(0);
  }

  final medicines =
      csvTable.map((row) {
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
          concentration: row.length > 17 ? row[17]?.toString() ?? '' : '',
          imageUrl: row.length > 18 ? row[18]?.toString() : null,
        );
      }).toList();

  print(
    'Parsed ${medicines.length} medicines from CSV in isolate. Building indices...',
  );

  // --- Build Indices ---
  final Map<String, List<int>> indexByTradeName = {};
  final Map<String, List<int>> indexByArabicName = {};
  final Map<String, List<int>> indexByActiveIngredient = {};
  final Map<String, List<int>> indexByCategory = {};

  for (int i = 0; i < medicines.length; i++) {
    final med = medicines[i];

    // Index by Trade Name (lowercase)
    final tradeNameLower = med.tradeName.toLowerCase();
    if (tradeNameLower.isNotEmpty) {
      indexByTradeName.putIfAbsent(tradeNameLower, () => []).add(i);
    }

    // Index by Arabic Name (lowercase)
    final arabicNameLower = med.arabicName.toLowerCase();
    if (arabicNameLower.isNotEmpty) {
      indexByArabicName.putIfAbsent(arabicNameLower, () => []).add(i);
    }

    // Index by Active Ingredient (lowercase)
    final activeLower = med.active.toLowerCase();
    if (activeLower.isNotEmpty) {
      indexByActiveIngredient.putIfAbsent(activeLower, () => []).add(i);
    }

    // Index by Category (Main and Sub, lowercase)
    final mainCatLower = med.mainCategory.toLowerCase();
    if (mainCatLower.isNotEmpty) {
      indexByCategory.putIfAbsent(mainCatLower, () => []).add(i);
    }
    final catLower = med.category.toLowerCase();
    // Avoid adding duplicates if main and sub are the same (or sub is empty)
    if (catLower.isNotEmpty && catLower != mainCatLower) {
      indexByCategory.putIfAbsent(catLower, () => []).add(i);
    }
  }

  print('Indices built.');

  return ParsedMedicineData(
    medicines: medicines,
    indexByTradeName: indexByTradeName,
    indexByArabicName: indexByArabicName,
    indexByActiveIngredient: indexByActiveIngredient,
    indexByCategory: indexByCategory,
  );
}

// --- CsvLocalDataSource Class (Modified) ---
class CsvLocalDataSource {
  static final CsvLocalDataSource _instance = CsvLocalDataSource._internal();
  ParsedMedicineData?
  _parsedData; // In-memory cache for parsed data and indices

  factory CsvLocalDataSource() {
    return _instance;
  }

  CsvLocalDataSource._internal();

  // --- Helper Methods ---
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_localCsvFileName');
  }

  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // --- Core Logic ---

  // Gets the timestamp of the last update (from prefs)
  Future<int?> getLastUpdateTimestamp() async {
    final prefs = await _prefs;
    return prefs.getInt(_prefsKeyLastUpdate);
  }

  // Saves the initial asset CSV to local storage
  Future<void> _cacheInitialAsset() async {
    try {
      print('Caching initial CSV from assets...');
      final rawCsv = await rootBundle.loadString('assets/meds.csv');
      final file = await _localFile;
      await file.writeAsString(rawCsv);
      final prefs = await _prefs;
      await prefs.setInt(
        _prefsKeyLastUpdate,
        DateTime.now().millisecondsSinceEpoch,
      );
      print('Initial CSV cached successfully.');
    } catch (e) {
      print('Error caching initial CSV: $e');
      // Decide how to handle this - maybe rethrow or return a failure state
      rethrow;
    }
  }

  // Reads CSV data either from local file or initial asset
  Future<String> _readCsvData() async {
    final file = await _localFile;
    if (await file.exists()) {
      print('Reading CSV from local file...');
      return await file.readAsString();
    } else {
      print('Local CSV not found, loading from assets...');
      await _cacheInitialAsset(); // Cache it first
      return await file.readAsString(); // Now read the newly cached file
    }
  }

  // Load and parse the CSV data, now returns ParsedMedicineData
  Future<ParsedMedicineData> _loadAndParseData() async {
    if (_parsedData != null) {
      return _parsedData!; // Return in-memory cache if available
    }

    try {
      final rawCsv =
          await _readCsvData(); // Read from local file or cache asset
      _parsedData = await compute(
        _parseCsvData,
        rawCsv,
      ); // Parse and build indices in isolate
      return _parsedData!;
    } catch (e) {
      print('Error loading or parsing CSV: $e');
      rethrow;
    }
  }

  // --- Public API Methods (Modified to use indices) ---

  // Get all medicines
  Future<List<MedicineModel>> getAllMedicines() async {
    final data = await _loadAndParseData();
    return data.medicines;
  }

  // Search medicines using indices
  Future<List<MedicineModel>> searchMedicinesByName(String query) async {
    final data = await _loadAndParseData();
    if (query.isEmpty) return data.medicines;

    final lowerCaseQuery = query.toLowerCase();
    final Set<int> matchingIndices = {}; // Use a Set to avoid duplicates

    // Search Trade Name Index
    data.indexByTradeName.forEach((key, indices) {
      if (key.contains(lowerCaseQuery)) {
        matchingIndices.addAll(indices);
      }
    });

    // Search Arabic Name Index
    data.indexByArabicName.forEach((key, indices) {
      if (key.contains(lowerCaseQuery)) {
        matchingIndices.addAll(indices);
      }
    });

    // Search Active Ingredient Index (Optional: Add if needed for general search)
    // data.indexByActiveIngredient.forEach((key, indices) {
    //   if (key.contains(lowerCaseQuery)) {
    //     matchingIndices.addAll(indices);
    //   }
    // });

    // Retrieve medicines based on unique indices
    return matchingIndices.map((index) => data.medicines[index]).toList();
  }

  // Filter medicines using category index
  Future<List<MedicineModel>> filterMedicinesByCategory(String category) async {
    final data = await _loadAndParseData();
    if (category.isEmpty) return data.medicines;

    final lowerCaseCategory = category.toLowerCase();
    final List<int>? indices = data.indexByCategory[lowerCaseCategory];

    if (indices == null || indices.isEmpty) {
      return []; // No medicines found for this category
    }

    // Retrieve medicines based on indices
    return indices.map((index) => data.medicines[index]).toList();
  }

  // Get available categories using index keys
  Future<List<String>> getAvailableCategories() async {
    final data = await _loadAndParseData();
    // Extract unique categories from the index keys
    // Note: This gets the lowercase keys used in the index.
    // We might want to retrieve the original casing from the MedicineModel if needed for display.
    final categories = data.indexByCategory.keys.toList();
    categories.sort(); // Sort alphabetically
    return categories;
    /*
    // Alternative: Get original casing from the first medicine in each category index
    final categoriesMap = <String, String>{}; // lowercase -> original case
    data.indexByCategory.forEach((key, indices) {
      if (indices.isNotEmpty) {
        final med = data.medicines[indices.first];
        // Prefer main category casing if available
        final mainCat = med.mainCategory ?? '';
        final cat = med.category ?? '';
        if (mainCat.toLowerCase() == key) {
          categoriesMap[key] = mainCat;
        } else if (cat.toLowerCase() == key) {
           categoriesMap[key] = cat;
        } else {
           categoriesMap[key] = key; // Fallback to key if casing not found
        }
      }
    });
    final categoriesList = categoriesMap.values.toList();
    categoriesList.sort();
    return categoriesList;
    */
  }

  // Save new CSV data downloaded from remote source
  Future<void> saveDownloadedCsv(String csvData) async {
    try {
      print('Saving downloaded CSV data to local storage...');
      final file = await _localFile;
      await file.writeAsString(csvData);

      // Update the timestamp in shared preferences
      final prefs = await _prefs;
      await prefs.setInt(
        _prefsKeyLastUpdate,
        DateTime.now().millisecondsSinceEpoch,
      );

      // Clear the in-memory cache to force reload and re-indexing
      _parsedData = null;

      print(
        'Downloaded CSV saved successfully. Cache cleared for re-indexing.',
      );
    } catch (e) {
      print('Error saving downloaded CSV: $e');
      rethrow;
    }
  }
}
