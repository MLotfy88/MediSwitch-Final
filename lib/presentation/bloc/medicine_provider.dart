import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'package:dartz/dartz.dart'; // Import dartz for Either
import '../../core/error/failures.dart'; // Import Failure base class
import '../../domain/entities/drug_entity.dart'; // Import DrugEntity
import '../../domain/usecases/get_all_drugs.dart';
import '../../domain/usecases/search_drugs.dart';
import '../../domain/usecases/filter_drugs_by_category.dart';
import '../../domain/usecases/get_available_categories.dart';
import '../../core/usecases/usecase.dart'; // For NoParams

class MedicineProvider extends ChangeNotifier {
  final GetAllDrugs getAllDrugsUseCase;
  final SearchDrugsUseCase searchDrugsUseCase;
  final FilterDrugsByCategoryUseCase filterDrugsByCategoryUseCase;
  final GetAvailableCategoriesUseCase getAvailableCategoriesUseCase;

  // State variables - now using DrugEntity
  List<DrugEntity> _medicines = [];
  List<DrugEntity> _filteredMedicines = [];
  List<String> _categories = []; // Keep categories as String for now
  String _searchQuery = '';
  String _selectedCategory = '';
  bool _isLoading = true;
  String _error = '';

  // Constructor injection for the UseCases (replace with DI later)
  MedicineProvider({
    required this.getAllDrugsUseCase,
    required this.searchDrugsUseCase,
    required this.filterDrugsByCategoryUseCase,
    required this.getAvailableCategoriesUseCase,
  }) {
    loadInitialData(); // Renamed for clarity
  }

  // Getters - expose DrugEntity lists
  List<DrugEntity> get medicines => _medicines;
  List<DrugEntity> get filteredMedicines => _filteredMedicines;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Renamed to reflect loading both drugs and categories
  Future<void> loadInitialData() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    // Load drugs first
    final failureOrDrugs = await getAllDrugsUseCase(
      NoParams(),
    ); // Pass NoParams

    failureOrDrugs.fold(
      (failure) {
        // Handle Failure case
        _error = _mapFailureToMessage(failure);
        _medicines = []; // Clear data on failure
        _filteredMedicines = [];
        _categories = [];
      },
      (drugs) async {
        // Make the success callback async
        // Handle Success case
        _medicines = drugs;
        _filteredMedicines = drugs; // Initially show all
        _error = '';
        // Now load categories after drugs are loaded
        await _loadCategories(); // This await is now valid
        await _applyFilters(); // Also await this async function
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Helper to load categories using the UseCase
  Future<void> _loadCategories() async {
    // Add async keyword
    final failureOrCategories = await getAvailableCategoriesUseCase(NoParams());
    failureOrCategories.fold(
      (failure) {
        // Handle category loading failure (maybe log, show partial error?)
        print("Error loading categories: ${_mapFailureToMessage(failure)}");
        _categories = []; // Set categories to empty on failure
      },
      (categories) {
        _categories = categories;
      },
    );
    // No need to notifyListeners here, loadInitialData will do it.
  }

  Future<void> setSearchQuery(String query) async {
    // Make async
    _searchQuery = query;
    await _applyFilters(); // Await the async filter operation
    // No need to notifyListeners here, _applyFilters does it
  }

  Future<void> setCategory(String category) async {
    // Make async
    _selectedCategory = category;
    await _applyFilters(); // Await the async filter operation
    // No need to notifyListeners here, _applyFilters does it
  }

  // Apply filters using UseCases
  Future<void> _applyFilters() async {
    _isLoading = true; // Indicate loading during filtering
    _error = '';
    notifyListeners();

    Either<Failure, List<DrugEntity>> result;

    if (_searchQuery.isEmpty && _selectedCategory.isEmpty) {
      // No filters, show all original medicines
      result = Right(_medicines);
    } else if (_searchQuery.isNotEmpty && _selectedCategory.isEmpty) {
      // Only search query
      result = await searchDrugsUseCase(SearchParams(query: _searchQuery));
    } else if (_searchQuery.isEmpty && _selectedCategory.isNotEmpty) {
      // Only category filter
      result = await filterDrugsByCategoryUseCase(
        FilterParams(category: _selectedCategory),
      );
    } else {
      // Both search query and category filter
      // 1. Search first
      result = await searchDrugsUseCase(SearchParams(query: _searchQuery));
      // 2. Filter search results locally by category
      result = result.fold(
        (failure) => Left(failure), // Pass search failure through
        (searchedDrugs) {
          final lowerCaseCategory = _selectedCategory.toLowerCase();
          final filtered =
              searchedDrugs.where((drug) {
                final mainCatLower = (drug.mainCategory ?? '').toLowerCase();
                return mainCatLower == lowerCaseCategory;
              }).toList();
          return Right(filtered); // Return the locally filtered list
        },
      );
    }

    // Update state based on the result
    result.fold(
      (failure) {
        _error = "خطأ في الفلترة: ${_mapFailureToMessage(failure)}";
        _filteredMedicines = []; // Clear results on error
      },
      (filteredDrugs) {
        _filteredMedicines = filteredDrugs;
        _error = ''; // Clear error on success
      },
    );

    _isLoading = false;
    notifyListeners();
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
