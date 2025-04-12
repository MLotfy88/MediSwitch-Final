import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Import Material for RangeValues
import 'package:intl/intl.dart'; // Import intl for DateFormat
import 'package:dartz/dartz.dart'; // Import dartz for Either
import '../../core/error/failures.dart'; // Import Failure base class
import '../../domain/entities/drug_entity.dart'; // Import DrugEntity
import '../../domain/usecases/get_all_drugs.dart'; // Still needed for update check logic inside repo
import '../../domain/usecases/search_drugs.dart';
import '../../domain/usecases/filter_drugs_by_category.dart';
import '../../domain/usecases/get_available_categories.dart';
import '../../domain/usecases/get_last_update_timestamp.dart';
import '../../domain/usecases/get_analytics_summary.dart'; // Import analytics use case
import '../../domain/repositories/analytics_repository.dart'; // Import AnalyticsSummary entity
import '../../core/usecases/usecase.dart';

class MedicineProvider extends ChangeNotifier {
  final GetAllDrugs getAllDrugsUseCase; // Keep for update check trigger
  final SearchDrugsUseCase searchDrugsUseCase;
  final FilterDrugsByCategoryUseCase filterDrugsByCategoryUseCase;
  final GetAvailableCategoriesUseCase getAvailableCategoriesUseCase;
  final GetLastUpdateTimestampUseCase getLastUpdateTimestampUseCase;
  final GetAnalyticsSummary getAnalyticsSummaryUseCase;

  // State variables
  // List<DrugEntity> _medicines = []; // Removed: No longer caching all medicines
  List<DrugEntity> _filteredMedicines =
      []; // Holds the currently displayed/filtered list
  // List<DrugEntity> _recentlyUpdatedMedicines = []; // Removed: Fetch on demand if needed
  List<String> _categories = [];
  // List<DrugEntity> _popularDrugs = []; // Removed: Fetch on demand if needed
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedDosageForm = '';
  RangeValues? _selectedPriceRange;
  double _minPrice = 0;
  double _maxPrice = 1000;
  bool _isLoading = true;
  String _error = '';
  int? _lastUpdateTimestamp;

  MedicineProvider({
    required this.getAllDrugsUseCase,
    required this.searchDrugsUseCase,
    required this.filterDrugsByCategoryUseCase,
    required this.getAvailableCategoriesUseCase,
    required this.getLastUpdateTimestampUseCase,
    required this.getAnalyticsSummaryUseCase,
  }) {
    loadInitialData();
  }

  // Getters
  // List<DrugEntity> get medicines => _medicines; // Removed
  List<DrugEntity> get filteredMedicines => _filteredMedicines;
  // List<DrugEntity> get recentlyUpdatedMedicines => _recentlyUpdatedMedicines; // Removed
  // List<DrugEntity> get popularDrugs => _popularDrugs; // Removed
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedDosageForm => _selectedDosageForm;
  RangeValues? get selectedPriceRange => _selectedPriceRange;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;

  String get lastUpdateTimestampFormatted {
    if (_lastUpdateTimestamp == null) return 'غير متوفر';
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(
        _lastUpdateTimestamp!,
      );
      return DateFormat('yyyy-MM-dd HH:mm', 'en').format(dateTime); // Use intl
    } catch (e) {
      print("Error formatting timestamp: $e");
      return 'تنسيق غير صالح';
    }
  }

  // Load initial necessary data (categories, timestamp) and trigger initial filter
  Future<void> loadInitialData() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    // Trigger update check (getAllDrugs in repo now handles this)
    // We don't need the result list here anymore.
    final updateResult = await getAllDrugsUseCase(NoParams());

    // Regardless of update success/failure, load categories and timestamp
    // If update failed, subsequent fetches will use potentially stale local data
    await _loadCategories();
    await _loadAndUpdateTimestamp();
    // TODO: Calculate price range based on a query or initial sample?
    // For now, keep default range until first filter/search.

    // Apply initial filters (which might be empty, fetching initial view)
    await _applyFilters();

    // Handle potential failure from the update check *after* attempting initial filter/load
    updateResult.fold(
      (failure) {
        // Show error but keep potentially loaded data from cache
        _error = "فشل التحقق من التحديثات: ${_mapFailureToMessage(failure)}";
        print(_error);
        // Don't set isLoading = false here, _applyFilters does it
        // notifyListeners(); // _applyFilters already notified
      },
      (_) {
        // Update successful or not needed, state already handled by _applyFilters
      },
    );

    // Ensure loading is set to false if not already done by _applyFilters
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCategories() async {
    final failureOrCategories = await getAvailableCategoriesUseCase(NoParams());
    failureOrCategories.fold(
      (failure) {
        print("Error loading categories: ${_mapFailureToMessage(failure)}");
        _categories = [];
      },
      (categories) {
        _categories = categories;
      },
    );
  }

  Future<void> _loadAndUpdateTimestamp() async {
    final failureOrTimestamp = await getLastUpdateTimestampUseCase(NoParams());
    failureOrTimestamp.fold(
      (failure) {
        print(
          "Error loading last update timestamp: ${_mapFailureToMessage(failure)}",
        );
        _lastUpdateTimestamp = null;
      },
      (timestamp) {
        _lastUpdateTimestamp = timestamp;
        if (kDebugMode)
          print("Last update timestamp loaded: $_lastUpdateTimestamp");
      },
    );
  }

  // Removed _populateRecentlyUpdated and _loadPopularDrugs

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await _applyFilters();
  }

  Future<void> setCategory(String category) async {
    _selectedCategory = category;
    await _applyFilters();
  }

  Future<void> setDosageForm(String dosageForm) async {
    _selectedDosageForm = dosageForm;
    await _applyFilters();
  }

  Future<void> setPriceRange(RangeValues? range) async {
    _selectedPriceRange = range;
    await _applyFilters();
  }

  // Apply filters by querying the repository
  Future<void> _applyFilters() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    Either<Failure, List<DrugEntity>> result;

    // Determine base query: search or category filter takes precedence
    if (_searchQuery.isNotEmpty) {
      result = await searchDrugsUseCase(SearchParams(query: _searchQuery));
    } else if (_selectedCategory.isNotEmpty) {
      result = await filterDrugsByCategoryUseCase(
        FilterParams(category: _selectedCategory),
      );
    } else {
      // No primary filter, fetch all (or a limited initial set)
      // No primary filter, fetch an initial limited set
      const initialLimit = 50; // Define a limit for the initial load
      result = await searchDrugsUseCase(
        SearchParams(query: '', limit: initialLimit),
      );
      // TODO: Consider adding a dedicated "get initial list" or paginated fetch later
    }

    // Apply secondary filters (dosage form, price) locally on the results
    result = result.fold((failure) => Left(failure), (drugs) {
      List<DrugEntity> filtered = List.from(drugs);

      // Apply Dosage Form Filter locally
      if (_selectedDosageForm.isNotEmpty) {
        final lowerCaseDosage = _selectedDosageForm.toLowerCase();
        filtered =
            filtered.where((drug) {
              final formLower = (drug.dosageForm ?? '').toLowerCase();
              return formLower.contains(lowerCaseDosage);
            }).toList();
      }

      // Apply Price Range Filter locally
      if (_selectedPriceRange != null) {
        filtered =
            filtered.where((drug) {
              final price = double.tryParse(drug.price);
              if (price == null) return false;
              return price >= _selectedPriceRange!.start &&
                  price <= _selectedPriceRange!.end;
            }).toList();
      }

      return Right(filtered);
    });

    // Update final state
    result.fold(
      (failure) {
        _error = "خطأ في جلب/فلترة الأدوية: ${_mapFailureToMessage(failure)}";
        _filteredMedicines = []; // Clear results on error
      },
      (filteredDrugs) {
        _filteredMedicines = filteredDrugs;
        _error = ''; // Clear error on success
        // TODO: Recalculate min/max price based on the *filtered* results?
        // Or keep the global min/max calculated once in loadInitialData?
        // For simplicity, keep global min/max for now.
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'خطأ في الوصول للبيانات المحلية.';
      case InitialLoadFailure:
        return 'فشل تحميل البيانات الأولية. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
      case ServerFailure: // Added ServerFailure case
        return 'خطأ في الاتصال بالخادم.';
      case NetworkFailure: // Added NetworkFailure case
        return 'خطأ في الشبكة. يرجى التحقق من اتصالك.';
      default:
        return 'حدث خطأ غير متوقع.';
    }
  }

  // Helper function to calculate min/max price from the loaded drug list
  void _calculatePriceRange(List<DrugEntity> drugs) {
    if (drugs.isEmpty) {
      _minPrice = 0;
      _maxPrice = 1000; // Reset to default if list is empty
      return;
    }

    double min = double.maxFinite;
    double max = 0;

    for (final drug in drugs) {
      final price = double.tryParse(drug.price);
      if (price != null) {
        if (price < min) min = price;
        if (price > max) max = price;
      }
    }

    _minPrice = (min == double.maxFinite) ? 0 : min;
    _maxPrice =
        (max == 0 || max < _minPrice)
            ? (_minPrice > 900 ? _minPrice + 100 : 1000)
            : max;
    if (_maxPrice <= _minPrice) {
      _maxPrice = _minPrice + 1;
    }

    if (kDebugMode) {
      print("Calculated Price Range: $_minPrice - $_maxPrice");
    }
  }

  // Helper function to parse date strings safely
  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(dateString);
    } catch (e) {
      try {
        return DateFormat('dd/MM/yyyy').parseStrict(dateString);
      } catch (e2) {
        if (kDebugMode) {
          print("Could not parse date: $dateString - Error: $e2");
        }
        return null;
      }
    }
  }
}
