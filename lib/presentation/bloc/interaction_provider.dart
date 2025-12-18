// lib/presentation/bloc/interaction_provider.dart

import 'package:flutter/foundation.dart';

import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../domain/entities/interaction_analysis_result.dart';
import '../../domain/entities/interaction_severity.dart';
import '../../domain/repositories/interaction_repository.dart';

class InteractionProvider extends ChangeNotifier {
  final InteractionRepository _interactionRepository;
  final FileLoggerService _logger = locator<FileLoggerService>();

  // State Variables
  final List<DrugEntity> _selectedMedicines = [];
  InteractionAnalysisResult? _analysisResult;
  bool _isLoading = false;
  String _error = '';
  bool _isInteractionDataLoaded = false;

  // Constructor
  InteractionProvider({required InteractionRepository interactionRepository})
    : _interactionRepository = interactionRepository {
    _logger.i("InteractionProvider: Constructor called.");
    _loadInteractionData();
  }

  // Getters
  List<DrugEntity> get selectedMedicines =>
      List.unmodifiable(_selectedMedicines);
  InteractionAnalysisResult? get analysisResult => _analysisResult;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isInteractionDataReady => _isInteractionDataLoaded;

  // --- Methods ---

  Future<void> _loadInteractionData() async {
    // No-op mostly as repo handles loading
    _isInteractionDataLoaded = true;
    notifyListeners();
  }

  void addMedicine(DrugEntity medicine) {
    if (!_selectedMedicines.any((m) => m.tradeName == medicine.tradeName)) {
      _logger.d("InteractionProvider: Adding medicine: ${medicine.tradeName}");
      _selectedMedicines.add(medicine);
      _analysisResult = null;
      _error = '';
      notifyListeners();
      if (_selectedMedicines.length >= 2) {
        analyzeInteractions();
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
    _analysisResult = null;
    _error = '';
    notifyListeners();
    if (_selectedMedicines.length >= 2) {
      analyzeInteractions();
    }
  }

  void clearSelection() {
    _logger.d("InteractionProvider: Clearing selection.");
    _selectedMedicines.clear();
    _analysisResult = null;
    _error = '';
    notifyListeners();
  }

  Future<void> analyzeInteractions() async {
    if (_selectedMedicines.length < 2) {
      _analysisResult = null;
      _error = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final resultEither = await _interactionRepository
          .findInteractionsForMedicines(_selectedMedicines);

      resultEither.fold(
        (failure) {
          _error = failure.message ?? 'Error analyzing interactions';
          _analysisResult = null;
        },
        (interactions) {
          _analysisResult = InteractionAnalysisResult(
            interactions: interactions,
            overallSeverity: _calculateOverallSeverity(interactions),
            recommendations:
                interactions.isNotEmpty
                    ? ['Check individual interactions for details.']
                    : ['No known interactions found.'],
          );
        },
      );
    } catch (e, s) {
      _logger.e("InteractionProvider: Error during analysis", e, s);
      _error = 'حدث خطأ أثناء تحليل التفاعلات.';
      _analysisResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<DrugInteraction>> getDrugInteractions(DrugEntity drug) async {
    try {
      final result = await _interactionRepository.findAllInteractionsForDrug(
        drug,
      );
      return result.fold((failure) => [], (interactions) => interactions);
    } catch (e, s) {
      _logger.e("InteractionProvider: Error getting drug interactions", e, s);
      return [];
    }
  }

  InteractionSeverity _calculateOverallSeverity(
    List<DrugInteraction> interactions,
  ) {
    InteractionSeverity max = InteractionSeverity.unknown;
    for (var i in interactions) {
      final InteractionSeverity current = _parseSeverity(i.severity);
      if (_getSeverityWeight(current) > _getSeverityWeight(max)) {
        max = current;
      }
    }
    return max;
  }

  InteractionSeverity _parseSeverity(dynamic severity) {
    if (severity is InteractionSeverity) return severity;
    if (severity is String) {
      switch (severity.toLowerCase()) {
        case 'contraindicated':
          return InteractionSeverity.contraindicated;
        case 'severe':
          return InteractionSeverity.severe;
        case 'major':
          return InteractionSeverity.major;
        case 'moderate':
          return InteractionSeverity.moderate;
        case 'minor':
          return InteractionSeverity.minor;
        default:
          return InteractionSeverity.unknown;
      }
    }
    return InteractionSeverity.unknown;
  }

  int _getSeverityWeight(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return 5;
      case InteractionSeverity.severe:
        return 4;
      case InteractionSeverity.major:
        return 3;
      case InteractionSeverity.moderate:
        return 2;
      case InteractionSeverity.minor:
        return 1;
      case InteractionSeverity.unknown:
        return 0;
    }
  }
}
