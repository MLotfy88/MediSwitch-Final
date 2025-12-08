import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediswitch/core/constants/categories_data.dart';
import 'package:mediswitch/core/di/locator.dart';
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/core/services/file_logger_service.dart';
import 'package:mediswitch/core/usecases/usecase.dart';
import 'package:mediswitch/data/datasources/local/sqlite_local_data_source.dart';
import 'package:mediswitch/data/models/dosage_guidelines_model.dart';
import 'package:mediswitch/domain/entities/category_entity.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/usecases/filter_drugs_by_category.dart';
import 'package:mediswitch/domain/usecases/find_drug_alternatives.dart';
import 'package:mediswitch/domain/usecases/get_categories_with_count.dart';
import 'package:mediswitch/domain/usecases/get_high_risk_drugs.dart';
import 'package:mediswitch/domain/usecases/get_last_update_timestamp.dart';
import 'package:mediswitch/domain/usecases/get_popular_drugs.dart';
import 'package:mediswitch/domain/usecases/get_recently_updated_drugs.dart';
import 'package:mediswitch/domain/usecases/search_drugs.dart';

/// Provider responsible for managing medicine-related state and data.
class MedicineProvider extends ChangeNotifier {
  // Dependencies (Injected via constructor or locator for default values)
  final SearchDrugsUseCase _searchDrugsUseCase;
  final FilterDrugsByCategoryUseCase _filterDrugsByCategoryUseCase;
  final GetCategoriesWithCountUseCase _getCategoriesWithCountUseCase;
  final GetLastUpdateTimestampUseCase _getLastUpdateTimestampUseCase;
  final GetRecentlyUpdatedDrugsUseCase _getRecentlyUpdatedDrugsUseCase;
  final GetPopularDrugsUseCase _getPopularDrugsUseCase;
  final GetHighRiskDrugsUseCase _getHighRiskDrugsUseCase;
  final SqliteLocalDataSource
  _localDataSource; // Kept for direct DB access if needed

  // Logger
  final FileLoggerService _logger = locator<FileLoggerService>();

  // State
  List<DrugEntity> _allDrugs = [];
  List<DrugEntity> _searchResults = [];
  // _newDrugs is mapped to _recentlyUpdatedDrugs via getter for backward compatibility
  List<DrugEntity> _recentlyUpdatedDrugs = [];
  List<DrugEntity> _popularDrugs = [];
  List<DrugEntity> _highRiskDrugs = [];
  List<DrugEntity> _favorites = []; // List of full entities
  final Set<String> _favoriteIds = {}; // Set of IDs for O(1) lookup

  List<DrugEntity> _filteredMedicines = [];
  List<CategoryEntity> _categories = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isInitialLoadComplete = false;
  String _error = '';
  int? _lastUpdateTimestamp;

  // Pagination & Filters State
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedDosageForm = '';
  RangeValues? _selectedPriceRange;
  int _currentPage = 0;
  final int _pageSize = 20;
  final int _initialPageSize = 20;
  bool _hasMoreItems = true;

  // Constants
  static const double _defaultMinPrice = 0;
  static const double _defaultMaxPrice = 10000;

  // Getters
  List<DrugEntity> get allDrugs => _allDrugs;
  List<DrugEntity> get searchResults => _searchResults;
  List<DrugEntity> get newDrugs => _recentlyUpdatedDrugs;
  List<DrugEntity> get recentlyUpdatedDrugs => _recentlyUpdatedDrugs;
  List<DrugEntity> get popularDrugs => _popularDrugs;
  List<DrugEntity> get highRiskDrugs => _highRiskDrugs;
  List<DrugEntity> get favorites => _favorites;
  List<DrugEntity> get filteredMedicines => _filteredMedicines;
  List<CategoryEntity> get categories => _categories;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isInitialLoadComplete => _isInitialLoadComplete;
  String get error => _error;
  int? get lastUpdateTimestamp => _lastUpdateTimestamp;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedDosageForm => _selectedDosageForm;
  RangeValues? get selectedPriceRange => _selectedPriceRange;
  bool get hasMoreItems => _hasMoreItems;

  // Expose min/max price for Filter Widgets
  double get minPrice => _defaultMinPrice;
  double get maxPrice => _defaultMaxPrice;

  // Helper to parse price string to double
  double? _parsePrice(String? priceString) {
    if (priceString == null) return null;
    final cleanedPrice = priceString.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanedPrice);
  }

  MedicineProvider({
    required SearchDrugsUseCase searchDrugsUseCase,
    required FilterDrugsByCategoryUseCase filterDrugsByCategoryUseCase,
    required GetCategoriesWithCountUseCase getCategoriesWithCountUseCase,
    required GetLastUpdateTimestampUseCase getLastUpdateTimestampUseCase,
    required GetRecentlyUpdatedDrugsUseCase getRecentlyUpdatedDrugsUseCase,
    required GetPopularDrugsUseCase getPopularDrugsUseCase,
    required GetHighRiskDrugsUseCase getHighRiskDrugsUseCase,
    required SqliteLocalDataSource localDataSource,
  }) : _searchDrugsUseCase = searchDrugsUseCase,
       _filterDrugsByCategoryUseCase = filterDrugsByCategoryUseCase,
       _getCategoriesWithCountUseCase = getCategoriesWithCountUseCase,
       _getLastUpdateTimestampUseCase = getLastUpdateTimestampUseCase,
       _getRecentlyUpdatedDrugsUseCase = getRecentlyUpdatedDrugsUseCase,
       _getPopularDrugsUseCase = getPopularDrugsUseCase,
       _getHighRiskDrugsUseCase = getHighRiskDrugsUseCase,
       _localDataSource = localDataSource {
    _logger.i("MedicineProvider: Constructor called.");
    loadInitialData();
  }

  Future<void> loadInitialData({bool forceUpdate = false}) async {
    _logger.i(
      "MedicineProvider: >>> ENTERING loadInitialData (forceUpdate: $forceUpdate) <<<",
    );

    if (_isLoading && !forceUpdate) {
      _logger.i(
        "MedicineProvider: loadInitialData called but already loading. Skipping.",
      );
      return;
    }

    _logger.i("MedicineProvider: Starting loadInitialData");
    _isLoading = true;
    _error = '';
    _isInitialLoadComplete = false;
    _currentPage = 0;
    _hasMoreItems = true;
    _filteredMedicines = [];
    _recentlyUpdatedDrugs = [];
    _popularDrugs = [];
    _highRiskDrugs = [];
    notifyListeners();

    try {
      // Load timestamp
      await _loadAndUpdateTimestamp();

      // Load categories
      await _loadCategories();

      // Load simulated sections
      await _loadSimulatedSections();

      // Apply initial filters (fetch first page)
      await _applyFilters(
        page: 0,
        // limit: _initialPageSize, // handled in _applyFilters
      );

      _isInitialLoadComplete = true;
      _logger.i("MedicineProvider: Initial load successful.");
    } catch (e, s) {
      _logger.e("MedicineProvider: Error during initial data load", e, s);
      _error =
          e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : "فشل تحميل البيانات الأولية.";
      _isInitialLoadComplete = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCategories() async {
    _logger.d("MedicineProvider: _loadCategories called.");

    // 1. Get raw data from DB
    final result = await _getCategoriesWithCountUseCase(NoParams());

    result.fold(
      (failure) {
        _logger.e(
          "MedicineProvider: Failed to load dynamic categories: $failure",
        );
        _useStaticCategories();
      },
      (categoryCounts) {
        _logger.i(
          "MedicineProvider: Loaded ${categoryCounts.length} categories from DB.",
        );

        final List<CategoryEntity> mergedCategories = [];
        final staticDataMap = {
          for (var item in kAllCategories) item.nameEn.toLowerCase(): item,
        };

        // Iterate over Map entries (replacing loop over Map directly)
        for (var entry in categoryCounts.entries) {
          final outputName = entry.key; // Category name
          final dbCount = entry.value; // Count

          final meta = staticDataMap[outputName.toLowerCase()];

          if (meta != null) {
            mergedCategories.add(
              CategoryEntity(
                id: meta.id,
                name: meta.nameEn,
                nameAr: meta.nameAr,
                shortName: meta.shortNameEn,
                shortNameAr: meta.shortNameAr,
                drugCount: dbCount,
                icon: _getIconNameFromMeta(meta),
                color: meta.colorName,
              ),
            );
            staticDataMap.remove(outputName.toLowerCase());
          } else {
            mergedCategories.add(
              CategoryEntity(
                id: outputName.toLowerCase().replaceAll(' ', '_'),
                name: outputName,
                nameAr: outputName,
                drugCount: dbCount,
                icon: 'pill',
                color: 'blue',
              ),
            );
          }
        }

        // Add remaining static categories with 0 count
        for (var meta in staticDataMap.values) {
          mergedCategories.add(
            CategoryEntity(
              id: meta.id,
              name: meta.nameEn,
              nameAr: meta.nameAr,
              shortName: meta.shortNameEn,
              shortNameAr: meta.shortNameAr,
              drugCount: 0,
              icon: _getIconNameFromMeta(meta),
              color: meta.colorName,
            ),
          );
        }

        mergedCategories.sort((a, b) => b.drugCount.compareTo(a.drugCount));

        _categories = mergedCategories;
        notifyListeners();
        _logger.i(
          "MedicineProvider: Merged and loaded ${_categories.length} categories.",
        );
      },
    );
  }

  void _useStaticCategories() {
    final List<CategoryEntity> mappedCategories =
        kAllCategories.map((data) {
          return CategoryEntity(
            id: data.id,
            name: data.nameEn,
            nameAr: data.nameAr,
            shortName: data.shortNameEn,
            shortNameAr: data.shortNameAr,
            drugCount: data.count,
            icon: _getIconNameFromMeta(data),
            color: data.colorName,
          );
        }).toList();
    _categories = mappedCategories;
    notifyListeners();
  }

  String _getIconNameFromMeta(CategoryData data) {
    if (data.id == 'anti_infective') return 'bug';
    if (data.id == 'cardiovascular') return 'heart';
    if (data.id == 'dermatology') return 'sun';
    if (data.id == 'endocrinology') return 'activity';
    if (data.id == 'general') return 'stethoscope';
    if (data.id == 'immunology') return 'shieldcheck';
    if (data.id == 'nutrition') return 'apple';
    if (data.id == 'pain_relief') return 'zap';
    if (data.id == 'psychiatric') return 'brain'; // Fix for neuro
    if (data.id == 'respiratory') return 'wind';
    return 'pill';
  }

  Future<void> _loadAndUpdateTimestamp() async {
    final failureOrTimestamp = await _getLastUpdateTimestampUseCase(NoParams());
    failureOrTimestamp.fold(
      (failure) {
        _logger.e("Error loading timestamp: ${_mapFailureToMessage(failure)}");
        _lastUpdateTimestamp = null;
      },
      (timestamp) {
        _lastUpdateTimestamp = timestamp;
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
      const recentLimit = 50;

      final recentResult = await _getRecentlyUpdatedDrugsUseCase(
        GetRecentlyUpdatedDrugsParams(
          cutoffDate: cutoffDate,
          limit: recentLimit,
        ),
      );
      recentResult.fold(
        (l) {
          _logger.w(
            "Failed to load recently updated drugs: ${_mapFailureToMessage(l)}",
          );
          _recentlyUpdatedDrugs = [];
        },
        (r) {
          _recentlyUpdatedDrugs = r;
        },
      );

      // --- Popular (Random) Logic ---
      const popularLimit = 10;
      final popularResult = await _getPopularDrugsUseCase(
        GetPopularDrugsParams(limit: popularLimit),
      );
      popularResult.fold(
        (l) {
          _logger.w("Failed to load popular drugs: ${_mapFailureToMessage(l)}");
          _popularDrugs = [];
        },
        (r) {
          _popularDrugs = r;
        },
      );

      // --- High Risk Drugs Logic ---
      // Fix: Pass limit (int) instead of NoParams()
      final highRiskResult = await _getHighRiskDrugsUseCase(20);
      highRiskResult.fold(
        (l) => _logger.w(
          "Failed to load high risk drugs: ${_mapFailureToMessage(l)}",
        ),
        (r) {
          _highRiskDrugs = r;
          _logger.i("Loaded ${_highRiskDrugs.length} high risk drugs");
        },
      );
    } catch (e, s) {
      _logger.e("Error loading sections", e, s);
      _recentlyUpdatedDrugs = [];
      _popularDrugs = [];
      _highRiskDrugs = [];
    }
  }

  // --- Filter & Search Setters ---

  Future<void> setSearchQuery(String query, {bool triggerSearch = true}) async {
    if (_isLoading && triggerSearch) return;

    _searchQuery = query;
    _selectedCategory = ''; // Clear category when searching
    _currentPage = 0;
    _hasMoreItems = true;
    _filteredMedicines = [];

    if (!triggerSearch) {
      notifyListeners();
      return;
    }

    _triggerLoadingSearch(page: 0, append: false);
  }

  Future<void> setCategory(String category, {bool triggerSearch = true}) async {
    if (_isLoading && triggerSearch) return;

    _selectedCategory = category;
    _searchQuery = ''; // Clear search when selecting category
    _currentPage = 0;
    _hasMoreItems = true;
    _filteredMedicines = [];

    if (!triggerSearch) {
      notifyListeners();
      return;
    }

    _triggerLoadingSearch(page: 0, append: false);
  }

  Future<void> setDosageForm(
    String dosageForm, {
    bool triggerSearch = true,
  }) async {
    _selectedDosageForm = dosageForm;
    if (triggerSearch) {
      _currentPage = 0;
      _hasMoreItems = true;
      _filteredMedicines = [];
      _triggerLoadingSearch(page: 0, append: false);
    } else {
      notifyListeners();
    }
  }

  Future<void> setPriceRange(
    RangeValues? range, {
    bool triggerSearch = true,
  }) async {
    _selectedPriceRange = range;
    if (triggerSearch) {
      _currentPage = 0;
      _hasMoreItems = true;
      _filteredMedicines = [];
      _triggerLoadingSearch(page: 0, append: false);
    } else {
      notifyListeners();
    }
  }

  // Aliases
  void updateSearchQuery(String query) => setSearchQuery(query);
  void updateFilters({String? dosageForm, RangeValues? priceRange}) {
    if (dosageForm != null) setDosageForm(dosageForm);
    if (priceRange != null) setPriceRange(priceRange);
  }

  // --- Favorites Logic ---
  bool isFavorite(DrugEntity drug) {
    final id = drug.id?.toString() ?? drug.tradeName;
    return _favoriteIds.contains(id);
  }

  void toggleFavorite(DrugEntity drug) {
    final id = drug.id?.toString() ?? drug.tradeName;
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
      _favorites.removeWhere((d) => (d.id?.toString() ?? d.tradeName) == id);
    } else {
      _favoriteIds.add(id);
      _favorites.add(drug);
    }
    notifyListeners();
  }

  // --- Search Triggering ---

  Future<void> triggerSearch() async {
    if (_isLoading) return;
    _currentPage = 0;
    _hasMoreItems = true;
    _filteredMedicines = [];
    _triggerLoadingSearch(page: 0, append: false);
  }

  void _triggerLoadingSearch({required int page, required bool append}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _applyFilters(page: page, append: append);
    } catch (e, s) {
      _logger.e("Error during search/filter", e, s);
      _error = "حدث خطأ أثناء البحث/الفلترة";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreDrugs() async {
    if (_isLoading || _isLoadingMore || !_hasMoreItems) return;

    _isLoadingMore = true;
    notifyListeners();

    _currentPage++;

    try {
      await _applyFilters(page: _currentPage, append: true, limit: _pageSize);
    } catch (e) {
      // Error already handled in applyFilters or just ignore for load more
      _currentPage--; // Revert page on error
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Alias
  Future<void> loadMoreResults() => loadMoreDrugs();

  Future<void> _applyFilters({
    required int page,
    bool append = false,
    int? limit,
  }) async {
    final int requestedLimit = limit ?? _pageSize;
    final int fetchLimit =
        requestedLimit + 1; // Fetch one extra to check hasMore
    final int offset =
        (page == 0) ? 0 : _initialPageSize + (page - 1) * _pageSize;

    Either<Failure, List<DrugEntity>> result;

    if (_searchQuery.isNotEmpty) {
      result = await _searchDrugsUseCase(
        SearchParams(query: _searchQuery, limit: fetchLimit, offset: offset),
      );
    } else if (_selectedCategory.isNotEmpty) {
      result = await _filterDrugsByCategoryUseCase(
        FilterParams(
          category: _selectedCategory,
          limit: fetchLimit,
          offset: offset,
        ),
      );
    } else {
      result = await _searchDrugsUseCase(
        SearchParams(query: '', limit: fetchLimit, offset: offset),
      );
    }

    result.fold(
      (failure) {
        _logger.e("Error applying filters: $failure");
        _error = _mapFailureToMessage(failure);
        if (!append) _filteredMedicines = [];
        _hasMoreItems = false;
      },
      (drugs) {
        // Apply in-memory secondary filters
        List<DrugEntity> filtered = List.from(drugs);

        if (_selectedDosageForm.isNotEmpty) {
          final formLower = _selectedDosageForm.toLowerCase();
          filtered =
              filtered
                  .where((d) => d.dosageForm.toLowerCase().contains(formLower))
                  .toList();
        }

        if (_selectedPriceRange != null) {
          filtered =
              filtered.where((d) {
                final price = _parsePrice(d.price);
                if (price == null) return false;
                return price >= _selectedPriceRange!.start &&
                    price <= _selectedPriceRange!.end;
              }).toList();
        }

        _hasMoreItems = drugs.length == fetchLimit;
        // Remove the extra item if we fetched it
        final itemsToAdd =
            _hasMoreItems ? filtered.take(requestedLimit).toList() : filtered;

        if (append) {
          final existingIds =
              _filteredMedicines
                  .map((d) => d.id?.toString() ?? d.tradeName)
                  .toSet();
          _filteredMedicines.addAll(
            itemsToAdd.where(
              (d) => !existingIds.contains(d.id?.toString() ?? d.tradeName),
            ),
          );
        } else {
          _filteredMedicines = itemsToAdd;
        }
        _error = '';
      },
    );
  }

  // --- Methods for Drug Details Screen (Added) ---

  Future<List<DrugEntity>> getSimilarDrugs(DrugEntity drug) async {
    // Similars = Same Active Ingredient (Mathayel)
    // We use FindDrugAlternativesUseCase which implements active ingredient matching
    final useCase = locator<FindDrugAlternativesUseCase>();
    final result = await useCase(drug);
    return result.fold((l) => [], (r) => r.alternatives);
  }

  Future<List<DrugEntity>> getAlternativeDrugs(DrugEntity drug) async {
    // Alternatives = Same Indication/Category but Different Active Ingredient (Badael)
    if (drug.mainCategory == null || drug.mainCategory!.isEmpty) return [];

    final result = await _filterDrugsByCategoryUseCase(
      FilterParams(category: drug.mainCategory!, limit: 20, offset: 0),
    );

    return result.fold(
      (l) => [],
      (drugs) =>
          drugs
              .where(
                (d) =>
                    (d.id?.toString() ?? d.tradeName) !=
                        (drug.id?.toString() ?? drug.tradeName) &&
                    (d.active?.toLowerCase() != drug.active?.toLowerCase()),
              )
              .toList(),
    );
  }

  Future<List<DosageGuidelinesModel>> getDosageGuidelines(
    String activeIngredient,
  ) async {
    // Directly access local data source for dosage guidelines
    // Since this is specific to the local SQLite DB "Dosage Guidelines" table.
    try {
      if (activeIngredient.isEmpty) return [];
      return await _localDataSource.getDosageGuidelines(activeIngredient);
    } catch (e) {
      _logger.e("Error fetching dosage guidelines: $e");
      return [];
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'خطأ في الخادم (Server Failure).';
    } else if (failure is CacheFailure) {
      return 'فشل في تحميل البيانات من قاعدة البيانات.';
    } else {
      return 'حدث خطأ غير متوقع.';
    }
  }
}
