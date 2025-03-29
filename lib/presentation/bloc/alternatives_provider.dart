import 'package:flutter/foundation.dart';
import '../../core/error/failures.dart'; // Import Failure
import '../../domain/entities/drug_entity.dart';
import '../../domain/usecases/find_drug_alternatives.dart'; // Import the use case

class AlternativesProvider extends ChangeNotifier {
  final FindDrugAlternativesUseCase findDrugAlternativesUseCase;

  // --- State Variables ---
  DrugEntity? _originalDrug;
  // List<DrugEntity> _similars = []; // Removed similars for now
  List<DrugEntity> _alternatives = []; // List to hold alternative drugs
  bool _isLoading = false;
  String _error = '';

  // Constructor with UseCase injection
  AlternativesProvider({required this.findDrugAlternativesUseCase});

  // --- Getters ---
  bool get isLoading => _isLoading;
  String get error => _error;
  DrugEntity? get originalDrug => _originalDrug;
  List<DrugEntity> get alternatives => _alternatives;

  // --- Methods ---

  // Method to set the original drug and trigger finding alternatives
  Future<void> findAlternativesFor(DrugEntity drug) async {
    _originalDrug = drug;
    _isLoading = true;
    _error = '';
    // _similars = []; // Clear previous similars
    _alternatives = []; // Clear previous alternatives
    notifyListeners();

    final failureOrAlternativesResult = await findDrugAlternativesUseCase(drug);

    failureOrAlternativesResult.fold(
      (failure) {
        print('Error finding alternatives: $failure');
        _error = _mapFailureToMessage(failure); // Use helper to map failure
        // _similars = [];
        _alternatives = [];
      },
      (result) {
        // _similars = result.similars; // Assign similars when re-enabled
        _alternatives = result.alternatives;
        _error = ''; // Clear error on success
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Helper to map Failure types to user-friendly messages (similar to MedicineProvider)
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'خطأ في الوصول للبيانات المحلية للبحث عن بدائل.';
      case ServerFailure:
        return 'خطأ في الخادم أثناء البحث عن بدائل.';
      case NetworkFailure:
        return 'خطأ في الشبكة أثناء البحث عن بدائل.';
      default:
        return 'حدث خطأ غير متوقع أثناء البحث عن بدائل.';
    }
  }
}
