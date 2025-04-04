// lib/domain/services/dosage_calculator_service.dart

import '../entities/drug_entity.dart';
import '../entities/dosage_result.dart';

class DosageCalculatorService {
  DosageResult calculateDosage(DrugEntity medicine, double weight, int age) {
    final String activeIngredientLower = medicine.active.toLowerCase();

    // Dispatch based on active ingredient
    if (activeIngredientLower.contains('paracetamol') ||
        activeIngredientLower.contains('acetaminophen')) {
      return _calculateParacetamolDosage(medicine, weight, age);
    } else if (activeIngredientLower.contains('ibuprofen')) {
      return _calculateIbuprofenDosage(medicine, weight, age);
    } else if (activeIngredientLower.contains('amoxicillin')) {
      return _calculateAmoxicillinDosage(medicine, weight, age);
    }
    // TODO: Add more drug calculations here

    // Default result if drug is not supported
    return DosageResult(
      dosage: 'حساب الجرعة غير مدعوم لهذا الدواء حاليًا.',
      warning: 'يرجى استشارة الطبيب أو الصيدلي.',
    );
  }

  // --- Private Calculation Methods (Placeholders) ---

  DosageResult _calculateParacetamolDosage(
    DrugEntity medicine,
    double weight,
    int age,
  ) {
    // 1. حساب الجرعة الأساسية بناءً على الوزن
    final double minDose = weight * 10; // الحد الأدنى: 10 مجم/كجم
    final double maxDose = weight * 15; // الحد الأقصى: 15 مجم/كجم
    final double concentration =
        medicine.concentration; // Strength per tablet/capsule or mg/mL

    String dosage = '';
    String? notes;
    String? warning;

    // 2. تحديد الجرعة بناءً على شكل الدواء والعمر
    if (medicine.dosageForm.toLowerCase() == "tablet") {
      if (concentration <= 0) {
        return DosageResult(
          dosage: 'تركيز الدواء غير معروف للأقراص.',
          warning: 'يرجى مراجعة بيانات الدواء.',
        );
      }
      if (age >= 12) {
        // للبالغين والأطفال فوق 12 سنة
        dosage =
            "قرص واحد (${concentration.toStringAsFixed(0)} مجم) كل 4-6 ساعات حسب الحاجة";
        notes = "الحد الأقصى: 4 أقراص في اليوم";
      } else if (age >= 6) {
        // للأطفال بين 6-12 سنة
        final double numTabletsMin = minDose / concentration;
        // Determine practical fraction (e.g., 1/2, 3/4, 1) - simplified logic
        String tabletFraction = '';
        if (numTabletsMin < 0.3) {
          tabletFraction = '1/4'; // Assuming tablets can be quartered if needed
        } else if (numTabletsMin < 0.6) {
          tabletFraction = '1/2';
        } else if (numTabletsMin < 0.85) {
          tabletFraction = '3/4';
        } else {
          tabletFraction = '1';
        }
        dosage =
            "$tabletFraction قرص (${concentration.toStringAsFixed(0)} مجم) كل 4-6 ساعات";
        notes =
            "الجرعة المحسوبة: ${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم";
      } else {
        // للأطفال أقل من 6 سنوات
        dosage =
            "${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم كل 4-6 ساعات";
        warning = "يفضل استخدام شراب الباراسيتامول للأطفال أقل من 6 سنوات";
      }
    } else if (medicine.dosageForm.toLowerCase() == "syrup") {
      if (concentration <= 0) {
        return DosageResult(
          dosage: 'تركيز الدواء غير معروف للشراب.',
          warning: 'يرجى مراجعة بيانات الدواء.',
        );
      }
      // 3. حساب حجم الشراب بناءً على التركيز (مجم/مل)
      final double minMl = (minDose / concentration);
      final double maxMl = (maxDose / concentration);
      dosage =
          "${minMl.toStringAsFixed(1)}-${maxMl.toStringAsFixed(1)} مل كل 4-6 ساعات";
      notes = "الحد الأقصى: 5 جرعات في اليوم";
    } else {
      // Handle unsupported dosage forms
      return DosageResult(
        dosage:
            'حساب الجرعة غير مدعوم لهذا الشكل الصيدلاني (${medicine.dosageForm}).',
        warning: 'يرجى استشارة الطبيب أو الصيدلي.',
      );
    }

    // 4. إضافة تحذير عام للأطفال الصغار (يُدمج مع التحذير السابق إن وجد)
    if (age < 2) {
      final ageWarning =
          "تحذير: يجب استشارة الطبيب قبل إعطاء أي دواء للأطفال أقل من سنتين.";
      warning = warning != null ? '$warning\n$ageWarning' : ageWarning;
    }

    return DosageResult(dosage: dosage, notes: notes, warning: warning);
  }

  DosageResult _calculateIbuprofenDosage(
    DrugEntity medicine,
    double weight,
    int age,
  ) {
    // 1. حساب الجرعة الأساسية بناءً على الوزن
    final double minDose = weight * 5; // الحد الأدنى: 5 مجم/كجم
    final double maxDose = weight * 10; // الحد الأقصى: 10 مجم/كجم
    final double maxDailyDose =
        weight * 40; // الحد الأقصى اليومي: 40 مجم/كجم/يوم
    final double concentration = medicine.concentration;

    String dosage = '';
    String? notes;
    String? warning;

    // 2. تحديد الجرعة بناءً على شكل الدواء والعمر
    if (medicine.dosageForm.toLowerCase() == "tablet") {
      if (concentration <= 0) {
        return DosageResult(
          dosage: 'تركيز الدواء غير معروف للأقراص.',
          warning: 'يرجى مراجعة بيانات الدواء.',
        );
      }
      if (age >= 12) {
        // للبالغين والأطفال فوق 12 سنة
        dosage =
            "قرص واحد (${concentration.toStringAsFixed(0)} مجم) كل 6-8 ساعات حسب الحاجة";
        notes =
            "الحد الأقصى: 3 أقراص في اليوم"; // Assuming 400mg or 600mg tablets
      } else if (age >= 6) {
        // للأطفال بين 6-12 سنة
        final double numTabletsMin = minDose / concentration;
        // Determine practical fraction (e.g., 1/2, 3/4, 1) - simplified logic
        String tabletFraction = '';
        if (numTabletsMin < 0.3) {
          tabletFraction = '1/4';
        } else if (numTabletsMin < 0.6) {
          tabletFraction = '1/2';
        } else if (numTabletsMin < 0.85) {
          tabletFraction = '3/4';
        } else {
          tabletFraction = '1';
        }
        dosage =
            "$tabletFraction قرص (${concentration.toStringAsFixed(0)} مجم) كل 6-8 ساعات";
        notes =
            "الجرعة المحسوبة: ${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم";
      } else {
        // للأطفال أقل من 6 سنوات
        dosage =
            "${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم كل 6-8 ساعات";
        warning = "يفضل استخدام شراب الإيبوبروفين للأطفال أقل من 6 سنوات";
      }
    } else if (medicine.dosageForm.toLowerCase() == "syrup") {
      if (concentration <= 0) {
        return DosageResult(
          dosage: 'تركيز الدواء غير معروف للشراب.',
          warning: 'يرجى مراجعة بيانات الدواء.',
        );
      }
      // 3. حساب حجم الشراب بناءً على التركيز (مجم/مل)
      final double minMl = (minDose / concentration);
      final double maxMl = (maxDose / concentration);
      dosage =
          "${minMl.toStringAsFixed(1)}-${maxMl.toStringAsFixed(1)} مل كل 6-8 ساعات";
      notes = "الحد الأقصى اليومي: ${maxDailyDose.toStringAsFixed(1)} مجم";
    } else {
      // Handle unsupported dosage forms
      return DosageResult(
        dosage:
            'حساب الجرعة غير مدعوم لهذا الشكل الصيدلاني (${medicine.dosageForm}).',
        warning: 'يرجى استشارة الطبيب أو الصيدلي.',
      );
    }

    // 4. إضافة تحذير عام للأطفال الصغار (يُدمج مع التحذير السابق إن وجد)
    if (age < 6) {
      // Ibuprofen warning for < 6 years
      final ageWarning =
          "تحذير: يجب استشارة الطبيب قبل إعطاء الإيبوبروفين للأطفال أقل من 6 سنوات.";
      warning = warning != null ? '$warning\n$ageWarning' : ageWarning;
    }

    return DosageResult(dosage: dosage, notes: notes, warning: warning);
  }

  DosageResult _calculateAmoxicillinDosage(
    DrugEntity medicine,
    double weight,
    int age,
  ) {
    // 1. حساب الجرعة اليومية بناءً على الوزن (متوسط 25 مجم/كجم/يوم، يمكن أن يصل إلى 40 أو 90 حسب الحالة)
    // Using average dose for general calculation as per external source example
    final double dailyDose = weight * 25;
    final double singleDose = dailyDose / 3; // الجرعة الواحدة (3 مرات يومياً)
    final double concentration = medicine.concentration;

    String dosage = '';
    String? notes;
    String? warning;

    // 2. تحديد الجرعة بناءً على شكل الدواء والعمر
    final String dosageFormLower = medicine.dosageForm.toLowerCase();
    if (dosageFormLower == "capsule" || dosageFormLower == "tablet") {
      if (concentration <= 0) {
        return DosageResult(
          dosage: 'تركيز الدواء غير معروف للكبسولات/الأقراص.',
          warning: 'يرجى مراجعة بيانات الدواء.',
        );
      }
      if (age >= 12) {
        // للبالغين والأطفال فوق 12 سنة (عادة جرعة ثابتة مثل 500 مجم)
        // Assuming standard adult dose if concentration matches common strengths (e.g., 250, 500)
        if (concentration == 250 ||
            concentration == 500 ||
            concentration == 875 ||
            concentration == 1000) {
          dosage =
              "كبسولة/قرص واحد (${concentration.toStringAsFixed(0)} مجم) 3 مرات يومياً";
        } else {
          // If concentration is unusual, calculate based on weight
          dosage = "${singleDose.toStringAsFixed(1)} مجم 3 مرات يومياً";
        }
        notes = "مدة العلاج المعتادة: 7-10 أيام (حسب توجيهات الطبيب)";
      } else {
        // للأطفال أقل من 12 سنة
        dosage = "${singleDose.toStringAsFixed(1)} مجم 3 مرات يومياً";
        warning =
            "يفضل استخدام شراب الأموكسيسيلين للأطفال أقل من 12 سنة أو حسب وزنهم.";
        notes = "مدة العلاج المعتادة: 7-10 أيام (حسب توجيهات الطبيب)";
      }
    } else if (dosageFormLower == "syrup" || dosageFormLower == "suspension") {
      if (concentration <= 0) {
        return DosageResult(
          dosage: 'تركيز الدواء غير معروف للشراب/المعلق.',
          warning: 'يرجى مراجعة بيانات الدواء.',
        );
      }
      // 3. حساب حجم الشراب بناءً على التركيز (مجم/مل)
      final double doseInMl = (singleDose / concentration);
      dosage = "${doseInMl.toStringAsFixed(1)} مل 3 مرات يومياً";
      notes =
          "الجرعة اليومية الإجمالية: ${dailyDose.toStringAsFixed(1)} مجم، مدة العلاج: 7-10 أيام (حسب توجيهات الطبيب)";
    } else {
      // Handle unsupported dosage forms
      return DosageResult(
        dosage:
            'حساب الجرعة غير مدعوم لهذا الشكل الصيدلاني (${medicine.dosageForm}).',
        warning: 'يرجى استشارة الطبيب أو الصيدلي.',
      );
    }

    // No specific age warning mentioned for Amoxicillin in the source, but good practice to consult doctor for young children.

    return DosageResult(dosage: dosage, notes: notes, warning: warning);
  }
}
