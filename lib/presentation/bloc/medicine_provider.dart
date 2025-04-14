import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Import Material for RangeValues
import 'package:intl/intl.dart'; // Import intl for DateFormat
import 'package:dartz/dartz.dart'; // Import dartz for Either
import '../../core/di/locator.dart'; // Import locator
import '../../core/services/file_logger_service.dart'; // Import logger
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
  final FileLoggerService _logger =
      locator<FileLoggerService>(); // Get logger instance

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
    _logger.i("MedicineProvider: Constructor called.");
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
    } catch (e, s) {
      // Add stack trace
      _logger.e("Error formatting timestamp", e, s); // Correct parameters
      return 'تنسيق غير صالح';
    }
  }

  // Load initial necessary data (categories, timestamp) and trigger initial filter
  Future<void> loadInitialData() async {
    // Prevent multiple simultaneous initial loads
    if (_isLoading && _isInitialLoadComplete) {
      _logger.w(
        "MedicineProvider: loadInitialData called while already loading or complete. Skipping.",
      );
      return;
    }

    _logger.i("MedicineProvider: loadInitialData called (Original Logic)");
    _isLoading = true;
    _error = '';
    _isInitialLoadComplete = false; // Mark as loading

    // Ensure listeners are notified safely after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if mounted is not directly possible here, rely on provider lifecycle
      if (isLoading) {
        // Check if still loading
        _logger.v(
          "MedicineProvider: Notifying listeners (initial loading state)",
        );
        notifyListeners();
      }
    });

    // Trigger update check (getAllDrugs in repo now handles this)
    _logger.i("MedicineProvider: Triggering update check...");
    final updateResult = await getAllDrugsUseCase(NoParams());
    _logger.i("MedicineProvider: Update check finished.");

    // Regardless of update success/failure, load categories and timestamp
    _logger.i("MedicineProvider: Loading categories and timestamp...");
    await _loadCategories();
    await _loadAndUpdateTimestamp();
    _logger.i("MedicineProvider: Categories and timestamp loaded.");

    // Apply initial filters (fetching initial view)
    _logger.i("MedicineProvider: Applying initial filters...");
    await _applyFilters(); // This will set isLoading = false and notify
    _logger.i("MedicineProvider: Initial filters applied.");

    // Handle potential failure from the update check *after* attempting initial filter/load
    updateResult.fold(
      (failure) {
        _error = "فشل التحقق من التحديثات: ${_mapFailureToMessage(failure)}";
        _logger.e("MedicineProvider: Update check failed: $_error");
        notifyListeners(); // Notify about the error
      },
      (_) {
        _logger.i("MedicineProvider: Update check successful or not needed.");
      },
    );

    _isInitialLoadComplete = true; // Mark initial load as complete

    // Ensure loading is false if _applyFilters didn't run or failed early
    if (_isLoading) {
      _logger.w(
        "MedicineProvider: isLoading was still true after _applyFilters. Setting to false.",
      );
      _isLoading = false;
      notifyListeners();
    }
    _logger.i("MedicineProvider: loadInitialData finished (Original Logic)");
  }

  Future<void> _loadCategories() async {
    _logger.d("MedicineProvider: _loadCategories called.");
    final failureOrCategories = await getAvailableCategoriesUseCase(NoParams());
    failureOrCategories.fold(
      (failure) {
        _logger.e("Error loading categories: ${_mapFailureToMessage(failure)}");
        _categories = [];
      },
      (categories) {
        _logger.i(
          "MedicineProvider: Categories loaded successfully (${categories.length} items).",
        );
        _categories = categories;
      },
    );
  }

  Future<void> _loadAndUpdateTimestamp() async {
    _logger.d("MedicineProvider: _loadAndUpdateTimestamp called.");
    final failureOrTimestamp = await getLastUpdateTimestampUseCase(NoParams());
    failureOrTimestamp.fold(
      (failure) {
        _logger.e(
          "Error loading last update timestamp: ${_mapFailureToMessage(failure)}",
        );
        _lastUpdateTimestamp = null;
      },
      (timestamp) {
        _lastUpdateTimestamp = timestamp;
        _logger.i(
          "MedicineProvider: Last update timestamp loaded: $_lastUpdateTimestamp",
        );
      },
    );
  }

  Future<void> setSearchQuery(String query) async {
    _logger.d("MedicineProvider: setSearchQuery called with query: '$query'");
    _searchQuery = query;
    await _applyFilters();
  }

  Future<void> setCategory(String category) async {
    _logger.d(
      "MedicineProvider: setCategory called with category: '$category'",
    );
    _selectedCategory = category;
    await _applyFilters();
  }

  Future<void> setDosageForm(String dosageForm) async {
    _logger.d(
      "MedicineProvider: setDosageForm called with dosageForm: '$dosageForm'",
    );
    _selectedDosageForm = dosageForm;
    await _applyFilters();
  }

  Future<void> setPriceRange(RangeValues? range) async {
    _logger.d("MedicineProvider: setPriceRange called with range: $range");
    _selectedPriceRange = range;
    await _applyFilters();
  }

  // Apply filters by querying the repository
  Future<void> _applyFilters() async {
    _logger.i(
      "MedicineProvider: _applyFilters called. Query: '$_searchQuery', Category: '$_selectedCategory', Dosage: '$_selectedDosageForm', Price: $_selectedPriceRange",
    );
    _isLoading = true;
    _error = '';
    notifyListeners(); // Notify that filtering started

    Either<Failure, List<DrugEntity>> result;

    try {
      // Determine base query: search or category filter takes precedence
      if (_searchQuery.isNotEmpty) {
        _logger.d("MedicineProvider: Applying search filter...");
        result = await searchDrugsUseCase(SearchParams(query: _searchQuery));
      } else if (_selectedCategory.isNotEmpty) {
        _logger.d("MedicineProvider: Applying category filter...");
        result = await filterDrugsByCategoryUseCase(
          FilterParams(category: _selectedCategory),
        );
      } else {
        // No primary filter, fetch an initial limited set
        _logger.d("MedicineProvider: Applying initial limit filter...");
        const initialLimit = 50;
        result = await searchDrugsUseCase(
          SearchParams(query: '', limit: initialLimit),
        );
      }

      // Apply secondary filters (dosage form, price) locally on the results
      result.fold(
        (failure) {
          _logger.e(
            "MedicineProvider: Error during primary fetch: ${_mapFailureToMessage(failure)}",
          );
          // Propagate the failure
          _error = "خطأ في جلب/فلترة الأدوية: ${_mapFailureToMessage(failure)}";
          _filteredMedicines = [];
        },
        (drugs) {
          _logger.d(
            "MedicineProvider: Primary fetch successful (${drugs.length} items). Applying secondary filters...",
          );
          List<DrugEntity> filtered = List.from(drugs);

          // Apply Dosage Form Filter locally
          if (_selectedDosageForm.isNotEmpty) {
            final lowerCaseDosage = _selectedDosageForm.toLowerCase();
            _logger.v(
              "MedicineProvider: Applying dosage filter: '$lowerCaseDosage'",
            );
            filtered =
                filtered.where((drug) {
                  final formLower = (drug.dosageForm ?? '').toLowerCase();
                  return formLower.contains(lowerCaseDosage);
                }).toList();
            _logger.v(
              "MedicineProvider: After dosage filter: ${filtered.length} items.",
            );
          }

          // Apply Price Range Filter locally
          if (_selectedPriceRange != null) {
            _logger.v(
              "MedicineProvider: Applying price filter: ${_selectedPriceRange!.start} - ${_selectedPriceRange!.end}",
            );
            filtered =
                filtered.where((drug) {
                  final price = double.tryParse(drug.price);
                  if (price == null) return false;
                  return price >= _selectedPriceRange!.start &&
                      price <= _selectedPriceRange!.end;
                }).toList();
            _logger.v(
              "MedicineProvider: After price filter: ${filtered.length} items.",
            );
          }

          _filteredMedicines = filtered;
          _error = ''; // Clear error on success
          _logger.i(
            "MedicineProvider: Filtering complete. Final count: ${_filteredMedicines.length}",
          );
        },
      );
    } catch (e, s) {
      _logger.e(
        "MedicineProvider: Unexpected error during _applyFilters",
        e,
        s,
      ); // Correct parameters
      _error = "حدث خطأ غير متوقع أثناء الفلترة.";
      _filteredMedicines = [];
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify that filtering finished
      _logger.d(
        "MedicineProvider: _applyFilters finished. isLoading: $_isLoading",
      );
    }
  }

  String _mapFailureToMessage(Failure failure) {
    // Keep existing mapping
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
    // Keep existing implementation
    if (drugs.isEmpty) {
      _minPrice = 0;
      _maxPrice = 1000;
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
    _logger.d("Calculated Price Range: $_minPrice - $_maxPrice");
  }

  // Helper function to parse date strings safely
  DateTime? _parseDate(String? dateString) {
    // Keep existing implementation
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(dateString);
    } catch (e) {
      try {
        return DateFormat('dd/MM/yyyy').parseStrict(dateString);
      } catch (e2, s2) {
        // Add stack trace
        _logger.w(
          "Could not parse date: $dateString",
          e2,
          s2,
        ); // Correct parameters
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
