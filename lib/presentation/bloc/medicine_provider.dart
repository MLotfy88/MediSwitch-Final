import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Import Material for RangeValues
import 'package:intl/intl.dart'; // Import intl for DateFormat
import 'package:dartz/dartz.dart'; // Import dartz for Either
import '../../core/error/failures.dart'; // Import Failure base class
import '../../domain/entities/drug_entity.dart'; // Import DrugEntity
import '../../domain/usecases/get_all_drugs.dart';
import '../../domain/usecases/search_drugs.dart';
import '../../domain/usecases/filter_drugs_by_category.dart';
import '../../domain/usecases/get_available_categories.dart';
import '../../domain/usecases/get_last_update_timestamp.dart';
import '../../domain/usecases/get_analytics_summary.dart'; // Import analytics use case
import '../../domain/repositories/analytics_repository.dart'; // Import AnalyticsSummary entity
import '../../core/usecases/usecase.dart';

class MedicineProvider extends ChangeNotifier {
  final GetAllDrugs getAllDrugsUseCase;
  final SearchDrugsUseCase searchDrugsUseCase;
  final FilterDrugsByCategoryUseCase filterDrugsByCategoryUseCase;
  final GetAvailableCategoriesUseCase getAvailableCategoriesUseCase;
  final GetLastUpdateTimestampUseCase getLastUpdateTimestampUseCase;
  final GetAnalyticsSummary
  getAnalyticsSummaryUseCase; // Inject analytics use case

  // State variables - now using DrugEntity
  List<DrugEntity> _medicines = [];
  List<DrugEntity> _filteredMedicines = [];
  List<DrugEntity> _recentlyUpdatedMedicines = []; // Added for Task 3.1.6
  List<String> _categories = [];
  List<DrugEntity> _popularDrugs = []; // Added state for popular drugs
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedDosageForm = ''; // Added state for dosage form filter
  RangeValues? _selectedPriceRange; // Added state for price range filter
  double _minPrice = 0; // Added state for min price
  double _maxPrice = 1000; // Added state for max price (default)
  bool _isLoading = true;
  String _error = '';
  int? _lastUpdateTimestamp;

  // Constructor injection for the UseCases (replace with DI later)
  MedicineProvider({
    required this.getAllDrugsUseCase,
    required this.searchDrugsUseCase,
    required this.filterDrugsByCategoryUseCase,
    required this.getAvailableCategoriesUseCase,
    required this.getLastUpdateTimestampUseCase,
    required this.getAnalyticsSummaryUseCase, // Add analytics use case to constructor
  }) {
    loadInitialData();
  }

  // Getters - expose DrugEntity lists
  List<DrugEntity> get medicines => _medicines;
  List<DrugEntity> get filteredMedicines => _filteredMedicines;
  List<DrugEntity> get recentlyUpdatedMedicines => _recentlyUpdatedMedicines;
  List<DrugEntity> get popularDrugs => _popularDrugs; // Added getter
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedDosageForm => _selectedDosageForm; // Added getter
  RangeValues? get selectedPriceRange => _selectedPriceRange; // Added getter
  double get minPrice => _minPrice; // Added getter
  double get maxPrice => _maxPrice; // Added getter

  // Getter to format the timestamp for display
  String get lastUpdateTimestampFormatted {
    if (_lastUpdateTimestamp == null) {
      return 'غير متوفر'; // "Not available"
    }
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(
        _lastUpdateTimestamp!,
      );
      // Basic formatting, consider using 'intl' package for better localization
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print("Error formatting timestamp: $e");
      return 'تنسيق غير صالح'; // "Invalid format"
    }
  }

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
        _recentlyUpdatedMedicines = []; // Also clear recently updated
        _categories = [];
        _isLoading = false; // Set loading false on failure
        notifyListeners(); // Notify after failure state update
      },
      (drugs) async {
        // Make the success callback async
        // Handle Success case
        _medicines = drugs;
        _filteredMedicines = drugs; // Initially show all
        _error = '';
        // Populate recently updated list (Task 3.1.6)
        _populateRecentlyUpdated(drugs);
        // Now load categories after drugs are loaded
        await _loadCategories(); // This await is now valid
        await _loadAndUpdateTimestamp();
        await _loadPopularDrugs(); // Load popular drugs after main list is ready
        _calculatePriceRange(drugs); // Calculate min/max price
        await _applyFilters(); // This already sets isLoading=false and notifies
      },
    );
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

  // Helper to load and update the timestamp
  Future<void> _loadAndUpdateTimestamp() async {
    final failureOrTimestamp = await getLastUpdateTimestampUseCase(NoParams());
    failureOrTimestamp.fold(
      (failure) {
        // Log error, but don't necessarily show it to the user here
        print(
          "Error loading last update timestamp: ${_mapFailureToMessage(failure)}",
        );
        _lastUpdateTimestamp = null;
      },
      (timestamp) {
        _lastUpdateTimestamp = timestamp;
        if (kDebugMode) {
          print("Last update timestamp loaded: $_lastUpdateTimestamp");
        }
      },
    );
    // No need to notifyListeners here, loadInitialData will do it.
  }

  // --- Helper to populate recently updated list ---
  void _populateRecentlyUpdated(List<DrugEntity> drugs) {
    // Simple logic: Sort by lastPriceUpdate (assuming format is parseable)
    // and take the top N (e.g., 10). Needs error handling for date parsing.
    try {
      List<DrugEntity> sortedDrugs = List.from(drugs);
      // Filter out drugs with empty or invalid date strings before sorting
      sortedDrugs.removeWhere(
        (drug) => drug.lastPriceUpdate == null || drug.lastPriceUpdate!.isEmpty,
      );
      // Sort remaining drugs using robust date parsing
      sortedDrugs.sort((a, b) {
        DateTime? dateA = _parseDate(a.lastPriceUpdate);
        DateTime? dateB = _parseDate(b.lastPriceUpdate);
        // Treat null dates as oldest
        if (dateB == null && dateA == null) return 0;
        if (dateB == null) return -1; // b is older
        if (dateA == null) return 1; // a is older
        return dateB.compareTo(dateA); // Sort descending (newest first)
      });
      // Take the top 10 (or fewer if less than 10 exist)
      _recentlyUpdatedMedicines = sortedDrugs.take(10).toList();
      if (kDebugMode) {
        print(
          'Populated recently updated list with ${_recentlyUpdatedMedicines.length} items.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error populating recently updated list: $e');
      }
      _recentlyUpdatedMedicines = []; // Clear list on error
    }
    // No need to notifyListeners here, loadInitialData will do it.
  }

  // --- Helper to load popular drugs based on analytics ---
  Future<void> _loadPopularDrugs() async {
    if (_medicines.isEmpty) {
      _popularDrugs = [];
      return; // Cannot determine popular if base list is empty
    }

    final failureOrSummary = await getAnalyticsSummaryUseCase(NoParams());

    failureOrSummary.fold(
      (failure) {
        // Log error but don't block UI for this
        print(
          "Error loading analytics summary: ${_mapFailureToMessage(failure)}",
        );
        _popularDrugs = []; // Default to empty on error
      },
      (summary) {
        final List<DrugEntity> foundPopular = [];
        final Set<String> addedDrugNames = {}; // To avoid duplicates

        // Get top search terms (lowercase)
        final topTerms =
            summary.topSearchQueries
                .map((item) => (item['query'] as String?)?.toLowerCase())
                .where((term) => term != null && term.isNotEmpty)
                .toList();

        if (kDebugMode) {
          print("Top search terms from analytics: $topTerms");
        }

        // Find corresponding drugs from the main list
        for (final term in topTerms) {
          if (foundPopular.length >= 10) break; // Limit to 10 popular drugs

          // Search by trade name or arabic name (case-insensitive)
          final matchingDrug = _medicines.firstWhere(
            (drug) =>
                drug.tradeName.toLowerCase().contains(term!) ||
                drug.arabicName.toLowerCase().contains(term),
            orElse: () => DrugEntity.empty(), // Return empty if not found
          );

          if (matchingDrug != DrugEntity.empty() &&
              !addedDrugNames.contains(matchingDrug.tradeName)) {
            foundPopular.add(matchingDrug);
            addedDrugNames.add(matchingDrug.tradeName);
          }
        }
        // If no popular drugs found via analytics, use recently updated as fallback for now
        if (foundPopular.isEmpty && _recentlyUpdatedMedicines.isNotEmpty) {
          _popularDrugs = List.from(_recentlyUpdatedMedicines); // Use a copy
          if (kDebugMode) {
            print(
              "No analytics data for popular drugs, using recently updated as fallback.",
            );
          }
        } else {
          _popularDrugs = foundPopular;
          if (kDebugMode) {
            print(
              "Found ${_popularDrugs.length} popular drugs based on analytics.",
            );
          }
        }
      },
    );
    // No need to notifyListeners here, loadInitialData will do it.
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await _applyFilters();
  }

  Future<void> setCategory(String category) async {
    _selectedCategory = category;
    await _applyFilters();
  }

  // Added setters for new filters
  Future<void> setDosageForm(String dosageForm) async {
    _selectedDosageForm = dosageForm;
    await _applyFilters();
  }

  Future<void> setPriceRange(RangeValues? range) async {
    _selectedPriceRange = range;
    await _applyFilters();
  }

  // Apply filters (including new ones)
  Future<void> _applyFilters() async {
    _isLoading = true; // Indicate loading during filtering
    _error = '';
    notifyListeners();

    // Start with the full list of medicines
    Either<Failure, List<DrugEntity>> result = Right(_medicines);

    // 1. Apply Search Query Filter (if any)
    if (_searchQuery.isNotEmpty) {
      result = await searchDrugsUseCase(SearchParams(query: _searchQuery));
    }

    // Apply subsequent filters only if the previous step was successful
    result = result.fold(
      (failure) => Left(failure), // Pass failure through
      (currentDrugs) {
        List<DrugEntity> filtered = List.from(
          currentDrugs,
        ); // Create a mutable copy

        // 2. Apply Category Filter (if any)
        if (_selectedCategory.isNotEmpty) {
          final lowerCaseCategory = _selectedCategory.toLowerCase();
          filtered =
              filtered.where((drug) {
                final mainCatLower = (drug.mainCategory ?? '').toLowerCase();
                return mainCatLower == lowerCaseCategory;
              }).toList();
        }

        // 3. Apply Dosage Form Filter (if any)
        if (_selectedDosageForm.isNotEmpty) {
          final lowerCaseDosage = _selectedDosageForm.toLowerCase();
          filtered =
              filtered.where((drug) {
                final formLower = (drug.dosageForm ?? '').toLowerCase();
                // Simple contains check, might need refinement based on data
                return formLower.contains(lowerCaseDosage);
              }).toList();
        }

        // 4. Apply Price Range Filter (if any)
        if (_selectedPriceRange != null) {
          filtered =
              filtered.where((drug) {
                final price = double.tryParse(drug.price);
                if (price == null)
                  return false; // Exclude drugs with unparseable prices
                return price >= _selectedPriceRange!.start &&
                    price <= _selectedPriceRange!.end;
              }).toList();
        }

        return Right(filtered); // Return the final filtered list
      },
    );

    // Update final state based on the result
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
      case InitialLoadFailure: // Handle the new failure type
        return 'فشل تحميل البيانات الأولية. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
      // case ServerFailure:
      //   return 'خطأ في الاتصال بالخادم.';
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

    // Handle cases where no valid prices were found or min/max are illogical
    _minPrice = (min == double.maxFinite) ? 0 : min;
    // Ensure max is at least min, provide a default range if max is still 0
    _maxPrice =
        (max == 0 || max < _minPrice)
            ? (_minPrice > 900
                ? _minPrice + 100
                : 1000) // Add 100 if min is high, else default 1000
            : max;
    // Ensure max is strictly greater than min if they ended up equal
    if (_maxPrice <= _minPrice) {
      _maxPrice = _minPrice + 1; // Add a small amount to max if equal to min
    }

    // Reset selected range if it's outside the new bounds (optional)
    // if (_selectedPriceRange != null &&
    //     (_selectedPriceRange!.start < _minPrice || _selectedPriceRange!.end > _maxPrice)) {
    //   _selectedPriceRange = null; // Or RangeValues(_minPrice, _maxPrice);
    // }

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
      // Attempt common formats, add more if needed
      return DateFormat('yyyy-MM-dd').parseStrict(dateString);
    } catch (e) {
      try {
        // Try another format if the first fails
        return DateFormat('dd/MM/yyyy').parseStrict(dateString);
      } catch (e2) {
        if (kDebugMode) {
          print("Could not parse date: $dateString - Error: $e2");
        }
        return null; // Return null if parsing fails
      }
    }
  }
}
