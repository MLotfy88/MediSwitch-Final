import 'package:flutter/foundation.dart'; // For ChangeNotifier
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
        await _applyFilters();
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
      // Sort remaining drugs
      sortedDrugs.sort((a, b) {
        // Basic date comparison, assumes 'YYYY-MM-DD' or similar sortable format
        // TODO: Implement robust date parsing (e.g., using intl package) if format varies
        return (b.lastPriceUpdate ?? '').compareTo(a.lastPriceUpdate ?? '');
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
        _popularDrugs = foundPopular;
        if (kDebugMode) {
          print(
            "Found ${_popularDrugs.length} popular drugs based on analytics.",
          );
        }
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
      case InitialLoadFailure: // Handle the new failure type
        return 'فشل تحميل البيانات الأولية. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
      // case ServerFailure:
      //   return 'خطأ في الاتصال بالخادم.';
      default:
        return 'حدث خطأ غير متوقع.';
    }
  }
}
