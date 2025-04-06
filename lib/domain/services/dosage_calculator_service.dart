import 'dart:math' as math;

import '../entities/dosage_result.dart';
import '../entities/drug_entity.dart'; // Assuming DrugEntity is in this path

/// Service responsible for calculating drug dosages.
class DosageCalculatorService {
  /// Calculates the appropriate dosage for a given medicine, weight, and age.
  ///
  /// Returns a [DosageResult] containing the calculated dosage string,
  /// optional warnings, and notes.
  DosageResult calculateDosage(DrugEntity medicine, double weight, int age) {
    // Input validation
    if (weight <= 0 || age < 0) {
      return DosageResult(
        dosage: "خطأ في المدخلات: يجب أن يكون الوزن موجباً والعمر غير سالب",
        warning: "يرجى إدخال قيم صحيحة للوزن والعمر",
      );
    }

    final String activeIngredientLower = medicine.active.toLowerCase();

    // Determine dosage based on active ingredient
    if (activeIngredientLower.contains("paracetamol") ||
        activeIngredientLower.contains("acetaminophen")) {
      return _calculateParacetamolDosage(medicine, weight, age);
    } else if (activeIngredientLower.contains("ibuprofen")) {
      return _calculateIbuprofenDosage(medicine, weight, age);
    } else if (activeIngredientLower.contains("amoxicillin")) {
      return _calculateAmoxicillinDosage(medicine, weight, age);
    }
    // TODO: Add calculation for pseudoephedrine if needed, based on External source
    // else if (activeIngredientLower.contains("pseudoephedrine")) {
    //   return _calculateColdMedicineDosage(medicine, weight, age);
    // }
    else {
      // For unsupported drugs
      return DosageResult(
        dosage: "يرجى استشارة الطبيب أو الصيدلاني لتحديد الجرعة المناسبة",
        warning: "لم يتم العثور على معادلة محددة لحساب جرعة هذا الدواء",
      );
    }
  }

  // --- Private Calculation Methods based on External Source ---

  DosageResult _calculateParacetamolDosage(
    DrugEntity medicine,
    double weight,
    int age,
  ) {
    // Dosage: 10-15 mg/kg every 4-6 hours, max 5 doses/day
    final double minDose = weight * 10;
    final double maxDose = weight * 15;
    String dosage = "";
    String? warning;
    String? notes;

    final String formLower = medicine.dosageForm.toLowerCase();

    if (formLower == "tablet" || formLower == "أقراص") {
      if (age >= 12) {
        dosage =
            "للبالغين والأطفال فوق 12 سنة: قرص واحد (${medicine.concentration.toStringAsFixed(0)} مجم) كل 4-6 ساعات حسب الحاجة، بحد أقصى 4 أقراص في اليوم.";
      } else if (age >= 6) {
        final double tabletDose = medicine.concentration;
        if (tabletDose <= 0) {
          return DosageResult(
            dosage: "خطأ: تركيز الدواء غير صحيح للأقراص.",
            warning: "يرجى مراجعة بيانات الدواء.",
          );
        }
        final double numTablets = minDose / tabletDose;
        dosage =
            "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${numTablets < 0.5 ? '1/2' : (numTablets < 1 ? '3/4' : '1')} قرص كل 4-6 ساعات حسب الحاجة، بحد أقصى 4 جرعات في اليوم.";
        notes =
            "الجرعة المحسوبة: ${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم كل 4-6 ساعات";
      } else {
        dosage =
            "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم كل 4-6 ساعات حسب الحاجة.";
        warning = "يفضل استخدام شراب الباراسيتامول للأطفال أقل من 6 سنوات.";
      }
    } else if (formLower == "syrup" || formLower == "شراب") {
      if (medicine.concentration <= 0) {
        return DosageResult(
          dosage: "خطأ: تركيز الدواء غير صحيح للشراب.",
          warning: "يرجى مراجعة بيانات الدواء.",
        );
      }
      final double minMl = (minDose / medicine.concentration);
      final double maxMl = (maxDose / medicine.concentration);
      // Simple rounding for display
      dosage =
          "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${_roundToNearestHalf(minMl).toStringAsFixed(1)}-${_roundToNearestHalf(maxMl).toStringAsFixed(1)} مل كل 4-6 ساعات حسب الحاجة، بحد أقصى 5 جرعات في اليوم.";
    } else {
      return DosageResult(
        dosage: "شكل الدواء غير مدعوم للحساب (${medicine.dosageForm}).",
      );
    }

    if (age < 2 && warning == null) {
      // Add warning if not already present
      warning =
          "تحذير: يجب استشارة الطبيب قبل إعطاء أي دواء للأطفال أقل من سنتين.";
    } else if (age < 2) {
      warning =
          (warning ?? "") +
          " يجب استشارة الطبيب قبل إعطاء أي دواء للأطفال أقل من سنتين.";
    }

    return DosageResult(dosage: dosage, warning: warning, notes: notes);
  }

  DosageResult _calculateIbuprofenDosage(
    DrugEntity medicine,
    double weight,
    int age,
  ) {
    // Dosage: 5-10 mg/kg every 6-8 hours, max 40 mg/kg/day
    final double minDose = weight * 5;
    final double maxDose = weight * 10;
    final double maxDailyDose = weight * 40;
    String dosage = "";
    String? warning;
    String? notes;

    final String formLower = medicine.dosageForm.toLowerCase();

    if (formLower == "tablet" || formLower == "أقراص") {
      if (age >= 12) {
        dosage =
            "للبالغين والأطفال فوق 12 سنة: قرص واحد (${medicine.concentration.toStringAsFixed(0)} مجم) كل 6-8 ساعات حسب الحاجة، بحد أقصى 3 أقراص في اليوم.";
      } else if (age >= 6) {
        final double tabletDose = medicine.concentration;
        if (tabletDose <= 0) {
          return DosageResult(
            dosage: "خطأ: تركيز الدواء غير صحيح للأقراص.",
            warning: "يرجى مراجعة بيانات الدواء.",
          );
        }
        final double numTablets = minDose / tabletDose;
        dosage =
            "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${numTablets < 0.5 ? '1/2' : (numTablets < 1 ? '3/4' : '1')} قرص كل 6-8 ساعات حسب الحاجة.";
        notes =
            "الجرعة المحسوبة: ${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم كل 6-8 ساعات، بحد أقصى ${maxDailyDose.toStringAsFixed(1)} مجم في اليوم";
      } else {
        dosage =
            "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم كل 6-8 ساعات حسب الحاجة.";
        warning = "يفضل استخدام شراب الإيبوبروفين للأطفال أقل من 6 سنوات.";
      }
    } else if (formLower == "syrup" || formLower == "شراب") {
      if (medicine.concentration <= 0) {
        return DosageResult(
          dosage: "خطأ: تركيز الدواء غير صحيح للشراب.",
          warning: "يرجى مراجعة بيانات الدواء.",
        );
      }
      final double minMl = (minDose / medicine.concentration);
      final double maxMl = (maxDose / medicine.concentration);
      dosage =
          "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${_roundToNearestHalf(minMl).toStringAsFixed(1)}-${_roundToNearestHalf(maxMl).toStringAsFixed(1)} مل كل 6-8 ساعات حسب الحاجة.";
      notes = "الحد الأقصى اليومي: ${maxDailyDose.toStringAsFixed(1)} مجم";
    } else {
      return DosageResult(
        dosage: "شكل الدواء غير مدعوم للحساب (${medicine.dosageForm}).",
      );
    }

    if (age < 6 && warning == null) {
      // Add warning if not already present
      warning =
          "تحذير: يجب استشارة الطبيب قبل إعطاء الإيبوبروفين للأطفال أقل من 6 سنوات.";
    } else if (age < 6) {
      warning =
          (warning ?? "") +
          " يجب استشارة الطبيب قبل إعطاء الإيبوبروفين للأطفال أقل من 6 سنوات.";
    }

    return DosageResult(dosage: dosage, warning: warning, notes: notes);
  }

  DosageResult _calculateAmoxicillinDosage(
    DrugEntity medicine,
    double weight,
    int age,
  ) {
    // Dosage: 20-40 mg/kg/day divided into 3 doses (using 25 mg/kg/day average)
    final double dailyDose = weight * 25; // Average daily dose
    final double singleDose = dailyDose / 3; // Dose per administration
    String dosage = "";
    String? warning;
    String? notes;

    final String formLower = medicine.dosageForm.toLowerCase();

    if (formLower == "capsule" || formLower == "كبسولة") {
      if (age >= 12) {
        dosage =
            "للبالغين والأطفال فوق 12 سنة: كبسولة واحدة (${medicine.concentration.toStringAsFixed(0)} مجم) 3 مرات يومياً لمدة 7-10 أيام.";
      } else {
        dosage =
            "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${singleDose.toStringAsFixed(1)} مجم 3 مرات يومياً لمدة 7-10 أيام.";
        warning = "يفضل استخدام شراب الأموكسيسيلين للأطفال أقل من 12 سنة.";
      }
    } else if (formLower == "syrup" || formLower == "شراب") {
      if (medicine.concentration <= 0) {
        return DosageResult(
          dosage: "خطأ: تركيز الدواء غير صحيح للشراب.",
          warning: "يرجى مراجعة بيانات الدواء.",
        );
      }
      final double doseInMl = (singleDose / medicine.concentration);
      dosage =
          "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${_roundToNearestHalf(doseInMl).toStringAsFixed(1)} مل 3 مرات يومياً لمدة 7-10 أيام.";
    } else {
      return DosageResult(
        dosage: "شكل الدواء غير مدعوم للحساب (${medicine.dosageForm}).",
      );
    }

    notes =
        "الجرعة اليومية الإجمالية: ${dailyDose.toStringAsFixed(1)} مجم مقسمة على 3 جرعات";

    return DosageResult(dosage: dosage, warning: warning, notes: notes);
  }

  // Helper function to round to nearest 0.5
  double _roundToNearestHalf(double value) {
    return (value * 2).round() / 2;
  }

  // TODO: Implement _calculateColdMedicineDosage if needed
  // DosageResult _calculateColdMedicineDosage(DrugEntity medicine, double weight, int age) { ... }
}
