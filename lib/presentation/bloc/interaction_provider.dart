// lib/presentation/bloc/interaction_provider.dart

import 'package:flutter/foundation.dart';

import '../../core/di/locator.dart'; // Import locator
import '../../core/services/file_logger_service.dart'; // Import logger
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../domain/entities/interaction_analysis_result.dart';
import '../../domain/repositories/interaction_repository.dart';
import '../../domain/services/interaction_checker_service.dart';
// Assuming InteractionRepositoryImpl provides the loaded data for now
// In a real app, you might inject the repository and load data here or ensure it's loaded elsewhere.
// import '../../data/repositories/interaction_repository_impl.dart'; // Not needed if using interface

class InteractionProvider extends ChangeNotifier {
  final InteractionRepository _interactionRepository; // To load data if needed
  final InteractionCheckerService _interactionCheckerService;
  final FileLoggerService _logger =
      locator<FileLoggerService>(); // Get logger instance

  // State Variables
  final List<DrugEntity> _selectedMedicines = [];
  InteractionAnalysisResult? _analysisResult;
  bool _isLoading = false;
  String _error = '';
  bool _isInteractionDataLoaded = false; // Track if data is loaded

  // Constructor
  InteractionProvider({
    required InteractionRepository interactionRepository, // Require injection
    required InteractionCheckerService
    interactionCheckerService, // Require injection
  }) : _interactionRepository = interactionRepository,
       _interactionCheckerService = interactionCheckerService {
    _logger.i("InteractionProvider: Constructor called.");
    // Re-enable auto-load
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
    if (_isInteractionDataLoaded) {
      _logger.d(
        "InteractionProvider: Interaction data already loaded. Skipping.",
      );
      return;
    }
    _logger.i("InteractionProvider: Loading interaction data...");
    _isLoading = true;
    _error = '';
    notifyListeners();

    final result = await _interactionRepository.loadInteractionData();
    result.fold(
      (failure) {
        _error = failure.message ?? 'Failed to load interaction data.';
        _isInteractionDataLoaded = false;
        _logger.e(
          "InteractionProvider: Error loading interaction data: $_error",
          failure,
        );
      },
      (_) {
        _error = '';
        _isInteractionDataLoaded = true;
        _logger.i("InteractionProvider: Interaction data loaded successfully.");
        // Optionally trigger analysis if medicines were already selected?
        if (_selectedMedicines.isNotEmpty) {
          _logger.d(
            "InteractionProvider: Triggering analysis after data load.",
          );
          analyzeInteractions(); // Call public method
        }
      },
    );
    _isLoading = false;
    notifyListeners();
  }

  void addMedicine(DrugEntity medicine) {
    if (!_selectedMedicines.any((m) => m.tradeName == medicine.tradeName)) {
      _logger.d("InteractionProvider: Adding medicine: ${medicine.tradeName}");
      _selectedMedicines.add(medicine);
      _analysisResult = null; // Clear previous results
      _error = '';
      notifyListeners();
      if (_selectedMedicines.length >= 2) {
        analyzeInteractions(); // Trigger analysis
      }
    } else {
      _logger.w(
        "InteractionProvider: Medicine already selected: ${medicine.tradeName}",
      );
    }
  }

  void removeMedicine(DrugEntity medicine) {
    _logger.d("InteractionProvider: Removing medicine: ${medicine.tradeName}");
    _selectedMedicines.removeWhere((m) => m.tradeName == medicine.tradeName);
    _analysisResult = null; // Clear previous results
    _error = '';
    notifyListeners();
    if (_selectedMedicines.length >= 2) {
      analyzeInteractions(); // Re-trigger analysis
    }
  }

  void clearSelection() {
    _logger.d("InteractionProvider: Clearing selection.");
    _selectedMedicines.clear();
    _analysisResult = null;
    _error = '';
    notifyListeners();
  }

  // Public method to perform analysis, callable from UI
  Future<void> analyzeInteractions() async {
    _logger.i("InteractionProvider: analyzeInteractions called.");
    if (!_isInteractionDataLoaded) {
      _error = "بيانات التفاعلات لم يتم تحميلها بعد.";
      _logger.w("InteractionProvider: Analysis attempted before data loaded.");
      notifyListeners();
      // Consider triggering _loadInteractionData() here or providing a retry button
      return;
    }
    if (_selectedMedicines.length < 2) {
      _logger.d(
        "InteractionProvider: Less than 2 medicines selected, clearing results.",
      );
      _analysisResult = null; // Clear results if less than 2 drugs
      _error = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    _logger.i(
      "InteractionProvider: Analyzing interactions for ${_selectedMedicines.length} drugs...",
    );

    try {
      // Use the public getters from the repository interface
      final allInteractions = _interactionRepository.allLoadedInteractions;
      final ingredientsMap = _interactionRepository.medicineToIngredientsMap;
      _logger.v(
        "InteractionProvider: Got ${allInteractions.length} interactions and ${ingredientsMap.length} ingredient mappings from repository.",
      );

      final result = _interactionCheckerService.analyzeInteractions(
        _selectedMedicines,
        allInteractions,
        ingredientsMap,
      );
      _analysisResult = result;
      _error = '';
      _logger.i(
        "InteractionProvider: Analysis complete. Found ${result.interactions.length} interactions.",
      );
    } catch (e, s) {
      // Add stack trace
      _logger.e(
        "InteractionProvider: Error during analysis",
        e,
        s,
      ); // Correct parameters
      _error = 'حدث خطأ أثناء تحليل التفاعلات.';
      _analysisResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      _logger.d(
        "InteractionProvider: analyzeInteractions finished. isLoading: $_isLoading",
      );
    }
  }

  /// Get interactions for a specific drug
  Future<List<DrugInteraction>> getDrugInteractions(DrugEntity drug) async {
    _logger.i(
      "InteractionProvider: Getting interactions for '${drug.tradeName}'",
    );

    if (!_isInteractionDataLoaded) {
      _logger.w(
        "InteractionProvider: Interaction data not loaded yet, attempting to load...",
      );
      await _loadInteractionData();
      if (!_isInteractionDataLoaded) {
        _logger.e("InteractionProvider: Failed to load interaction data");
        return [];
      }
    }

    try {
      // Get drug's active ingredients (may contain multiple separated by + or /)
      final rawActive = drug.active.toLowerCase().trim();
      if (rawActive.isEmpty) {
        _logger.w(
          "InteractionProvider: Drug '${drug.tradeName}' has no active ingredient",
        );
        return [];
      }

      // Split active ingredients by common separators
      final activeIngredients =
          rawActive
              .split(RegExp(r'[+/,&]|\s+and\s+|\s+with\s+'))
              .map((e) => e.trim())
              .where((e) => e.length > 2)
              .toList();

      if (activeIngredients.isEmpty) {
        activeIngredients.add(rawActive);
      }

      // Get all interactions
      final allInteractions = _interactionRepository.allLoadedInteractions;

      // Filter interactions that involve any of this drug's active ingredients
      final drugInteractions =
          allInteractions.where((interaction) {
            final ing1 = interaction.ingredient1.toLowerCase().trim();
            final ing2 = interaction.ingredient2.toLowerCase().trim();

            // Check if any active ingredient matches
            for (final activeIng in activeIngredients) {
              if (ing1 == activeIng ||
                  ing2 == activeIng ||
                  ing1.contains(activeIng) ||
                  ing2.contains(activeIng) ||
                  activeIng.contains(ing1) ||
                  activeIng.contains(ing2)) {
                return true;
              }
            }
            return false;
          }).toList();

      _logger.i(
        "InteractionProvider: Found ${drugInteractions.length} interactions for '${drug.tradeName}' with ingredients: $activeIngredients",
      );

      return drugInteractions;
    } catch (e, s) {
      _logger.e("InteractionProvider: Error getting drug interactions", e, s);
      return [];
    }
  }
}

// Removed the temporary extension InteractionRepositoryInternalAccess
