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

// Add mounted check mixin for safety with async operations
class MedicineProvider extends ChangeNotifier with DiagnosticableTreeMixin {
  final GetAllDrugs getAllDrugsUseCase; // Keep for update check trigger
  final SearchDrugsUseCase searchDrugsUseCase;
  final FilterDrugsByCategoryUseCase filterDrugsByCategoryUseCase;
  final GetAvailableCategoriesUseCase getAvailableCategoriesUseCase;
  final GetLastUpdateTimestampUseCase getLastUpdateTimestampUseCase;
  final GetAnalyticsSummary getAnalyticsSummaryUseCase;

  // State variables
  List<DrugEntity> _filteredMedicines = [];
  List<String> _categories = [];
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedDosageForm = '';
  RangeValues? _selectedPriceRange;
  double _minPrice = 0;
  double _maxPrice = 1000;
  bool _isLoading = true;
  String _error = '';
  int? _lastUpdateTimestamp;

  // Flag to track if initial load is complete
  bool _isInitialLoadComplete = false;
  bool get isInitialLoadComplete => _isInitialLoadComplete;

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
  List<DrugEntity> get filteredMedicines => _filteredMedicines;
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
      return DateFormat('yyyy-MM-dd HH:mm', 'en').format(dateTime);
    } catch (e) {
      print("Error formatting timestamp: $e");
      return 'تنسيق غير صالح';
    }
  }

  // Load initial necessary data (categories, timestamp) and trigger initial filter
  Future<void> loadInitialData() async {
    // Prevent multiple simultaneous initial loads
    if (_isLoading && _isInitialLoadComplete) return;

    print("MedicineProvider: loadInitialData called (Original Logic)");
    _isLoading = true;
    _error = '';
    _isInitialLoadComplete = false; // Mark as loading
    // Use WidgetsBinding only if called from constructor context might be unsafe
    // notifyListeners(); // Notify immediately might be too early

    // Ensure listeners are notified safely after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isLoading) {
        // Check if still loading
        notifyListeners();
      }
    });

    // Trigger update check (getAllDrugs in repo now handles this)
    final updateResult = await getAllDrugsUseCase(NoParams());

    // Regardless of update success/failure, load categories and timestamp
    await _loadCategories();
    await _loadAndUpdateTimestamp();

    // Apply initial filters (fetching initial view)
    await _applyFilters(); // This will set isLoading = false and notify

    // Handle potential failure from the update check *after* attempting initial filter/load
    updateResult.fold(
      (failure) {
        // Set error state, _applyFilters would have already set isLoading=false
        _error = "فشل التحقق من التحديثات: ${_mapFailureToMessage(failure)}";
        print(_error);
        notifyListeners(); // Notify about the error
      },
      (_) {
        // Update successful or not needed, state already handled by _applyFilters
        print("MedicineProvider: Update check successful or not needed.");
      },
    );

    _isInitialLoadComplete = true; // Mark initial load as complete

    // Ensure loading is false if _applyFilters didn't run or failed early
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
    print("MedicineProvider: loadInitialData finished (Original Logic)");
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
    // Don't notify here, let loadInitialData handle it
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
    // Don't notify here, let loadInitialData handle it
  }

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
    notifyListeners(); // Notify that filtering started

    Either<Failure, List<DrugEntity>> result;

    // Determine base query: search or category filter takes precedence
    if (_searchQuery.isNotEmpty) {
      result = await searchDrugsUseCase(SearchParams(query: _searchQuery));
    } else if (_selectedCategory.isNotEmpty) {
      result = await filterDrugsByCategoryUseCase(
        FilterParams(category: _selectedCategory),
      );
    } else {
      // No primary filter, fetch an initial limited set
      const initialLimit = 50; // Define a limit for the initial load
      result = await searchDrugsUseCase(
        SearchParams(query: '', limit: initialLimit),
      );
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
        // For simplicity, keep global min/max for now.
      },
    );

    _isLoading = false;
    notifyListeners(); // Notify that filtering finished
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'خطأ في الوصول للبيانات المحلية.';
      case InitialLoadFailure:
        return 'فشل تحميل البيانات الأولية. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
      case ServerFailure:
        return 'خطأ في الاتصال بالخادم.';
      case NetworkFailure:
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

  // Add DiagnosticableTreeMixin methods
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      IterableProperty<DrugEntity>('filteredMedicines', _filteredMedicines),
    );
    properties.add(IterableProperty<String>('categories', _categories));
    properties.add(StringProperty('searchQuery', _searchQuery));
    properties.add(StringProperty('selectedCategory', _selectedCategory));
    properties.add(
      DiagnosticsProperty<RangeValues>(
        'selectedPriceRange',
        _selectedPriceRange,
      ),
    );
    properties.add(DoubleProperty('minPrice', _minPrice));
    properties.add(DoubleProperty('maxPrice', _maxPrice));
    properties.add(
      FlagProperty('isLoading', value: _isLoading, ifTrue: 'LOADING'),
    );
    properties.add(StringProperty('error', _error, defaultValue: ''));
    properties.add(IntProperty('lastUpdateTimestamp', _lastUpdateTimestamp));
    properties.add(
      FlagProperty(
        'isInitialLoadComplete',
        value: _isInitialLoadComplete,
        ifTrue: 'LOADED',
      ),
    );
  }
}
