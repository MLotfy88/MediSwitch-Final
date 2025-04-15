import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dartz/dartz.dart';
import 'package:collection/collection.dart'; // Import collection package
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/usecases/get_all_drugs.dart';
import '../../domain/usecases/search_drugs.dart';
import '../../domain/usecases/filter_drugs_by_category.dart';
import '../../domain/usecases/get_available_categories.dart';
import '../../domain/usecases/get_last_update_timestamp.dart';
import '../../domain/usecases/get_analytics_summary.dart'; // Keep if used elsewhere
// import '../../domain/repositories/analytics_repository.dart'; // Not directly used here
import '../../core/usecases/usecase.dart';

class MedicineProvider extends ChangeNotifier with DiagnosticableTreeMixin {
  final GetAllDrugs getAllDrugsUseCase;
  final SearchDrugsUseCase searchDrugsUseCase;
  final FilterDrugsByCategoryUseCase filterDrugsByCategoryUseCase;
  final GetAvailableCategoriesUseCase getAvailableCategoriesUseCase;
  final GetLastUpdateTimestampUseCase getLastUpdateTimestampUseCase;
  // final GetAnalyticsSummary getAnalyticsSummaryUseCase; // Keep if needed
  final FileLoggerService _logger = locator<FileLoggerService>();

  // --- State variables ---
  List<DrugEntity> _filteredMedicines = [];
  List<String> _categories = [];
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedDosageForm = '';
  RangeValues? _selectedPriceRange;
  double _minPrice = 0;
  double _maxPrice = 1000; // Default max price
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  int? _lastUpdateTimestamp;
  bool _isInitialLoadComplete = false;

  // --- Pagination State ---
  static const int _pageSize = 15;
  int _currentPage = 0;
  bool _hasMoreItems = true;

  // --- State for Simulated Sections ---
  List<DrugEntity> _recentlyUpdatedDrugs = [];
  List<DrugEntity> _popularDrugs = [];
  static const int _simulatedSectionLimit =
      8; // Number of items for simulated sections

  // --- Getters ---
  List<DrugEntity> get filteredMedicines => _filteredMedicines;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedDosageForm => _selectedDosageForm;
  RangeValues? get selectedPriceRange => _selectedPriceRange;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  bool get hasMoreItems => _hasMoreItems;
  bool get isInitialLoadComplete => _isInitialLoadComplete;
  List<DrugEntity> get recentlyUpdatedDrugs =>
      _recentlyUpdatedDrugs; // Getter for recent
  List<DrugEntity> get popularDrugs => _popularDrugs; // Getter for popular

  MedicineProvider({
    required this.getAllDrugsUseCase,
    required this.searchDrugsUseCase,
    required this.filterDrugsByCategoryUseCase,
    required this.getAvailableCategoriesUseCase,
    required this.getLastUpdateTimestampUseCase,
    // required this.getAnalyticsSummaryUseCase,
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
      // Use Arabic locale for formatting month name etc.
      return DateFormat('d MMM yyyy, HH:mm', 'ar').format(dateTime);
    } catch (e, s) {
      _logger.e("Error formatting timestamp", e, s);
      return 'تنسيق غير صالح';
    }
  }

  Future<void> loadInitialData({bool forceUpdate = false}) async {
    // Prevent concurrent loads unless forced
    if (_isLoading && !forceUpdate) return;

    _logger.i(
      "MedicineProvider: loadInitialData called (forceUpdate: $forceUpdate)",
    );
    _isLoading = true;
    _error = '';
    _isInitialLoadComplete = false;
    _currentPage = 0;
    _hasMoreItems = true;
    _filteredMedicines = [];
    _recentlyUpdatedDrugs = []; // Clear simulated lists too
    _popularDrugs = [];
    notifyListeners();

    // --- Update Check (Keep disabled for now) ---
    // bool updateCheckFailed = false;
    // if (forceUpdate) {
    //    _logger.i("MedicineProvider: Forcing data update...");
    //    try {
    //       await _updateLocalDataFromRemote(); // Assuming this exists in repo
    //    } catch (e, s) {
    //       _logger.e("MedicineProvider: Forced update failed", e, s);
    //       _error = "فشل تحديث البيانات: ${_mapFailureToMessage(e is Failure ? e : UnknownFailure())}";
    //       updateCheckFailed = true;
    //    }
    // } else {
    //    // Normal update check logic (currently disabled in repo)
    //    final updateResult = await getAllDrugsUseCase(NoParams());
    //    updateResult.fold(
    //      (failure) {
    //        _error = "فشل التحقق من التحديثات: ${_mapFailureToMessage(failure)}";
    //        _logger.e("MedicineProvider: Update check failed: $_error");
    //        updateCheckFailed = true;
    //      },
    //      (_) => _logger.i("MedicineProvider: Update check successful or not needed."),
    //    );
    // }
    // --- End Update Check ---

    // Load categories and timestamp regardless of update result
    _logger.i("MedicineProvider: Loading categories and timestamp...");
    await Future.wait([_loadCategories(), _loadAndUpdateTimestamp()]);
    _logger.i("MedicineProvider: Categories and timestamp loaded.");

    // Apply initial filters (fetch first page) and simulated sections
    _logger.i(
      "MedicineProvider: Applying initial filters (page 0) and loading simulated sections...",
    );
    // Fetch initial page and simulated data concurrently
    await Future.wait([
      _applyFilters(page: 0),
      _loadSimulatedSections(), // Load simulated data
    ]);

    _isInitialLoadComplete = true;
    // _isLoading is set to false inside _applyFilters
    _logger.i("MedicineProvider: loadInitialData finished.");
    // Final notification happens in _applyFilters
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
        // Calculate price range based on ALL categories initially if needed
        // Or calculate based on the first page load in _applyFilters
      },
    );
    // No notifyListeners here, handled by loadInitialData/applyFilters
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
    // No notifyListeners here, handled by loadInitialData/applyFilters
  }

  // --- Method to load simulated data for horizontal lists ---
  Future<void> _loadSimulatedSections() async {
    _logger.d("MedicineProvider: _loadSimulatedSections called.");
    try {
      // Fetch a small set for "Recent" - using search with a common letter 'a' for variety
      final recentResult = await searchDrugsUseCase(
        SearchParams(query: 'a', limit: _simulatedSectionLimit, offset: 0),
      );
      recentResult.fold(
        (l) => _logger.w("Failed to load simulated recent drugs"),
        (r) => _recentlyUpdatedDrugs = r,
      );

      // Fetch another small set for "Popular" - using search with 'b' offset slightly
      final popularResult = await searchDrugsUseCase(
        SearchParams(query: 'b', limit: _simulatedSectionLimit, offset: 5),
      );
      popularResult.fold(
        (l) => _logger.w("Failed to load simulated popular drugs"),
        (r) => _popularDrugs = r,
      );
      _logger.i(
        "MedicineProvider: Simulated sections loaded. Recent: ${_recentlyUpdatedDrugs.length}, Popular: ${_popularDrugs.length}",
      );
    } catch (e, s) {
      _logger.e("Error loading simulated sections", e, s);
      _recentlyUpdatedDrugs = [];
      _popularDrugs = [];
    }
    // No notifyListeners here, handled by loadInitialData/applyFilters
  }

  Future<void> setSearchQuery(String query) async {
    _logger.d("MedicineProvider: setSearchQuery called with query: '$query'");
    _searchQuery = query;
    _selectedCategory = ''; // Clear category when searching
    _currentPage = 0;
    _hasMoreItems = true;
    _filteredMedicines = [];
    await _applyFilters(page: 0);
  }

  Future<void> setCategory(String category) async {
    _logger.d(
      "MedicineProvider: setCategory called with category: '$category'",
    );
    _selectedCategory = category;
    _searchQuery = '';
    _currentPage = 0;
    _hasMoreItems = true;
    _filteredMedicines = [];
    await _applyFilters(page: 0);
  }

  Future<void> setDosageForm(String dosageForm) async {
    _logger.d(
      "MedicineProvider: setDosageForm called with dosageForm: '$dosageForm'",
    );
    _selectedDosageForm = dosageForm;
    _currentPage = 0;
    _hasMoreItems = true;
    _filteredMedicines = [];
    await _applyFilters(page: 0);
  }

  Future<void> setPriceRange(RangeValues? range) async {
    _logger.d("MedicineProvider: setPriceRange called with range: $range");
    _selectedPriceRange = range;
    _currentPage = 0;
    _hasMoreItems = true;
    _filteredMedicines = [];
    await _applyFilters(page: 0);
  }

  Future<void> loadMoreDrugs() async {
    if (_isLoading || _isLoadingMore || !_hasMoreItems) {
      _logger.d(
        "MedicineProvider: loadMoreDrugs called but skipping. isLoading: $_isLoading, isLoadingMore: $_isLoadingMore, hasMore: $_hasMoreItems",
      );
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    _currentPage++;
    _logger.i("MedicineProvider: loadMoreDrugs called for page $_currentPage");

    await _applyFilters(page: _currentPage, append: true);

    _isLoadingMore = false;
    notifyListeners();
    _logger.i(
      "MedicineProvider: loadMoreDrugs finished for page $_currentPage. hasMore: $_hasMoreItems",
    );
  }

  Future<void> _applyFilters({required int page, bool append = false}) async {
    if (!append) {
      _isLoading = true;
      _error = '';
      // Clear list only if not appending
      if (!append) _filteredMedicines = [];
      notifyListeners();
    }

    final int offset = page * _pageSize;
    _logger.i(
      "MedicineProvider: _applyFilters called. Page: $page, Offset: $offset, Append: $append. Query: '$_searchQuery', Category: '$_selectedCategory'",
    );

    Either<Failure, List<DrugEntity>> result;

    try {
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
        // Fetch first page when no specific filter is active
        result = await searchDrugsUseCase(
          SearchParams(query: '', limit: _pageSize, offset: offset),
        );
      }

      result.fold(
        (failure) {
          _logger.e(
            "MedicineProvider: Error during primary fetch (page $page): ${_mapFailureToMessage(failure)}",
          );
          _error = "خطأ في جلب/فلترة الأدوية: ${_mapFailureToMessage(failure)}";
          if (!append) _filteredMedicines = [];
          _hasMoreItems = false;
        },
        (drugs) {
          _logger.d(
            "MedicineProvider: Primary fetch successful (page $page - ${drugs.length} items). Applying secondary filters...",
          );
          List<DrugEntity> newlyFiltered = List.from(drugs);

          // Apply Dosage Form Filter locally
          if (_selectedDosageForm.isNotEmpty) {
            final lowerCaseDosage = _selectedDosageForm.toLowerCase();
            newlyFiltered =
                newlyFiltered.where((drug) {
                  final formLower = (drug.dosageForm).toLowerCase();
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

          _error = '';
          _hasMoreItems = newlyFiltered.length == _pageSize;

          if (append) {
            // Avoid duplicates when appending
            final existingTradeNames =
                _filteredMedicines.map((d) => d.tradeName).toSet();
            _filteredMedicines.addAll(
              newlyFiltered.where(
                (d) => !existingTradeNames.contains(d.tradeName),
              ),
            );
          } else {
            _filteredMedicines = newlyFiltered;
            // Calculate price range based on the first page load if needed
            // _calculatePriceRange(_filteredMedicines);
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
      if (!append) _isLoading = false;
      notifyListeners();
      _logger.d(
        "MedicineProvider: _applyFilters finished for page $page. isLoading: $_isLoading, hasMore: $_hasMoreItems",
      );
    }
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

  // Removed _calculatePriceRange and _parseDate as they are not currently used

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
    properties.add(
      IterableProperty<DrugEntity>(
        'recentlyUpdatedDrugs',
        _recentlyUpdatedDrugs,
      ),
    ); // Add new lists
    properties.add(IterableProperty<DrugEntity>('popularDrugs', _popularDrugs));
  }
}
