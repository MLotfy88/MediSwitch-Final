import 'package:flutter/foundation.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/dosage_result.dart'; // Import DosageResult
import '../../domain/services/dosage_calculator_service.dart'; // Import Service

class DoseCalculatorProvider extends ChangeNotifier {
  // --- State Variables ---
  DrugEntity? _selectedDrug;
  String _weightInput = '';
  String _ageInput = ''; // Added age input state
  DosageResult? _dosageResult; // Changed state variable
  bool _isLoading = false;
  String _error = '';

  // Inject the service
  final DosageCalculatorService _dosageCalculatorService;

  // Constructor
  // Initialize the service in the constructor
  DoseCalculatorProvider({DosageCalculatorService? dosageCalculatorService})
    : _dosageCalculatorService =
          dosageCalculatorService ?? DosageCalculatorService();

  // --- Getters ---
  bool get isLoading => _isLoading;
  String get error => _error;
  DrugEntity? get selectedDrug => _selectedDrug;
  String get weightInput => _weightInput;
  String get ageInput => _ageInput; // Added age getter
  DosageResult? get dosageResult => _dosageResult; // Changed getter

  // --- Methods ---

  // Method to set the selected drug
  void setSelectedDrug(DrugEntity? drug) {
    // Allow null to clear selection
    _selectedDrug = drug;
    // Reset calculation when drug changes
    _dosageResult = null; // Clear result
    _error = '';
    notifyListeners();
  }

  // Method to set weight
  void setWeight(String weight) {
    _weightInput = weight;
    _dosageResult = null; // Clear result on input change
    _error = '';
    notifyListeners();
  }

  // Method to set age
  void setAge(String age) {
    _ageInput = age;
    _dosageResult = null; // Clear result on input change
    _error = '';
    notifyListeners();
  }

  // Method to perform calculation
  // Method to perform calculation
  Future<void> calculateDose() async {
    if (_selectedDrug == null || _weightInput.isEmpty || _ageInput.isEmpty) {
      _error = 'يرجى اختيار الدواء وإدخال الوزن والعمر.';
      _dosageResult = null; // Clear previous result
      notifyListeners();
      return;
    }

    final weightKg = double.tryParse(_weightInput);
    final ageYears = int.tryParse(_ageInput);

    if (weightKg == null || weightKg <= 0) {
      _error = 'الوزن المدخل غير صالح.';
      _dosageResult = null;
      notifyListeners();
      return;
    }

    if (ageYears == null || ageYears < 0) {
      _error = 'العمر المدخل غير صالح.';
      _dosageResult = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    _dosageResult = null; // Clear previous result before calculation
    notifyListeners();

    try {
      // Simulate calculation delay (optional, can be removed)
      // await Future.delayed(const Duration(milliseconds: 100));

      // Call the dosage calculation service
      _dosageResult = _dosageCalculatorService.calculateDosage(
        _selectedDrug!,
        weightKg,
        ageYears,
      );

      _error = ''; // Clear error on success
    } catch (e) {
      // Although the service currently doesn't throw, catch potential future errors
      print('Error during dose calculation: $e');
      _error = 'حدث خطأ غير متوقع أثناء حساب الجرعة.';
      _dosageResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
