import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dartz/dartz.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/usecases/get_all_drugs.dart';
import '../../domain/usecases/search_drugs.dart';
import '../../domain/usecases/filter_drugs_by_category.dart';
import '../../domain/usecases/get_available_categories.dart';
import '../../domain/usecases/get_last_update_timestamp.dart';
import '../../domain/usecases/get_analytics_summary.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../core/usecases/usecase.dart';

class MedicineProvider extends ChangeNotifier with DiagnosticableTreeMixin {
  final GetAllDrugs getAllDrugsUseCase;
  final SearchDrugsUseCase searchDrugsUseCase;
  final FilterDrugsByCategoryUseCase filterDrugsByCategoryUseCase;
  final GetAvailableCategoriesUseCase getAvailableCategoriesUseCase;
  final GetLastUpdateTimestampUseCase getLastUpdateTimestampUseCase;
  final GetAnalyticsSummary getAnalyticsSummaryUseCase;
  final FileLoggerService _logger = locator<FileLoggerService>();

  // --- State variables ---
  List<DrugEntity> _filteredMedicines = [];
  List<String> _categories = [];
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedDosageForm = '';
  RangeValues? _selectedPriceRange;
  double _minPrice = 0;
  double _maxPrice = 1000;
  bool _isLoading = true; // Tracks initial loading and filter changes
  bool _isLoadingMore = false; // Tracks loading more items
  String _error = '';
  int? _lastUpdateTimestamp;
  bool _isInitialLoadComplete = false;

  // --- Pagination State ---
  static const int _pageSize = 15; // Number of items per page
  int _currentPage = 0; // Current page index (0-based)
  bool _hasMoreItems = true; // Assume there are more items initially

  // --- Getters ---
  List<DrugEntity> get filteredMedicines => _filteredMedicines;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore; // Expose loading more state
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedDosageForm => _selectedDosageForm;
  RangeValues? get selectedPriceRange => _selectedPriceRange;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  bool get hasMoreItems => _hasMoreItems; // Expose has more items state
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

  String get lastUpdateTimestampFormatted {
    if (_lastUpdateTimestamp == null) return 'غير متوفر';
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(
        _lastUpdateTimestamp!,
      );
      return DateFormat('yyyy-MM-dd HH:mm', 'en').format(dateTime);
    } catch (e, s) {
      _logger.e("Error formatting timestamp", e, s);
      return 'تنسيق غير صالح';
    }
  }

  Future<void> loadInitialData() async {
    if (_isLoading && _isInitialLoadComplete) return;

    _logger.i("MedicineProvider: loadInitialData called");
    _isLoading = true;
    _error = '';
    _isInitialLoadComplete = false;
    _currentPage = 0; // Reset page on initial load
    _hasMoreItems = true; // Assume more items exist on new load/filter
    _filteredMedicines = []; // Clear previous results immediately
    notifyListeners(); // Show loading indicator

    // Trigger update check first
    _logger.i("MedicineProvider: Triggering update check...");
    final updateResult = await getAllDrugsUseCase(NoParams());
    _logger.i("MedicineProvider: Update check finished.");

    // Load categories and timestamp regardless of update result
    _logger.i("MedicineProvider: Loading categories and timestamp...");
    await Future.wait([_loadCategories(), _loadAndUpdateTimestamp()]);
    _logger.i("MedicineProvider: Categories and timestamp loaded.");

    // Apply initial filters (fetch first page)
    _logger.i("MedicineProvider: Applying initial filters (page 0)...");
    await _applyFilters(page: 0); // Fetch page 0

    updateResult.fold(
      (failure) {
        _error = "فشل التحقق من التحديثات: ${_mapFailureToMessage(failure)}";
        _logger.e("MedicineProvider: Update check failed: $_error");
        // Don't overwrite potential data loading error from _applyFilters
      },
      (_) {
        _logger.i("MedicineProvider: Update check successful or not needed.");
      },
    );

    _isInitialLoadComplete = true;
    // _isLoading is set to false inside _applyFilters
    _logger.i("MedicineProvider: loadInitialData finished.");
    // Final notification happens in _applyFilters
  }

  Future<void> _loadCategories() async {
    // ... (keep existing implementation) ...
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
    // ... (keep existing implementation) ...
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
    _currentPage = 0; // Reset page
    _hasMoreItems = true; // Assume more items
    _filteredMedicines = []; // Clear previous results
    await _applyFilters(page: 0);
  }

  Future<void> setCategory(String category) async {
    _logger.d(
      "MedicineProvider: setCategory called with category: '$category'",
    );
    _selectedCategory = category;
    _searchQuery = ''; // Clear search query when category changes
    _currentPage = 0; // Reset page
    _hasMoreItems = true; // Assume more items
    _filteredMedicines = []; // Clear previous results
    await _applyFilters(page: 0);
  }

  Future<void> setDosageForm(String dosageForm) async {
    _logger.d(
      "MedicineProvider: setDosageForm called with dosageForm: '$dosageForm'",
    );
    _selectedDosageForm = dosageForm;
    _currentPage = 0; // Reset page
    _hasMoreItems = true; // Assume more items
    _filteredMedicines = []; // Clear previous results
    await _applyFilters(page: 0);
  }

  Future<void> setPriceRange(RangeValues? range) async {
    _logger.d("MedicineProvider: setPriceRange called with range: $range");
    _selectedPriceRange = range;
    _currentPage = 0; // Reset page
    _hasMoreItems = true; // Assume more items
    _filteredMedicines = []; // Clear previous results
    await _applyFilters(page: 0);
  }

  // --- Load More Logic ---
  Future<void> loadMoreDrugs() async {
    if (_isLoading || _isLoadingMore || !_hasMoreItems) {
      _logger.d(
        "MedicineProvider: loadMoreDrugs called but skipping. isLoading: $_isLoading, isLoadingMore: $_isLoadingMore, hasMore: $_hasMoreItems",
      );
      return; // Don't load more if already loading or no more items
    }

    _isLoadingMore = true;
    notifyListeners(); // Show loading indicator at the bottom

    _currentPage++; // Increment page index
    _logger.i("MedicineProvider: loadMoreDrugs called for page $_currentPage");

    await _applyFilters(page: _currentPage, append: true);

    _isLoadingMore = false;
    notifyListeners(); // Hide loading indicator / update list
    _logger.i(
      "MedicineProvider: loadMoreDrugs finished for page $_currentPage. hasMore: $_hasMoreItems",
    );
  }

  // Apply filters by querying the repository for a specific page
  Future<void> _applyFilters({required int page, bool append = false}) async {
    // If it's not appending, it's a new filter/initial load
    if (!append) {
      _isLoading = true;
      _error = '';
      // Don't clear _filteredMedicines here if append is false, do it in the calling methods
      notifyListeners();
    }

    final int offset = page * _pageSize;
    _logger.i(
      "MedicineProvider: _applyFilters called. Page: $page, Offset: $offset, Append: $append. Query: '$_searchQuery', Category: '$_selectedCategory'",
    );

    Either<Failure, List<DrugEntity>> result;

    try {
      // Determine base query: search or category filter takes precedence
      // Pass limit and offset to the use case
      if (_searchQuery.isNotEmpty) {
        _logger.d("MedicineProvider: Applying search filter (page $page)...");
        result = await searchDrugsUseCase(
          SearchParams(query: _searchQuery, limit: _pageSize, offset: offset),
        );
      } else if (_selectedCategory.isNotEmpty) {
        _logger.d("MedicineProvider: Applying category filter (page $page)...");
        result = await filterDrugsByCategoryUseCase(
          FilterParams(
            category: _selectedCategory,
            limit: _pageSize,
            offset: offset,
          ),
        );
      } else {
        _logger.d(
          "MedicineProvider: Applying initial/no filter (page $page)...",
        );
        result = await searchDrugsUseCase(
          SearchParams(query: '', limit: _pageSize, offset: offset),
        );
      }

      // Apply secondary filters locally (still needed as DB doesn't support them yet)
      result.fold(
        (failure) {
          _logger.e(
            "MedicineProvider: Error during primary fetch (page $page): ${_mapFailureToMessage(failure)}",
          );
          _error = "خطأ في جلب/فلترة الأدوية: ${_mapFailureToMessage(failure)}";
          if (!append) _filteredMedicines = []; // Clear only if not appending
          _hasMoreItems = false; // Stop pagination on error
        },
        (drugs) {
          _logger.d(
            "MedicineProvider: Primary fetch successful (page $page - ${drugs.length} items). Applying secondary filters...",
          );
          List<DrugEntity> newlyFiltered = List.from(
            drugs,
          ); // Filter only the new batch

          // Apply Dosage Form Filter locally
          if (_selectedDosageForm.isNotEmpty) {
            final lowerCaseDosage = _selectedDosageForm.toLowerCase();
            newlyFiltered =
                newlyFiltered.where((drug) {
                  final formLower = (drug.dosageForm ?? '').toLowerCase();
                  return formLower.contains(lowerCaseDosage);
                }).toList();
          }

          // Apply Price Range Filter locally
          if (_selectedPriceRange != null) {
            newlyFiltered =
                newlyFiltered.where((drug) {
                  final price = double.tryParse(drug.price);
                  if (price == null) return false;
                  return price >= _selectedPriceRange!.start &&
                      price <= _selectedPriceRange!.end;
                }).toList();
          }

          _logger.i(
            "MedicineProvider: Filtering complete for page $page. New items count: ${newlyFiltered.length}",
          );

          _error = ''; // Clear error on success
          _hasMoreItems =
              newlyFiltered.length ==
              _pageSize; // Assume less items means end of list

          if (append) {
            _filteredMedicines.addAll(
              newlyFiltered,
            ); // Add new items to existing list
          } else {
            _filteredMedicines =
                newlyFiltered; // Replace list for initial load/filter change
          }
        },
      );
    } catch (e, s) {
      _logger.e(
        "MedicineProvider: Unexpected error during _applyFilters (page $page)",
        e,
        s,
      );
      _error = "حدث خطأ غير متوقع أثناء الفلترة.";
      if (!append) _filteredMedicines = [];
      _hasMoreItems = false;
    } finally {
      if (!append)
        _isLoading =
            false; // Only turn off main loading indicator if not appending
      // _isLoadingMore is handled in loadMoreDrugs
      notifyListeners();
      _logger.d(
        "MedicineProvider: _applyFilters finished for page $page. isLoading: $_isLoading, hasMore: $_hasMoreItems",
      );
    }
  }

  String _mapFailureToMessage(Failure failure) {
    // ... (keep existing implementation) ...
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

  void _calculatePriceRange(List<DrugEntity> drugs) {
    // ... (keep existing implementation) ...
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

  DateTime? _parseDate(String? dateString) {
    // ... (keep existing implementation) ...
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(dateString);
    } catch (e) {
      try {
        return DateFormat('dd/MM/yyyy').parseStrict(dateString);
      } catch (e2, s2) {
        _logger.w("Could not parse date: $dateString", e2, s2);
        return null;
      }
    }
  }

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
    properties.add(
      FlagProperty(
        'isLoadingMore',
        value: _isLoadingMore,
        ifTrue: 'LOADING MORE',
      ),
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
    properties.add(IntProperty('currentPage', _currentPage));
    properties.add(
      FlagProperty('hasMoreItems', value: _hasMoreItems, ifTrue: 'HAS MORE'),
    );
  }
}
