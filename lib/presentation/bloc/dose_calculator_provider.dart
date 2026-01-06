import 'package:flutter/foundation.dart';

import '../../domain/entities/dosage_result.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/services/dosage_calculator_service.dart';

class DoseCalculatorProvider extends ChangeNotifier {
  // --- State Variables ---
  DrugEntity? _selectedDrug;
  String _weightInput = '';
  String _ageInput = ''; // Added age input state
  String _durationInput = '3'; // Default to 3 days
  DosageResult? _dosageResult; // Changed state variable
  bool _isLoading = false;
  String _error = '';
  bool _showDrugSelectionError = false;

  final DosageCalculatorService _dosageCalculatorService;

  DoseCalculatorProvider({DosageCalculatorService? dosageCalculatorService})
    : _dosageCalculatorService =
          dosageCalculatorService ?? DosageCalculatorService();

  // --- Getters ---
  bool get isLoading => _isLoading;
  String get error => _error;
  DrugEntity? get selectedDrug => _selectedDrug;
  String get weightInput => _weightInput;
  String get ageInput => _ageInput;
  String get durationInput => _durationInput;
  DosageResult? get dosageResult => _dosageResult;
  bool get showDrugSelectionError => _showDrugSelectionError;

  // Getters for parsed values (used by UI for initialization)
  double? get weight => double.tryParse(_weightInput);
  int? get age => int.tryParse(_ageInput);

  // --- Methods ---

  void setSelectedDrug(DrugEntity? drug) {
    _selectedDrug = drug;
    clearResult(); // Clear result when drug changes
    _showDrugSelectionError = false;
    notifyListeners();
  }

  void setWeight(String weight) {
    _weightInput = weight;
    clearResult(); // Clear result on input change
    notifyListeners();
  }

  void setAge(String age) {
    _ageInput = age;
    clearResult(); // Clear result on input change
    notifyListeners();
  }

  void setDuration(String duration) {
    _durationInput = duration;
    clearResult();
    notifyListeners();
  }

  // Method to clear the result and error
  void clearResult() {
    _dosageResult = null;
    _error = '';
    // Don't reset _showDrugSelectionError here, let validation handle it
    notifyListeners();
  }

  Future<void> calculateDose() async {
    _error = '';
    _showDrugSelectionError = false;
    _dosageResult = null;

    if (_selectedDrug == null) {
      _showDrugSelectionError = true;
      notifyListeners();
      return;
    }

    if (_weightInput.isEmpty || _ageInput.isEmpty) {
      _error = 'يرجى إدخال الوزن والعمر.';
      notifyListeners();
      return;
    }

    final weightKg = double.tryParse(_weightInput);
    final ageYears = int.tryParse(_ageInput);
    final durationDays = int.tryParse(_durationInput);

    if (weightKg == null || weightKg <= 0) {
      _error = 'الوزن المدخل غير صالح.';
      notifyListeners();
      return;
    }

    if (ageYears == null || ageYears < 0) {
      _error = 'العمر المدخل غير صالح.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // استخدام الدالة الجديدة مع guidelines
      _dosageResult = _dosageCalculatorService.calculateDosageFromDB(
        _selectedDrug!,
        weightKg,
        ageYears,
        durationDays: durationDays,
      );
      _error = '';
    } catch (e) {
      print('Error during dose calculation: $e');
      _error = 'حدث خطأ غير متوقع أثناء حساب الجرعة.';
      _dosageResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to map Failure types (if service starts returning Either)
  // String _mapFailureToMessage(Failure failure) { ... }
}
