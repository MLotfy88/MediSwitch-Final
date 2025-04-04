// lib/presentation/bloc/interaction_provider.dart

import 'package:flutter/foundation.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../domain/entities/interaction_analysis_result.dart';
import '../../domain/repositories/interaction_repository.dart';
import '../../domain/services/interaction_checker_service.dart';
// Assuming InteractionRepositoryImpl provides the loaded data for now
// In a real app, you might inject the repository and load data here or ensure it's loaded elsewhere.
import '../../data/repositories/interaction_repository_impl.dart';

class InteractionProvider extends ChangeNotifier {
  // Injected dependencies (Consider using a proper DI solution like get_it later)
  // For simplicity now, we might instantiate them here or pass them in.
  // Let's assume InteractionRepositoryImpl holds the loaded data for now.
  final InteractionRepository _interactionRepository; // To load data if needed
  final InteractionCheckerService _interactionCheckerService;

  // State Variables
  final List<DrugEntity> _selectedMedicines = [];
  InteractionAnalysisResult? _analysisResult;
  bool _isLoading = false;
  String _error = '';
  bool _isInteractionDataLoaded = false; // Track if data is loaded

  // Constructor
  InteractionProvider({
    InteractionRepository? interactionRepository,
    InteractionCheckerService? interactionCheckerService,
  }) : _interactionRepository =
           interactionRepository ??
           InteractionRepositoryImpl(), // Use Impl for now
       _interactionCheckerService =
           interactionCheckerService ?? InteractionCheckerService() {
    // Attempt to load interaction data when the provider is created
    _loadInteractionData();
  }

  // Getters
  List<DrugEntity> get selectedMedicines =>
      List.unmodifiable(_selectedMedicines);
  InteractionAnalysisResult? get analysisResult => _analysisResult;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isInteractionDataReady =>
      _isInteractionDataLoaded; // Expose loaded status

  // --- Methods ---

  Future<void> _loadInteractionData() async {
    if (_isInteractionDataLoaded) return;
    _isLoading = true;
    _error = '';
    notifyListeners();
    print("InteractionProvider: Loading interaction data...");
    final result = await _interactionRepository.loadInteractionData();
    result.fold(
      (failure) {
        _error = failure.message ?? 'Failed to load interaction data.';
        _isInteractionDataLoaded = false;
        print("InteractionProvider: Error loading interaction data: $_error");
      },
      (_) {
        _error = '';
        _isInteractionDataLoaded = true;
        print("InteractionProvider: Interaction data loaded successfully.");
        // Optionally trigger analysis if medicines were already selected?
        if (_selectedMedicines.isNotEmpty) {
          _analyzeInteractions();
        }
      },
    );
    _isLoading = false;
    notifyListeners();
  }

  void addMedicine(DrugEntity medicine) {
    if (!_selectedMedicines.any((m) => m.tradeName == medicine.tradeName)) {
      // Avoid duplicates
      _selectedMedicines.add(medicine);
      _analysisResult = null; // Clear previous results
      _error = '';
      notifyListeners();
      if (_selectedMedicines.length >= 2) {
        _analyzeInteractions(); // Trigger analysis
      }
    }
  }

  void removeMedicine(DrugEntity medicine) {
    _selectedMedicines.removeWhere((m) => m.tradeName == medicine.tradeName);
    _analysisResult = null; // Clear previous results
    _error = '';
    notifyListeners();
    if (_selectedMedicines.length >= 2) {
      _analyzeInteractions(); // Re-trigger analysis
    }
  }

  void clearSelection() {
    _selectedMedicines.clear();
    _analysisResult = null;
    _error = '';
    notifyListeners();
  }

  // Internal method to perform analysis
  void _analyzeInteractions() {
    if (!_isInteractionDataLoaded) {
      _error = "بيانات التفاعلات لم يتم تحميلها بعد.";
      notifyListeners();
      _loadInteractionData(); // Try loading again
      return;
    }
    if (_selectedMedicines.length < 2) {
      _analysisResult = null; // Clear results if less than 2 drugs
      _error = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    print(
      "InteractionProvider: Analyzing interactions for ${_selectedMedicines.length} drugs...",
    );

    // Simulate analysis - In a real app, get loaded data from repository/cache
    // For now, we pass empty lists as placeholders for loaded data
    // This needs refinement: How does the provider access the loaded data?
    // Option 1: Inject InteractionRepositoryImpl and access its internal state (not ideal)
    // Option 2: Load data within the provider itself (done in _loadInteractionData)
    // Option 3: Use a separate data holder/cache service (better for larger apps)

    // Assuming _interactionRepository holds the data after load (needs adjustment in Impl)
    // This is a simplification and might need rework depending on how data is managed.
    // We need access to the actual loaded lists from the repository.
    // Let's simulate by calling the service directly for now.
    // A proper implementation would likely involve getting the data from the repository instance.

    try {
      // *** This part needs refinement based on how data is managed ***
      // *** Assuming repository holds data after loadInteractionData() ***
      // *** This direct call might bypass error handling in repository's find method ***
      final result = _interactionCheckerService.analyzeInteractions(
        _selectedMedicines,
        (_interactionRepository as InteractionRepositoryImpl)
            ._allInteractions, // Accessing internal state - Needs improvement
        (_interactionRepository as InteractionRepositoryImpl)
            ._medicineToIngredientsMap, // Accessing internal state - Needs improvement
      );
      _analysisResult = result;
      _error = '';
      print(
        "InteractionProvider: Analysis complete. Found ${result.interactions.length} interactions.",
      );
    } catch (e) {
      print("InteractionProvider: Error during analysis: $e");
      _error = 'حدث خطأ أثناء تحليل التفاعلات.';
      _analysisResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Helper extension for direct access - **REMOVE THIS IN A REAL APP**
// This is a temporary workaround to access internal state for demonstration.
// A better approach involves a dedicated method in the repository or a data cache.
extension InteractionRepositoryInternalAccess on InteractionRepository {
  List<DrugInteraction> get _allInteractions =>
      (this as InteractionRepositoryImpl)._allInteractions;
  Map<String, List<String>> get _medicineToIngredientsMap =>
      (this as InteractionRepositoryImpl)._medicineToIngredientsMap;
}
