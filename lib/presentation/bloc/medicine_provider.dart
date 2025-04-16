import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dartz/dartz.dart';
import 'package:collection/collection.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/usecases/get_all_drugs.dart'; // Still needed for update check/initial load logic
import '../../domain/usecases/search_drugs.dart';
import '../../domain/usecases/filter_drugs_by_category.dart';
import '../../domain/usecases/get_available_categories.dart';
import '../../domain/usecases/get_last_update_timestamp.dart';
// import '../../domain/usecases/get_analytics_summary.dart'; // Keep commented out
import '../../core/usecases/usecase.dart';

class MedicineProvider extends ChangeNotifier with DiagnosticableTreeMixin {
  final GetAllDrugs getAllDrugsUseCase;
  final SearchDrugsUseCase searchDrugsUseCase;
  final FilterDrugsByCategoryUseCase filterDrugsByCategoryUseCase;
  final GetAvailableCategoriesUseCase getAvailableCategoriesUseCase;
  final GetLastUpdateTimestampUseCase getLastUpdateTimestampUseCase;
  final FileLoggerService _logger = locator<FileLoggerService>();

  // --- State variables ---
  List<DrugEntity> _filteredMedicines = [];
  List<String> _categories = [];
  String _searchQuery = '';
  String _selectedCategory = ''; // Back to single category selection
  String _selectedDosageForm =
      ''; // Keep dosage form filter (can be applied locally)
  RangeValues?
  _selectedPriceRange; // Keep price range filter (can be applied locally)
  double _minPrice = 0;
  double _maxPrice = 1000;
  bool _isLoading = true;
  bool _isLoadingMore = false; // Re-added for pagination
  String _error = '';
  int? _lastUpdateTimestamp;
  bool _isInitialLoadComplete = false;

  // --- Pagination State ---
  static const int _initialPageSize = 10; // Size for the very first load
  static const int _pageSize = 15; // Size for subsequent loads
  int _currentPage = 0; // Re-added current page
  bool _hasMoreItems = true; // Re-added flag

  // --- State for Simulated Sections ---
  List<DrugEntity> _recentlyUpdatedDrugs = [];
  List<DrugEntity> _popularDrugs = [];
  static const int _simulatedSectionLimit = 8;

  // --- Getters ---
  List<DrugEntity> get filteredMedicines => _filteredMedicines;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore; // Re-added getter
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory =>
      _selectedCategory; // Back to single category getter
  String get selectedDosageForm => _selectedDosageForm;
  RangeValues? get selectedPriceRange => _selectedPriceRange;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  bool get hasMoreItems => _hasMoreItems; // Re-added getter
  bool get isInitialLoadComplete => _isInitialLoadComplete;
  List<DrugEntity> get recentlyUpdatedDrugs => _recentlyUpdatedDrugs;
  List<DrugEntity> get popularDrugs => _popularDrugs;

  // Helper to parse price string to double
  double? _parsePrice(String? priceString) {
    if (priceString == null) return null;
    final cleanedPrice = priceString.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanedPrice);
  }

  MedicineProvider({
    required this.getAllDrugsUseCase,
    required this.searchDrugsUseCase,
    required this.filterDrugsByCategoryUseCase,
    required this.getAvailableCategoriesUseCase,
    required this.getLastUpdateTimestampUseCase,
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
      return DateFormat('d MMM yyyy, HH:mm', 'ar').format(dateTime);
    } catch (e, s) {
      _logger.e("Error formatting timestamp", e, s);
      return 'تنسيق غير صالح';
    }
  }

  Future<void> loadInitialData({bool forceUpdate = false}) async {
    if (_isLoading && !forceUpdate) return;

    _logger.i(
      "MedicineProvider: loadInitialData called (forceUpdate: $forceUpdate)",
    );
    _isLoading = true;
    _error = '';
    _isInitialLoadComplete = false;
    _currentPage = 0; // Reset pagination
    _hasMoreItems = true;
    _filteredMedicines = [];
    _recentlyUpdatedDrugs = [];
    _popularDrugs = [];
    // Removed notifyListeners() here to prevent premature UI update with empty lists

    // Load categories and timestamp first
    _logger.i("MedicineProvider: Loading categories and timestamp...");
    await Future.wait([_loadCategories(), _loadAndUpdateTimestamp()]);
    _logger.i("MedicineProvider: Categories and timestamp loaded.");

    // Apply initial filters (fetch first page) and simulated sections
    _logger.i(
      "MedicineProvider: Applying initial filters (page 0) and loading simulated sections...",
    );
    await Future.wait([
      _applyFilters(
        page: 0,
        limit: _initialPageSize,
      ), // Fetch initial page (10 items)
      _loadSimulatedSections(), // Load simulated data (still fetches small amounts)
    ]);

    _isLoading = false; // Set loading false AFTER all waits complete
    _isInitialLoadComplete = true;
    _logger.i("MedicineProvider: loadInitialData finished.");
    notifyListeners(); // Notify listeners ONCE after all initial data is loaded
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

  // Load simulated sections (still fetches small amounts, independent of main list pagination)
  Future<void> _loadSimulatedSections() async {
    _logger.d("MedicineProvider: _loadSimulatedSections called.");
    try {
      // Fetch a small set for "Recent" - Use empty query, offset 0
      final recentResult = await searchDrugsUseCase(
        SearchParams(query: '', limit: _simulatedSectionLimit, offset: 0),
      );
      recentResult.fold(
        (l) => _logger.w("Failed to load simulated recent drugs"),
        (r) => _recentlyUpdatedDrugs = r,
      );

      // Fetch another small set for "Popular" - Use empty query, different offset
      final popularResult = await searchDrugsUseCase(
        SearchParams(
          query: '',
          limit: _simulatedSectionLimit,
          offset: _simulatedSectionLimit,
        ), // Offset by the limit to get a different set
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
    _filteredMedicines = []; // Clear previous results before new search/filter
    await _applyFilters(page: 0);
  }

  // Back to single category selection
  Future<void> setCategory(String category) async {
    _logger.d(
      "MedicineProvider: setCategory called with category: '$category'",
    );
    _selectedCategory = category;
    _searchQuery = ''; // Clear search when filtering by category
    _currentPage = 0;
    _hasMoreItems = true;
    _filteredMedicines = [];
    await _applyFilters(page: 0);
  }

  // Dosage form and price range filters are applied locally after fetching
  void setDosageForm(String dosageForm) {
    _logger.d(
      "MedicineProvider: setDosageForm called with dosageForm: '$dosageForm'",
    );
    _selectedDosageForm = dosageForm;
    _applyFilters(page: 0); // Re-apply filters locally on the current data
  }

  void setPriceRange(RangeValues? range) {
    _logger.d("MedicineProvider: setPriceRange called with range: $range");
    _selectedPriceRange = range;
    _applyFilters(page: 0); // Re-apply filters locally on the current data
  }

  // Re-added loadMoreDrugs for pagination
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

    // Subsequent loads use the standard _pageSize
    await _applyFilters(page: _currentPage, append: true, limit: _pageSize);

    _isLoadingMore = false;
    notifyListeners();
    _logger.i(
      "MedicineProvider: loadMoreDrugs finished for page $_currentPage. hasMore: $_hasMoreItems",
    );
  }

  // Apply filters by fetching from repository (with pagination)
  // Accepts an optional limit, defaulting to _pageSize if not provided
  Future<void> _applyFilters({
    required int page,
    bool append = false,
    int? limit, // Optional limit parameter
  }) async {
    final int requestedLimit =
        limit ?? _pageSize; // The number of items we *want* for the page
    final int fetchLimit =
        requestedLimit + 1; // Ask for one extra item to check if more exist
    if (!append) {
      _isLoading = true;
      _error = '';
      // Clear list only if not appending (i.e., new search/filter)
      if (!append) _filteredMedicines = [];
      // Removed notifyListeners() here - it's handled by the calling function (loadInitialData/loadMoreDrugs)
    }

    // Calculate offset based on page number and *previous* page sizes
    // Page 0: offset 0
    // Page 1: offset 10 (initial size)
    // Page 2: offset 10 + 15 = 25
    // Page 3: offset 10 + 15 + 15 = 40
    final int offset =
        (page == 0) ? 0 : _initialPageSize + (page - 1) * _pageSize;

    _logger.i(
      "MedicineProvider: _applyFilters called. Page: $page, Requested Limit: $requestedLimit, Fetch Limit: $fetchLimit, Offset: $offset, Append: $append. Query: '$_searchQuery', Category: '$_selectedCategory'",
    );

    Either<Failure, List<DrugEntity>> result;

    try {
      // Add detailed logging before calling the use case
      _logger.i(
        "MedicineProvider: Preparing to call UseCase. Query: '$_searchQuery', Category: '$_selectedCategory', Page: $page, Fetch Limit: $fetchLimit, Offset: $offset, Append: $append",
      );

      // >>>>> ADD EXTRA LOGGING HERE <<<<<
      _logger.d(
        "MedicineProvider: UseCase PARAMS - Query: '$_searchQuery', Limit: $fetchLimit, Offset: $offset, Category: '$_selectedCategory'", // Log fetchLimit
      );
      // >>>>> END EXTRA LOGGING <<<<<

      // Fetch data based on primary filter (search or category)
      if (_searchQuery.isNotEmpty) {
        _logger.d(
          "MedicineProvider: Applying search filter via repository (page $page)...",
        );
        result = await searchDrugsUseCase(
          SearchParams(
            query: _searchQuery,
            limit: fetchLimit, // Use fetchLimit
            offset: offset,
          ),
        );
      } else if (_selectedCategory.isNotEmpty) {
        _logger.d(
          "MedicineProvider: Applying category filter via repository (page $page)...",
        );
        result = await filterDrugsByCategoryUseCase(
          FilterParams(
            category: _selectedCategory,
            limit: fetchLimit, // Use fetchLimit
            offset: offset,
          ),
        );
      } else {
        _logger.d(
          "MedicineProvider: Applying no primary filter, fetching all (page $page)...",
        );
        result = await searchDrugsUseCase(
          SearchParams(
            query: '',
            limit: fetchLimit,
            offset: offset,
          ), // Use fetchLimit
        );
      }

      result.fold(
        (failure) {
          _logger.e(
            "MedicineProvider: Error during repository fetch (page $page): ${_mapFailureToMessage(failure)}",
          );
          _error = "خطأ في جلب/فلترة الأدوية: ${_mapFailureToMessage(failure)}";
          if (!append) _filteredMedicines = [];
          _hasMoreItems = false;
        },
        (drugs) {
          _logger.d(
            "MedicineProvider: Repository fetch successful (page $page - ${drugs.length} items). Applying secondary local filters...",
          );
          List<DrugEntity> newlyFiltered = List.from(drugs);

          // Apply secondary filters (Dosage Form, Price Range) locally
          if (_selectedDosageForm.isNotEmpty) {
            final formLower = _selectedDosageForm.toLowerCase();
            newlyFiltered =
                newlyFiltered
                    .where(
                      (drug) =>
                          drug.dosageForm.toLowerCase().contains(formLower),
                    )
                    .toList();
          }
          if (_selectedPriceRange != null) {
            newlyFiltered =
                newlyFiltered.where((drug) {
                  final price = _parsePrice(drug.price);
                  if (price == null) return false;
                  return price >= _selectedPriceRange!.start &&
                      price <= _selectedPriceRange!.end;
                }).toList();
          }

          _logger.i(
            "MedicineProvider: Filtering complete for page $page. New items count: ${newlyFiltered.length}",
          );

          _error = '';
          // New logic: Check if we received more items than requested for the page
          _hasMoreItems = drugs.length == fetchLimit;

          // Get the items to actually add to the list (max requestedLimit)
          final itemsToAdd =
              _hasMoreItems ? drugs.take(requestedLimit).toList() : drugs;

          _logger.d(
            "MedicineProvider: hasMoreItems set to $_hasMoreItems. Items received: ${drugs.length}, Items to add: ${itemsToAdd.length}",
          );

          // Apply secondary filters to the items we intend to add
          List<DrugEntity> locallyFilteredItemsToAdd = List.from(itemsToAdd);
          if (_selectedDosageForm.isNotEmpty) {
            final formLower = _selectedDosageForm.toLowerCase();
            locallyFilteredItemsToAdd =
                locallyFilteredItemsToAdd
                    .where(
                      (drug) =>
                          drug.dosageForm.toLowerCase().contains(formLower),
                    )
                    .toList();
          }
          if (_selectedPriceRange != null) {
            locallyFilteredItemsToAdd =
                locallyFilteredItemsToAdd.where((drug) {
                  final price = _parsePrice(drug.price);
                  if (price == null) return false;
                  return price >= _selectedPriceRange!.start &&
                      price <= _selectedPriceRange!.end;
                }).toList();
          }
          _logger.i(
            "MedicineProvider: Filtering complete for page $page. Final items to add count: ${locallyFilteredItemsToAdd.length}",
          );

          if (append) {
            final existingTradeNames =
                _filteredMedicines.map((d) => d.tradeName).toSet();
            _filteredMedicines.addAll(
              locallyFilteredItemsToAdd.where(
                // Add the locally filtered items
                (d) => !existingTradeNames.contains(d.tradeName),
              ),
            );
          } else {
            _filteredMedicines =
                locallyFilteredItemsToAdd; // Set the locally filtered items
            if (page == 0) {
              // Calculate price range based on the first page items *before* local filtering?
              // Or after? Let's do it after local filtering for consistency.
              _calculatePriceRange(_filteredMedicines);
            }
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
      // Remove setting isLoading and notifying listeners from here during initial load
      // It will be handled by loadInitialData
      // if (!append) _isLoading = false;
      // notifyListeners();
      _logger.d(
        "MedicineProvider: _applyFilters finished for page $page. isLoading: $_isLoading, hasMore: $_hasMoreItems",
      );
    }
  }

  // Calculate min/max price from a list of drugs
  void _calculatePriceRange(List<DrugEntity> drugs) {
    if (drugs.isEmpty) {
      _minPrice = 0;
      _maxPrice = 1000;
      return;
    }
    double minP = double.maxFinite;
    double maxP = 0;
    for (var drug in drugs) {
      final price = _parsePrice(drug.price);
      if (price != null) {
        if (price < minP) minP = price;
        if (price > maxP) maxP = price;
      }
    }
    _minPrice = (minP == double.maxFinite) ? 0 : minP;
    _maxPrice = (maxP == 0 || maxP <= _minPrice) ? _minPrice + 1000 : maxP;
    _logger.i(
      "MedicineProvider: Calculated price range based on current list: $_minPrice - $_maxPrice",
    );
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      IterableProperty<DrugEntity>('filteredMedicines', _filteredMedicines),
    );
    properties.add(IterableProperty<String>('categories', _categories));
    properties.add(StringProperty('searchQuery', _searchQuery));
    properties.add(
      StringProperty('selectedCategory', _selectedCategory),
    ); // Back to single string
    properties.add(StringProperty('selectedDosageForm', _selectedDosageForm));
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
    ); // Re-added
    properties.add(StringProperty('error', _error, defaultValue: ''));
    properties.add(IntProperty('lastUpdateTimestamp', _lastUpdateTimestamp));
    properties.add(
      FlagProperty(
        'isInitialLoadComplete',
        value: _isInitialLoadComplete,
        ifTrue: 'LOADED',
      ),
    );
    properties.add(IntProperty('currentPage', _currentPage)); // Re-added
    properties.add(
      FlagProperty('hasMoreItems', value: _hasMoreItems, ifTrue: 'HAS MORE'),
    ); // Re-added
    properties.add(
      IterableProperty<DrugEntity>(
        'recentlyUpdatedDrugs',
        _recentlyUpdatedDrugs,
      ),
    );
    properties.add(IterableProperty<DrugEntity>('popularDrugs', _popularDrugs));
  }
}
