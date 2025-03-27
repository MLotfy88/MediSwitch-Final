import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/csv_service.dart';
import 'models/medicine.dart';
// import 'screens/home_screen.dart'; // No longer the direct home
import 'screens/main_screen.dart'; // Import the main navigation screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MedicineProvider(),
      child: MaterialApp(
        title: 'MediSwitch',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Arial',
          useMaterial3: true,
        ),
        home: const MainScreen(), // Use MainScreen as the home widget
      ),
    );
  }
}

class MedicineProvider extends ChangeNotifier {
  final CsvService _csvService = CsvService();
  List<Medicine> _medicines = []; // Full list from CSV
  List<Medicine> _filteredMedicines = []; // Filtered list for display
  List<String> _categories = []; // Unique categories from CSV
  String _searchQuery = '';
  String _selectedCategory = '';
  bool _isLoading = true;
  String _error = '';

  List<Medicine> get medicines =>
      _medicines; // Expose full list if needed elsewhere
  List<Medicine> get filteredMedicines => _filteredMedicines; // List for UI
  List<String> get categories => _categories; // Expose categories for UI
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  MedicineProvider() {
    loadMedicines();
  }

  Future<void> loadMedicines() async {
    try {
      _isLoading = true;
      _error = ''; // Clear previous errors
      notifyListeners();

      // Load all medicines initially
      _medicines = await _csvService.getAllMedicines();
      // Load categories
      _categories = await _csvService.getAvailableCategories();
      // Apply initial filters (which might be none) - No longer async
      _applyFilters(); // This will set _filteredMedicines
      _error = '';
    } catch (e) {
      _error = 'حدث خطأ أثناء تحميل البيانات: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters (can be sync now as data is in memory)
  void _applyFilters() {
    // Start with all medicines loaded in memory
    List<Medicine> results = _medicines;

    try {
      // Apply category filter first if selected
      if (_selectedCategory.isNotEmpty) {
        final lowerCaseCategory = _selectedCategory.toLowerCase();
        results =
            results.where((med) {
              return med.mainCategory.toLowerCase() == lowerCaseCategory ||
                  med.category.toLowerCase() == lowerCaseCategory;
            }).toList();
      }

      // Apply search query filter to the results of the category filter (or all if no category)
      if (_searchQuery.isNotEmpty) {
        final lowerCaseQuery = _searchQuery.toLowerCase();
        // Filter the current 'results' list directly
        results =
            results.where((med) {
              return med.tradeName.toLowerCase().contains(lowerCaseQuery) ||
                  med.arabicName.toLowerCase().contains(lowerCaseQuery);
            }).toList();
      }

      _filteredMedicines = results; // Update the list for the UI
      _error = ''; // Clear error on successful filter
    } catch (e) {
      _error = 'حدث خطأ أثناء تطبيق الفلاتر: $e';
      _filteredMedicines = []; // Clear results on error
    } finally {
      notifyListeners(); // Notify listeners regardless of success or failure
    }
  }
}
