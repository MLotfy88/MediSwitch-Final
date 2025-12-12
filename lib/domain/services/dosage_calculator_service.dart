import '../entities/dosage_result.dart';
import '../entities/drug_entity.dart'; // Assuming DrugEntity is in this path

/// Dosage Calculator Service for computing recommended dosages
class DosageCalculatorService {
  // Helper to extract numeric value from concentration string
  // Examples: "50 mg" → 50.0, "40gm/ml" → 40.0, "100" → 100.0
  static double _parseConcentrationValue(String concentrationStr) {
    if (concentrationStr.isEmpty) return 0.0;

    // Extract first number from the string
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(concentrationStr);
    if (match != null) {
      return double.tryParse(match.group(0)!) ?? 0.0;
    }
    return 0.0;
  }

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

  // Helper class to hold parsed concentration
  _Concentration? _parseSyrupConcentration(
    String tradeName,
    double defaultStrength,
  ) {
    // Regex to find patterns like "120mg/5ml", "250 mg / 5 ml", "100mg/ml"
    // Group 1: Strength (e.g., 120)
    // Group 3: Volume (e.g., 5), optional
    final RegExp regex = RegExp(
      r'(\d+(?:\.\d+)?)\s*mg\s*/\s*(\d+(?:\.\d+)?)?\s*ml',
      caseSensitive: false,
    );
    final match = regex.firstMatch(tradeName);

    if (match != null) {
      final double strength =
          double.tryParse(match.group(1) ?? '') ?? defaultStrength;
      final double volume =
          double.tryParse(match.group(2) ?? '1') ??
          1.0; // Default to 1ml if not specified
      return _Concentration(strength: strength, volume: volume);
    }

    // Fallback: Try to find just "X mg" if it's a tablet/capsule or if the previous regex failed
    // This might be risky for syrups if they don't specify volume, but usually syrups have /5ml or /ml
    // If we only find "120 mg" in a syrup, it's ambiguous.
    // However, if we have the `defaultStrength` from the DB column, we can use that as strength and assume 1ml or 5ml?
    // Better to rely on the DB column if regex fails, but treating it as mg/1ml or mg/5ml is the issue.

    if (defaultStrength > 0) {
      // If regex failed but we have a DB value.
      // Most DB values for syrups in the provided CSV seemed to be just the strength number (e.g. 15 for 15mg/ml, or 250 for 250mg/5ml?? No, CSV showed 5mg/5ml had concentration 5? No, let's check CSV again.
      // CSV: alerid 5mg/5ml -> concentration column was empty in some, or 5 in others?
      // Let's assume if DB has a value, it is the Strength in mg.
      // But we don't know the volume.
      // If it's a syrup, standard is often 5ml, but drops are 1ml.
      // We will return null to indicate failure to parse strict pattern,
      // and let the caller decide or use a default.
      return _Concentration(
        strength: defaultStrength,
        volume: 1.0,
      ); // Fallback to 1ml if only strength is known?
    }

    return null;
  }

  DosageResult _calculateParacetamolDosage(
    DrugEntity medicine,
    double weight,
    int age,
  ) {
    // Dosage: 10-15 mg/kg every 4-6 hours, max 5 doses/day
    final double minDoseMg = weight * 10;
    final double maxDoseMg = weight * 15;
    String dosage = "";
    String? warning;
    String? notes;

    final String formLower = medicine.dosageForm.toLowerCase();

    if (formLower.contains("tablet") ||
        formLower.contains("tab") ||
        formLower.contains("أقراص") ||
        formLower.contains("قرص")) {
      if (age >= 12) {
        final double concentration =
            DosageCalculatorService._parseConcentrationValue(
              medicine.concentration,
            );
        dosage =
            "للبالغين والأطفال فوق 12 سنة: قرص واحد (${concentration.toStringAsFixed(0)} مجم) كل 4-6 ساعات حسب الحاجة، بحد أقصى 4 أقراص في اليوم.";
      } else if (age >= 6) {
        final double tabletStrength =
            DosageCalculatorService._parseConcentrationValue(
              medicine.concentration,
            );
        if (tabletStrength <= 0) {
          return DosageResult(
            dosage: "خطأ: تركيز الدواء غير صحيح للأقراص.",
            warning: "يرجى مراجعة بيانات الدواء.",
          );
        }
        final double numTablets = minDoseMg / tabletStrength;
        dosage =
            "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${numTablets < 0.5 ? '1/2' : (numTablets < 1 ? '3/4' : '1')} قرص كل 4-6 ساعات حسب الحاجة، بحد أقصى 4 جرعات في اليوم.";
        notes =
            "الجرعة المحسوبة: ${minDoseMg.toStringAsFixed(1)}-${maxDoseMg.toStringAsFixed(1)} مجم كل 4-6 ساعات";
      } else {
        dosage =
            "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${minDoseMg.toStringAsFixed(1)}-${maxDoseMg.toStringAsFixed(1)} مجم كل 4-6 ساعات حسب الحاجة.";
        warning = "يفضل استخدام شراب الباراسيتامول للأطفال أقل من 6 سنوات.";
      }
    } else if (formLower.contains("syrup") ||
        formLower.contains("susp") ||
        formLower.contains("شراب") ||
        formLower.contains("معلق")) {
      final parsed = _parseSyrupConcentration(
        medicine.tradeName,
        _parseConcentrationValue(medicine.concentration),
      );

      if (parsed == null || parsed.strength <= 0) {
        return DosageResult(
          dosage: "تعذر تحديد تركيز الدواء من الاسم (${medicine.tradeName}).",
          warning:
              "يرجى التأكد من أن اسم الدواء يحتوي على التركيز (مثلاً 120mg/5ml).",
        );
      }

      // Calculate Volume in ml: (TargetDoseMg * UnitVolumeMl) / StrengthMg
      final double minMl = (minDoseMg * parsed.volume) / parsed.strength;
      final double maxMl = (maxDoseMg * parsed.volume) / parsed.strength;

      dosage =
          "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${_roundToNearestHalf(minMl).toStringAsFixed(1)}-${_roundToNearestHalf(maxMl).toStringAsFixed(1)} مل كل 4-6 ساعات حسب الحاجة، بحد أقصى 5 جرعات في اليوم.";

      notes =
          "التركيز المستخدم: ${parsed.strength.toStringAsFixed(0)}مجم / ${parsed.volume.toStringAsFixed(0)}مل";
    } else if (formLower.contains("drop") || formLower.contains("نقط")) {
      // Drops logic (usually 100mg/ml)
      final parsed = _parseSyrupConcentration(
        medicine.tradeName,
        _parseConcentrationValue(medicine.concentration),
      );
      if (parsed == null || parsed.strength <= 0) {
        return DosageResult(dosage: "تعذر تحديد تركيز النقط.");
      }
      // Drops are usually calculated in ml then converted to drops (approx 20 drops = 1ml, but varies)
      // Let's stick to ml for accuracy or check if user wants drops count.
      final double minMl = (minDoseMg * parsed.volume) / parsed.strength;
      final double maxMl = (maxDoseMg * parsed.volume) / parsed.strength;

      dosage =
          "للأطفال ${age} سنوات: ${_roundToNearestHalf(minMl).toStringAsFixed(1)}-${_roundToNearestHalf(maxMl).toStringAsFixed(1)} مل (${(minMl * 20).toStringAsFixed(0)}-${(maxMl * 20).toStringAsFixed(0)} نقطة تقريباً) كل 4-6 ساعات.";
    } else {
      return DosageResult(
        dosage: "شكل الدواء غير مدعوم للحساب (${medicine.dosageForm}).",
      );
    }

    if (age < 2 && warning == null) {
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
    final double minDoseMg = weight * 5;
    final double maxDoseMg = weight * 10;
    final double maxDailyDoseMg = weight * 40;
    String dosage = "";
    String? warning;
    String? notes;

    final String formLower = medicine.dosageForm.toLowerCase();

    if (formLower.contains("tablet") ||
        formLower.contains("tab") ||
        formLower.contains("أقراص") ||
        formLower.contains("قرص")) {
      if (age >= 12) {
        final double concentration = _parseConcentrationValue(
          medicine.concentration,
        );
        dosage =
            "للبالغين والأطفال فوق 12 سنة: قرص واحد (${concentration.toStringAsFixed(0)} مجم) كل 6-8 ساعات حسب الحاجة، بحد أقصى 3 أقراص في اليوم.";
      } else if (age >= 6) {
        final double tabletStrength = _parseConcentrationValue(
          medicine.concentration,
        );
        if (tabletStrength <= 0) {
          return DosageResult(
            dosage: "خطأ: تركيز الدواء غير صحيح للأقراص.",
            warning: "يرجى مراجعة بيانات الدواء.",
          );
        }
        final double numTablets = minDoseMg / tabletStrength;
        dosage =
            "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${numTablets < 0.5 ? '1/2' : (numTablets < 1 ? '3/4' : '1')} قرص كل 6-8 ساعات حسب الحاجة.";
        notes =
            "الجرعة المحسوبة: ${minDoseMg.toStringAsFixed(1)}-${maxDoseMg.toStringAsFixed(1)} مجم كل 6-8 ساعات";
      } else {
        dosage =
            "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${minDoseMg.toStringAsFixed(1)}-${maxDoseMg.toStringAsFixed(1)} مجم كل 6-8 ساعات حسب الحاجة.";
        warning = "يفضل استخدام شراب الإيبوبروفين للأطفال أقل من 6 سنوات.";
      }
    } else if (formLower.contains("syrup") ||
        formLower.contains("susp") ||
        formLower.contains("شراب") ||
        formLower.contains("معلق")) {
      final parsed = _parseSyrupConcentration(
        medicine.tradeName,
        _parseConcentrationValue(medicine.concentration),
      );

      if (parsed == null || parsed.strength <= 0) {
        return DosageResult(
          dosage: "تعذر تحديد تركيز الدواء من الاسم (${medicine.tradeName}).",
          warning:
              "يرجى التأكد من أن اسم الدواء يحتوي على التركيز (مثلاً 100mg/5ml).",
        );
      }

      final double minMl = (minDoseMg * parsed.volume) / parsed.strength;
      final double maxMl = (maxDoseMg * parsed.volume) / parsed.strength;

      dosage =
          "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${_roundToNearestHalf(minMl).toStringAsFixed(1)}-${_roundToNearestHalf(maxMl).toStringAsFixed(1)} مل كل 6-8 ساعات حسب الحاجة.";
      notes =
          "التركيز المستخدم: ${parsed.strength.toStringAsFixed(0)}مجم / ${parsed.volume.toStringAsFixed(0)}مل\nالحد الأقصى اليومي: ${maxDailyDoseMg.toStringAsFixed(1)} مجم";
    } else {
      return DosageResult(
        dosage: "شكل الدواء غير مدعوم للحساب (${medicine.dosageForm}).",
      );
    }

    if (age < 6 && warning == null) {
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
    // Dosage: 20-40 mg/kg/day divided into 3 doses (using 25 mg/kg/day average for mild/moderate)
    // Or 45mg/kg/day divided into 2 doses for higher concentration?
    // Let's stick to standard 3 doses for now: 25-30 mg/kg/day.
    final double dailyDoseMg =
        weight * 30; // Using 30mg/kg/day as a safe effective average
    final double singleDoseMg =
        dailyDoseMg / 3; // Dose per administration (every 8h)
    String dosage = "";
    String? warning;
    String? notes;

    final String formLower = medicine.dosageForm.toLowerCase();

    if (formLower.contains("capsule") ||
        formLower.contains("tab") ||
        formLower.contains("كبسولة") ||
        formLower.contains("قرص")) {
      if (age >= 12) {
        final double concentration = _parseConcentrationValue(
          medicine.concentration,
        );
        dosage =
            "للبالغين والأطفال فوق 12 سنة: كبسولة واحدة (${concentration.toStringAsFixed(0)} مجم) 3 مرات يومياً لمدة 7-10 أيام.";
      } else {
        dosage =
            "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${singleDoseMg.toStringAsFixed(1)} مجم 3 مرات يومياً لمدة 7-10 أيام.";
        warning = "يفضل استخدام شراب الأموكسيسيلين للأطفال أقل من 12 سنة.";
      }
    } else if (formLower.contains("syrup") ||
        formLower.contains("susp") ||
        formLower.contains("شراب") ||
        formLower.contains("معلق")) {
      final parsed = _parseSyrupConcentration(
        medicine.tradeName,
        _parseConcentrationValue(medicine.concentration),
      );

      if (parsed == null || parsed.strength <= 0) {
        return DosageResult(
          dosage: "تعذر تحديد تركيز الدواء من الاسم (${medicine.tradeName}).",
          warning:
              "يرجى التأكد من أن اسم الدواء يحتوي على التركيز (مثلاً 250mg/5ml).",
        );
      }

      final double doseInMl = (singleDoseMg * parsed.volume) / parsed.strength;

      dosage =
          "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${_roundToNearestHalf(doseInMl).toStringAsFixed(1)} مل 3 مرات يومياً (كل 8 ساعات) لمدة 7-10 أيام.";

      notes =
          "التركيز المستخدم: ${parsed.strength.toStringAsFixed(0)}مجم / ${parsed.volume.toStringAsFixed(0)}مل\nالجرعة اليومية الإجمالية: ${dailyDoseMg.toStringAsFixed(1)} مجم";
    } else {
      return DosageResult(
        dosage: "شكل الدواء غير مدعوم للحساب (${medicine.dosageForm}).",
      );
    }

    return DosageResult(dosage: dosage, warning: warning, notes: notes);
  }

  // Helper function to round to nearest 0.5
  double _roundToNearestHalf(double value) {
    return (value * 2).round() / 2;
  }

  // TODO: Implement _calculateColdMedicineDosage if needed
  // DosageResult _calculateColdMedicineDosage(DrugEntity medicine, double weight, int age) { ... }
}

class _Concentration {
  final double strength;
  final double volume;

  _Concentration({required this.strength, required this.volume});
}
