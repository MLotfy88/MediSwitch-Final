import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dartz/dartz.dart';
import 'package:collection/collection.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../data/datasources/local/sqlite_local_data_source.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/usecases/get_all_drugs.dart'; // Still needed for update check/initial load logic
import '../../domain/usecases/search_drugs.dart';
import '../../domain/usecases/filter_drugs_by_category.dart';
import '../../domain/usecases/get_available_categories.dart';
import '../../domain/usecases/get_last_update_timestamp.dart';
import '../../domain/usecases/get_recently_updated_drugs.dart';
import '../../domain/usecases/get_popular_drugs.dart';
// import '../../domain/usecases/get_analytics_summary.dart'; // Keep commented out
import '../../core/usecases/usecase.dart';

class MedicineProvider extends ChangeNotifier with DiagnosticableTreeMixin {
  final GetAllDrugs getAllDrugsUseCase;
  final SearchDrugsUseCase searchDrugsUseCase;
  final FilterDrugsByCategoryUseCase filterDrugsByCategoryUseCase;
  final GetAvailableCategoriesUseCase getAvailableCategoriesUseCase;
  final GetLastUpdateTimestampUseCase getLastUpdateTimestampUseCase;
  final GetRecentlyUpdatedDrugsUseCase getRecentlyUpdatedDrugsUseCase;
  final GetPopularDrugsUseCase getPopularDrugsUseCase;
  // Add the data source dependency
  final SqliteLocalDataSource _localDataSource;
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
  bool _isLoading = false; // Initialize to false
  bool _isLoadingMore = false; // Re-added for pagination
  String _error = '';
  // REMOVED: bool _isInitialLoading = false; // Flag specifically for initial load process
  int? _lastUpdateTimestamp;
  bool _isInitialLoadComplete = false;
  // --- Pagination State ---
  static const int _initialPageSize = 10; // Load 10 drugs initially
  static const int _pageSize =
      15; // Load 15 additional drugs when scrolling down
  int _currentPage = 0; // صفحة البداية
  bool _hasMoreItems = true; // مؤشر لوجود المزيد من البيانات

  // --- State for Simulated Sections ---
  List<DrugEntity> _recentlyUpdatedDrugs = [];
  List<DrugEntity> _popularDrugs = [];
  static const int _simulatedSectionLimit = 8;

  // --- Getters ---
  List<DrugEntity> get filteredMedicines => _filteredMedicines;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  // bool get isSeedingDatabase => _isSeedingDatabase; // REMOVED: Getter for seeding state
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
  int? get lastUpdateTimestamp =>
      _lastUpdateTimestamp; // Public getter for raw timestamp

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
    required this.getRecentlyUpdatedDrugsUseCase,
    required this.getPopularDrugsUseCase,
    // Inject the data source
    required SqliteLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource {
    // Initialize it
    _logger.i("MedicineProvider: Constructor called.");
    loadInitialData();
  }

  // REMOVED: Formatted timestamp getter - formatting moved to UI layer
  // String get lastUpdateTimestampFormatted { ... }

  Future<void> loadInitialData({bool forceUpdate = false}) async {
    _logger.i(
      "MedicineProvider: >>> ENTERING loadInitialData (forceUpdate: $forceUpdate) <<<",
    ); // ADDED EARLY LOG
    // Use simple isLoading guard
    _logger.d(
      "MedicineProvider: Checking guard. _isLoading = $_isLoading, forceUpdate = $forceUpdate",
    ); // <-- ADDED DEBUG LOG
    if (_isLoading && !forceUpdate) {
      _logger.i(
        "MedicineProvider: loadInitialData called but already loading. Skipping. (isLoading=$_isLoading, forceUpdate=$forceUpdate)", // Updated log
      );
      return;
    }

    _logger.i(
      "MedicineProvider: loadInitialData called (forceUpdate: $forceUpdate)",
    );
    _isLoading = true; // Set loading true
    // _isInitialLoading = true; // Removed flag
    // Unconditional state reset (Restored)
    _error = '';
    _isInitialLoadComplete = false;
    _currentPage = 0; // Reset pagination
    _hasMoreItems = true;
    _filteredMedicines = [];
    _recentlyUpdatedDrugs = []; // إعادة تعيين قائمة الأدوية المحدثة عند التحديث
    _popularDrugs = []; // إعادة تعيين قائمة الأدوية الشائعة عند التحديث
    notifyListeners(); // Notify UI that loading has started

    try {
      // REMOVED: Seeding is now guaranteed by InitializationScreen before this provider is used.
      // _logger.i(
      //   "MedicineProvider: Waiting for database seeding to complete...",
      // );
      // await _localDataSource.seedingComplete; // Wait for the seeding Future
      // _logger.i("MedicineProvider: Database seeding confirmed complete.");

      // Load timestamp
      _logger.i("MedicineProvider: Loading timestamp...");
      await _loadAndUpdateTimestamp();
      _logger.i("MedicineProvider: Timestamp loaded.");

      // Load categories first
      _logger.i("MedicineProvider: Loading categories...");
      await _loadCategories();
      _logger.i("MedicineProvider: Categories loaded.");
      // Load simulated sections needed for HomeScreen UI (Original Order)
      _logger.i("MedicineProvider: >>> TRYING _loadSimulatedSections...");
      await _loadSimulatedSections(); // Await section loading
      _logger.i(
        "MedicineProvider: <<< FINISHED _loadSimulatedSections. Recent: ${_recentlyUpdatedDrugs.length}, Popular: ${_popularDrugs.length}",
      );

      // Apply initial filters (fetch first page) (Original Order)
      _logger.i("MedicineProvider: >>> TRYING _applyFilters (initial)...");
      await _applyFilters(
        page: 0,
        limit: _initialPageSize,
        // notifyOnCompletion: false, // Parameter removed
      ); // Await initial filter application
      _logger.i(
        "MedicineProvider: <<< FINISHED _applyFilters (initial). Filtered count: ${_filteredMedicines.length}",
      );

      // SUCCESS PATH: Only reach here if both sections and initial filters loaded without error
      _isInitialLoadComplete = true;
      _logger.i("MedicineProvider: Initial load successful.");
      // State (_isLoading) set in finally
    } catch (e, s) {
      // FAILURE PATH: Catch errors from _loadSimulatedSections OR _applyFilters
      _logger.e("MedicineProvider: Error during initial data load", e, s);
      _error =
          e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : "فشل تحميل البيانات الأولية.";
      _filteredMedicines = [];
      _recentlyUpdatedDrugs = [];
      _popularDrugs = [];
      _hasMoreItems = false;
      _isInitialLoadComplete = false; // Ensure this is false on error
      _logger.w("MedicineProvider: Initial load FAILED. Error: '$_error'.");
      // State (_isLoading) set in finally
    } finally {
      _isLoading = false; // Set loading false at the end
      // _isInitialLoading = false; // Removed flag
      _logger.d("loadInitialData: Final notifyListeners() call.");
      notifyListeners(); // Single notification reflecting final state
    }
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

  Future<void> _loadSimulatedSections() async {
    _logger.d("MedicineProvider: _loadSimulatedSections called.");
    try {
      // --- Recently Updated Logic ---
      final now = DateTime.now();
      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
      final cutoffDate = DateFormat('yyyy-MM-dd').format(oneMonthAgo);
      const recentLimit = 8;

      _logger.i(
        "Fetching recently updated drugs since $cutoffDate (limit: $recentLimit)",
      );
      final recentResult = await getRecentlyUpdatedDrugsUseCase(
        GetRecentlyUpdatedDrugsParams(
          cutoffDate: cutoffDate,
          limit: recentLimit,
        ),
      );
      recentResult.fold(
        (l) {
          final errorMsg = _mapFailureToMessage(l);
          _logger.w(
            "[_loadSimulatedSections] FAILED to load recently updated drugs: $errorMsg",
          );
          _recentlyUpdatedDrugs = [];
          throw Exception('Failed to load recently updated drugs: $errorMsg');
        },
        (r) {
          _logger.i(
            "[_loadSimulatedSections] Successfully loaded ${r.length} recently updated drugs.",
          );
          _recentlyUpdatedDrugs = r;
        },
      );

      // --- Popular (Random) Logic ---
      const popularLimit = 10;
      _logger.i("Fetching $popularLimit popular (random) drugs");
      final popularResult = await getPopularDrugsUseCase(
        GetPopularDrugsParams(limit: popularLimit),
      );
      popularResult.fold(
        (l) {
          final errorMsg = _mapFailureToMessage(l);
          _logger.w(
            "[_loadSimulatedSections] FAILED to load popular (random) drugs: $errorMsg",
          );
          _popularDrugs = [];
          throw Exception('Failed to load popular drugs: $errorMsg');
        },
        (r) {
          _logger.i(
            "[_loadSimulatedSections] Successfully loaded ${r.length} popular (random) drugs.",
          );
          _popularDrugs = r;
        },
      );

      _logger.i(
        "MedicineProvider: Sections loaded. Recent: ${_recentlyUpdatedDrugs.length}, Popular: ${_popularDrugs.length}",
      );
    } catch (e, s) {
      _logger.e("Error loading sections", e, s);
      _recentlyUpdatedDrugs = [];
      _popularDrugs = [];
    }
  }

  Future<void> setSearchQuery(String query) async {
    _logger.d("MedicineProvider: setSearchQuery called with query: '$query'");
    // Prevent search during any loading process
    if (_isLoading) {
      _logger.w("setSearchQuery: Skipping search as loading is in progress.");
      return;
    }

    _isLoading = true; // Set loading for this specific action
    _searchQuery = query;
    _selectedCategory = '';
    _currentPage = 0;
    _hasMoreItems = true;
    _filteredMedicines = []; // Clear previous results for new search
    notifyListeners(); // Notify UI that search is starting

    try {
      await _applyFilters(page: 0, append: false);
    } catch (e, s) {
      _logger.e("Error during setSearchQuery._applyFilters", e, s);
      _error = "خطأ أثناء البحث."; // Set specific error
    } finally {
      _isLoading = false; // Clear loading for this action
      notifyListeners(); // Notify UI about final state
    }
  }

  Future<void> setCategory(String category) async {
    _logger.d(
      "MedicineProvider: setCategory called with category: '$category'",
    );
    // Prevent category change during any loading process
    if (_isLoading) {
      _logger.w(
        "setCategory: Skipping category change as loading is in progress.",
      );
      return;
    }

    _isLoading = true; // Set loading for this specific action
    _selectedCategory = category;
    _searchQuery = '';
    _currentPage = 0;
    _hasMoreItems = true;
    _filteredMedicines = []; // Clear previous results for new category
    notifyListeners(); // Notify UI that category change is starting

    try {
      await _applyFilters(page: 0, append: false);
    } catch (e, s) {
      _logger.e("Error during setCategory._applyFilters", e, s);
      _error = "خطأ أثناء تغيير الفئة."; // Set specific error
    } finally {
      _isLoading = false; // Clear loading for this action
      notifyListeners(); // Notify UI about final state
    }
  }

  void setDosageForm(String dosageForm) {
    _logger.d(
      "MedicineProvider: setDosageForm called with dosageForm: '$dosageForm'",
    );
    _selectedDosageForm = dosageForm;
    _applyFilters(page: 0);
  }

  void setPriceRange(RangeValues? range) {
    _logger.d("MedicineProvider: setPriceRange called with range: $range");
    _selectedPriceRange = range;
    _applyFilters(page: 0);
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
    _logger.i(
      "MedicineProvider: loadMoreDrugs ENTRY - Requesting page $_currentPage",
    );

    await _applyFilters(page: _currentPage, append: true, limit: _pageSize);

    _isLoadingMore = false;
    _logger.d(
      "MedicineProvider: Final state before notify (Load More) - isLoading: $_isLoading, isLoadingMore: $_isLoadingMore, hasMore: $_hasMoreItems, filteredCount: ${_filteredMedicines.length}",
    );
    notifyListeners();
    _logger.i(
      "MedicineProvider: loadMoreDrugs EXIT - Finished page $_currentPage. hasMore: $_hasMoreItems, Total items: ${_filteredMedicines.length}",
    );
  }

  Future<void> _applyFilters({
    required int page,
    bool append = false,
    int? limit,
    // bool notifyOnCompletion = true, // Parameter removed
  }) async {
    final int requestedLimit = limit ?? _pageSize;
    final int fetchLimit = requestedLimit + 1;
    // Loading state and initial error reset are handled by calling methods

    final int offset =
        (page == 0) ? 0 : _initialPageSize + (page - 1) * _pageSize;

    _logger.i(
      "MedicineProvider: _applyFilters ENTRY - Page: $page, Append: $append, ReqLimit: $requestedLimit, FetchLimit: $fetchLimit, Offset: $offset, Query: '$_searchQuery', Category: '$_selectedCategory', DosageForm: '$_selectedDosageForm', PriceRange: $_selectedPriceRange",
    );

    Either<Failure, List<DrugEntity>> result;

    try {
      _logger.i(
        "MedicineProvider: Preparing to call UseCase. Query: '$_searchQuery', Category: '$_selectedCategory', Page: $page, Fetch Limit: $fetchLimit, Offset: $offset, Append: $append",
      );
      _logger.d(
        "MedicineProvider: UseCase PARAMS - Query: '$_searchQuery', Limit: $fetchLimit, Offset: $offset, Category: '$_selectedCategory'",
      );

      if (_searchQuery.isNotEmpty) {
        _logger.d(
          "MedicineProvider: Applying search filter via repository (page $page)...",
        );
        result = await searchDrugsUseCase(
          SearchParams(query: _searchQuery, limit: fetchLimit, offset: offset),
        );
      } else if (_selectedCategory.isNotEmpty) {
        _logger.d(
          "MedicineProvider: Applying category filter via repository (page $page)...",
        );
        result = await filterDrugsByCategoryUseCase(
          FilterParams(
            category: _selectedCategory,
            limit: fetchLimit,
            offset: offset,
          ),
        );
      } else {
        _logger.d(
          "MedicineProvider: Applying no primary filter, fetching all (page $page)...",
        );
        result = await searchDrugsUseCase(
          SearchParams(query: '', limit: fetchLimit, offset: offset),
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
          _logger.i(
            "MedicineProvider: _applyFilters - UseCase SUCCESS (Page: $page, Append: $append). Fetched ${drugs.length} items.",
          );
          _logger.d(
            "MedicineProvider: Applying secondary local filters (Dosage: '$_selectedDosageForm', Price: $_selectedPriceRange)...",
          );
          List<DrugEntity> newlyFiltered = List.from(drugs);

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
          _hasMoreItems = drugs.length == fetchLimit;

          final itemsToAdd =
              _hasMoreItems ? drugs.take(requestedLimit).toList() : drugs;

          _logger.d(
            "MedicineProvider: hasMoreItems set to $_hasMoreItems. Items received: ${drugs.length}, Items to add: ${itemsToAdd.length}",
          );

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
                (d) => !existingTradeNames.contains(d.tradeName),
              ),
            );
          } else {
            _filteredMedicines = locallyFilteredItemsToAdd;
            if (page == 0) {
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
      // REMOVED: Loading state is managed by the calling methods

      // REMOVED: Notifications handled by calling methods
      // if (notifyOnCompletion && !append) {
      //    _logger.d("_applyFilters: Notifying listeners (notifyOnCompletion=true, append=false)");
      //    notifyListeners();
      // }
      // Pagination Logging (Phase 2, Step 4)
      _logger.i(
        "MedicineProvider: _applyFilters EXIT - Page: $page, Append: $append. Final State: isLoading=$_isLoading, isLoadingMore=$_isLoadingMore, hasMore=$_hasMoreItems, filteredCount=${_filteredMedicines.length}, error='$_error'",
      );
    }
  }

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
    properties.add(StringProperty('selectedCategory', _selectedCategory));
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
    // REMOVED: Seeding state debug property
    // properties.add(
    //   FlagProperty(
    //     'isSeedingDatabase',
    //     value: _isSeedingDatabase,
    //     ifTrue: 'SEEDING DB',
    //   ),
    // );
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
    );
    properties.add(IterableProperty<DrugEntity>('popularDrugs', _popularDrugs));
  }
}
