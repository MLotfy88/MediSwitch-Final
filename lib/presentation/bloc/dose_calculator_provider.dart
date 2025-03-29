import 'package:flutter/foundation.dart';
import '../../domain/entities/drug_entity.dart';

class DoseCalculatorProvider extends ChangeNotifier {
  // --- State Variables ---
  DrugEntity? _selectedDrug;
  String _weightInput = '';
  double? _calculatedDose;
  bool _isLoading = false;
  String _error = '';

  // TODO: Inject necessary UseCases if calculation needs more drug details

  // Constructor
  DoseCalculatorProvider();

  // --- Getters ---
  bool get isLoading => _isLoading;
  String get error => _error;
  DrugEntity? get selectedDrug => _selectedDrug;
  String get weightInput => _weightInput;
  double? get calculatedDose => _calculatedDose;

  // --- Methods ---

  // Method to set the selected drug
  void setSelectedDrug(DrugEntity? drug) {
    // Allow null to clear selection
    _selectedDrug = drug;
    // Reset calculation when drug changes
    _calculatedDose = null;
    _error = '';
    notifyListeners();
  }

  // Method to set weight
  void setWeight(String weight) {
    _weightInput = weight;
    // Optionally clear previous calculation/error when weight changes
    // _calculatedDose = null;
    // _error = '';
    notifyListeners(); // Notify if UI needs to react to weight input change directly
  }

  // Method to perform calculation
  Future<void> calculateDose() async {
    if (_selectedDrug == null || _weightInput.isEmpty) {
      _error = 'يرجى اختيار الدواء وإدخال الوزن.';
      _calculatedDose = null; // Clear previous dose on error
      notifyListeners();
      return;
    }

    final weightKg = double.tryParse(_weightInput);
    if (weightKg == null || weightKg <= 0) {
      _error = 'الوزن المدخل غير صالح.';
      _calculatedDose = null; // Clear previous dose on error
      notifyListeners();
      return;
    }

    // TODO: Implement actual calculation logic using drug data and weight
    // This might involve a specific UseCase or complex logic based on drug properties
    // For now, using a simple placeholder calculation.
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Simulate calculation delay
      await Future.delayed(const Duration(milliseconds: 500));

      // --- Placeholder Calculation Logic (Improved slightly) ---
      // This is still a placeholder and NOT medically accurate.
      // It needs to be replaced with actual dosage calculation logic based on medical data.
      double doseFactor = 10.0; // Default factor
      String unit = _selectedDrug!.unit.toLowerCase();
      String dosageForm = _selectedDrug!.dosageForm.toLowerCase();

      // Very basic attempt to adjust factor based on unit/form (highly simplified)
      if (unit.contains('mg') && !unit.contains('ml')) {
        doseFactor = 5.0; // Lower factor for mg?
      } else if (unit.contains('ml') ||
          dosageForm.contains('syrup') ||
          dosageForm.contains('susp')) {
        doseFactor = 15.0; // Higher factor for liquids?
      } else if (unit.contains('g')) {
        doseFactor = 0.5; // Lower factor for grams?
      }

      // Simple placeholder: weight * factor
      _calculatedDose = weightKg * doseFactor;
      print(
        'Placeholder Dose Calculated: $weightKg * $doseFactor = $_calculatedDose',
      );
      // --- End Placeholder ---

      _error = ''; // Clear error on success
    } catch (e) {
      print('Error during dose calculation: $e');
      _error = 'خطأ في حساب الجرعة.';
      _calculatedDose = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
