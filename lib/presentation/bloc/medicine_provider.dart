import 'package:flutter/foundation.dart'; // For ChangeNotifier
import '../../core/error/failures.dart'; // Import Failure base class
import '../../domain/entities/drug_entity.dart'; // Import DrugEntity
import '../../domain/usecases/get_all_drugs.dart'; // Import UseCase
// Removed direct data source/model imports

class MedicineProvider extends ChangeNotifier {
  final GetAllDrugs getAllDrugsUseCase; // Depend on UseCase

  // State variables - now using DrugEntity
  List<DrugEntity> _medicines = [];
  List<DrugEntity> _filteredMedicines = [];
  List<String> _categories = []; // Keep categories as String for now
  String _searchQuery = '';
  String _selectedCategory = '';
  bool _isLoading = true;
  String _error = '';

  // Constructor injection for the UseCase (replace with DI later)
  MedicineProvider({required this.getAllDrugsUseCase}) {
    loadMedicines();
  }

  // Getters - expose DrugEntity lists
  List<DrugEntity> get medicines => _medicines;
  List<DrugEntity> get filteredMedicines => _filteredMedicines;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  Future<void> loadMedicines() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    final failureOrDrugs = await getAllDrugsUseCase(); // Call the use case

    failureOrDrugs.fold(
      (failure) {
        // Handle Failure case
        _error = _mapFailureToMessage(failure);
        _medicines = []; // Clear data on failure
        _filteredMedicines = [];
        _categories = [];
      },
      (drugs) {
        // Handle Success case
        _medicines = drugs;
        _filteredMedicines = drugs; // Initially show all
        _extractCategories(); // Extract categories from loaded entities
        _error = '';
        _applyFilters(); // Apply initial filters if any (search/category might be pre-set)
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Helper to extract unique categories from DrugEntity list
  void _extractCategories() {
    if (_medicines.isEmpty) {
      _categories = [];
      return;
    }
    final categorySet =
        _medicines
            .map((drug) => drug.mainCategory)
            .where((cat) => cat.isNotEmpty) // Filter out empty strings
            .toSet();
    _categories = categorySet.toList()..sort();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    // No need to notifyListeners here, _applyFilters does it
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    // No need to notifyListeners here, _applyFilters does it
  }

  // Apply filters based on DrugEntity
  void _applyFilters() {
    List<DrugEntity> results = _medicines;

    try {
      // Apply category filter
      if (_selectedCategory.isNotEmpty) {
        final lowerCaseCategory = _selectedCategory.toLowerCase();
        results =
            results.where((drug) {
              // Already checked for null/empty in _extractCategories, but good practice
              final mainCatLower = (drug.mainCategory ?? '').toLowerCase();
              return mainCatLower == lowerCaseCategory;
            }).toList();
      }

      // Apply search query filter
      if (_searchQuery.isNotEmpty) {
        final lowerCaseQuery = _searchQuery.toLowerCase();
        results =
            results.where((drug) {
              final tradeNameLower = (drug.tradeName ?? '').toLowerCase();
              final arabicNameLower = (drug.arabicName ?? '').toLowerCase();
              return tradeNameLower.contains(lowerCaseQuery) ||
                  arabicNameLower.contains(lowerCaseQuery);
            }).toList();
      }

      _filteredMedicines = results;
      _error = ''; // Clear error on successful filter
    } catch (e) {
      _error = 'حدث خطأ أثناء تطبيق الفلاتر: $e';
      _filteredMedicines = []; // Clear results on error
    } finally {
      notifyListeners(); // Notify listeners after filtering
    }
  }

  // Helper to map Failure types to user-friendly messages
  String _mapFailureToMessage(Failure failure) {
    // Add more specific messages based on Failure types later
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'خطأ في تحميل البيانات المحلية.';
      // case ServerFailure:
      //   return 'خطأ في الاتصال بالخادم.';
      default:
        return 'حدث خطأ غير متوقع.';
    }
  }
}
