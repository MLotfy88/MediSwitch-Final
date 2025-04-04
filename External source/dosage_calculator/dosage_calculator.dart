// حاسبة الجرعات الدوائية بناءً على الوزن والعمر

import 'dart:math' as math;

// تعريف فئة الدواء
class Medicine {
  final String tradeName;
  final String arabicName;
  final String activeIngredient;
  final String dosageForm;
  final String dosageFormAr;
  final double concentration; // تركيز المادة الفعالة (مجم/مل للسوائل أو مجم/قرص للأقراص)

  Medicine({
    required this.tradeName,
    required this.arabicName,
    required this.activeIngredient,
    required this.dosageForm,
    required this.dosageFormAr,
    required this.concentration,
  });
}

// تعريف فئة نتيجة حساب الجرعة
class DosageResult {
  final String dosage;
  final String? warning;
  final String? notes;

  DosageResult({
    required this.dosage,
    this.warning,
    this.notes,
  });
}

// فئة حاسبة الجرعات
class DosageCalculator {
  // حساب الجرعة بناءً على الوزن والعمر والدواء
  static DosageResult calculateDosage(Medicine medicine, double weight, int age) {
    // التحقق من صحة المدخلات
    if (weight <= 0 || age < 0) {
      return DosageResult(
        dosage: "خطأ في المدخلات: يجب أن يكون الوزن موجباً والعمر غير سالب",
        warning: "يرجى إدخال قيم صحيحة للوزن والعمر",
      );
    }

    // تحديد الجرعة بناءً على المادة الفعالة
    if (medicine.activeIngredient.contains("paracetamol") ||
        medicine.activeIngredient.contains("acetaminophen")) {
      return _calculateParacetamolDosage(medicine, weight, age);
    } else if (medicine.activeIngredient.contains("ibuprofen")) {
      return _calculateIbuprofenDosage(medicine, weight, age);
    } else if (medicine.activeIngredient.contains("amoxicillin")) {
      return _calculateAmoxicillinDosage(medicine, weight, age);
    } else if (medicine.activeIngredient.contains("pseudoephedrine")) {
      return _calculateColdMedicineDosage(medicine, weight, age);
    } else {
      // للأدوية الأخرى التي لا تتوفر لها معادلات محددة
      return DosageResult(
        dosage: "يرجى استشارة الطبيب أو الصيدلي لتحديد الجرعة المناسبة",
        warning: "لم يتم العثور على معادلة محددة لحساب جرعة هذا الدواء",
      );
    }
  }

  // حساب جرعة الباراسيتامول (أسيتامينوفين)
  static DosageResult _calculateParacetamolDosage(Medicine medicine, double weight, int age) {
    // جرعة الباراسيتامول: 10-15 مجم/كجم كل 4-6 ساعات، بحد أقصى 5 جرعات في اليوم
    final double minDose = weight * 10;
    final double maxDose = weight * 15;
    String dosage = "";
    String? warning;
    String? notes;

    // تحديد الجرعة بناءً على شكل الدواء والعمر
    if (medicine.dosageForm == "tablet" || medicine.dosageForm == "أقراص") {
      if (age >= 12) {
        // للبالغين والأطفال فوق 12 سنة
        dosage = "للبالغين والأطفال فوق 12 سنة: قرص واحد (${medicine.concentration} مجم) كل 4-6 ساعات حسب الحاجة، بحد أقصى 4 أقراص في اليوم.";
      } else if (age >= 6) {
        // للأطفال بين 6-12 سنة
        final double tabletDose = medicine.concentration;
        final double numTablets = minDose / tabletDose;
        dosage = "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${numTablets < 0.5 ? '1/2' : (numTablets < 1 ? '3/4' : '1')} قرص كل 4-6 ساعات حسب الحاجة، بحد أقصى 4 جرعات في اليوم.";
        notes = "الجرعة المحسوبة: ${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم كل 4-6 ساعات";
      } else {
        // للأطفال أقل من 6 سنوات
        dosage = "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم كل 4-6 ساعات حسب الحاجة.";
        warning = "يفضل استخدام شراب الباراسيتامول للأطفال أقل من 6 سنوات.";
      }
    } else if (medicine.dosageForm == "syrup" || medicine.dosageForm == "شراب") {
      // حساب حجم الشراب بناءً على التركيز (مجم/مل)
      final double minMl = (minDose / medicine.concentration);
      final double maxMl = (maxDose / medicine.concentration);
      dosage = "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${minMl.toStringAsFixed(1)}-${maxMl.toStringAsFixed(1)} مل كل 4-6 ساعات حسب الحاجة، بحد أقصى 5 جرعات في اليوم.";
    }

    // إضافة تحذير للأطفال الصغار
    if (age < 2) {
      warning = "تحذير: يجب استشارة الطبيب قبل إعطاء أي دواء للأطفال أقل من سنتين.";
    }

    return DosageResult(
      dosage: dosage,
      warning: warning,
      notes: notes,
    );
  }

  // حساب جرعة الإيبوبروفين
  static DosageResult _calculateIbuprofenDosage(Medicine medicine, double weight, int age) {
    // جرعة الإيبوبروفين: 5-10 مجم/كجم كل 6-8 ساعات، بحد أقصى 40 مجم/كجم/يوم
    final double minDose = weight * 5;
    final double maxDose = weight * 10;
    final double maxDailyDose = weight * 40;
    String dosage = "";
    String? warning;
    String? notes;

    // تحديد الجرعة بناءً على شكل الدواء والعمر
    if (medicine.dosageForm == "tablet" || medicine.dosageForm == "أقراص") {
      if (age >= 12) {
        // للبالغين والأطفال فوق 12 سنة
        dosage = "للبالغين والأطفال فوق 12 سنة: قرص واحد (${medicine.concentration} مجم) كل 6-8 ساعات حسب الحاجة، بحد أقصى 3 أقراص في اليوم.";
      } else if (age >= 6) {
        // للأطفال بين 6-12 سنة
        final double tabletDose = medicine.concentration;
        final double numTablets = minDose / tabletDose;
        dosage = "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${numTablets < 0.5 ? '1/2' : (numTablets < 1 ? '3/4' : '1')} قرص كل 6-8 ساعات حسب الحاجة.";
        notes = "الجرعة المحسوبة: ${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم كل 6-8 ساعات، بحد أقصى ${maxDailyDose.toStringAsFixed(1)} مجم في اليوم";
      } else {
        // للأطفال أقل من 6 سنوات
        dosage = "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم كل 6-8 ساعات حسب الحاجة.";
        warning = "يفضل استخدام شراب الإيبوبروفين للأطفال أقل من 6 سنوات.";
      }
    } else if (medicine.dosageForm == "syrup" || medicine.dosageForm == "شراب") {
      // حساب حجم الشراب بناءً على التركيز (مجم/مل)
      final double minMl = (minDose / medicine.concentration);
      final double maxMl = (maxDose / medicine.concentration);
      dosage = "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${minMl.toStringAsFixed(1)}-${maxMl.toStringAsFixed(1)} مل كل 6-8 ساعات حسب الحاجة.";
    }

    // إضافة تحذير للأطفال الصغار
    if (age < 6) {
      warning = "تحذير: يجب استشارة الطبيب قبل إعطاء الإيبوبروفين للأطفال أقل من 6 سنوات.";
    }

    return DosageResult(
      dosage: dosage,
      warning: warning,
      notes: notes,
    );
  }

  // حساب جرعة الأموكسيسيلين (مضاد حيوي)
  static DosageResult _calculateAmoxicillinDosage(Medicine medicine, double weight, int age) {
    // جرعة الأموكسيسيلين: 20-40 مجم/كجم/يوم مقسمة على 3 جرعات
    final double dailyDose = weight * 25; // متوسط الجرعة اليومية
    final double singleDose = dailyDose / 3; // الجرعة الواحدة (3 مرات يومياً)
    String dosage = "";
    String? warning;
    String? notes;

    // تحديد الجرعة بناءً على شكل الدواء والعمر
    if (medicine.dosageForm == "capsule" || medicine.dosageForm == "كبسولة") {
      if (age >= 12) {
        // للبالغين والأطفال فوق 12 سنة
        dosage = "للبالغين والأطفال فوق 12 سنة: كبسولة واحدة (${medicine.concentration} مجم) 3 مرات يومياً لمدة 7-10 أيام.";
      } else {
        // للأطفال أقل من 12 سنة
        dosage = "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${singleDose.toStringAsFixed(1)} مجم 3 مرات يومياً لمدة 7-10 أيام.";
        warning = "يفضل استخدام شراب الأموكسيسيلين للأطفال أقل من 12 سنة.";
      }
    } else if (medicine.dosageForm == "syrup" || medicine.dosageForm == "شراب") {
      // حساب حجم الشراب بناءً على التركيز (مجم/مل)
      final double doseInMl = (singleDose / medicine.concentration);
      dosage = "للأطفال ${age} سنوات (${weight.toStringAsFixed(1)} كجم): ${doseInMl.toStringAsFixed(1)} مل 3 مرات يومياً لمدة 7-10 أيام.";
    }

    // إضافة ملاحظة عن الجرعة اليومية
    notes = "الجرعة اليومية الإجمالية: ${dailyDose.toStringAsFixed(1)} مجم مقسمة على 3 جرعات";

    return DosageResult(
      dosage: dosage,
      warning: warning,
      notes: notes,
    );
  }

  // حساب جرعة أدوية البرد (التي تحتوي على سودوإيفيدرين)
  static DosageResult _calculateColdMedicineDosage(Medicine medicine, double weight, int age) {
    String dosage = "";
    String? warning;
    String? notes;

    // تحديد الجرعة بناءً على العمر
    if (medicine.dosageForm == "tablet" || medicine.dosageForm == "أقراص") {
      if (age >= 12) {
        // للبالغين والأطفال فوق 12 سنة
        dosage = "للبالغين والأطفال فوق 12 سنة: قرص واحد كل 6-8 ساعات حسب الحاجة، بحد أقصى 3 أقراص في اليوم.";
      } else if (age >= 6) {
        // للأطفال بين 6-12 سنة
        dosage = "للأطفال ${age} سنوات: نصف قرص كل 6-8 ساعات حسب الحاجة، بحد أقصى 3 جرعات في اليوم.";
      } else {
        // للأطفال أقل من 6 سنوات
        dosage = "غير مناسب للأطفال أقل من 6 سنوات.";
        warning = "لا ينصح باستخدام أدوية البرد التي تحتوي على سودوإيفيدرين للأطفال أقل من 6 سنوات.";
      }
    } else if (medicine.dosageForm == "syrup" || medicine.dosageForm == "شراب") {
      if (age >= 12) {
        // للبالغين والأطفال فوق 12 سنة
        dosage = "للبالغين والأطفال فوق 12 سنة: 10 مل كل 6-8 ساعات حسب الحاجة، بحد أقصى 3 جرعات في اليوم.";
      } else if (age >= 6 && age < 12) {
        // للأطفال بين 6-12 سنة
        dosage = "للأطفال ${age} سنوات: 5 مل كل 6-8 ساعات حسب الحاجة، بحد أقصى 3 جرعات في اليوم.";
      } else if (age >= 2 && age < 6) {
        // للأطفال بين 2-6 سنوات
        dosage = "للأطفال ${age} سنوات: 2.5 مل كل 6-8 ساعات حسب الحاجة، بحد أقصى 3 جرعات في اليوم.";
        warning = "يجب استشارة الطبيب قبل إعطاء أدوية البرد للأطفال أقل من 6 سنوات.";
      } else {
        // للأطفال أقل من سنتين
        dosage = "غير مناسب للأطفال أقل من سنتين.";
        warning = "لا ينصح باستخدام أدوية البرد التي تحتوي على سودوإيفيدرين للأطفال أقل من سنتين.";
      }
    }

    return DosageResult(
      dosage: dosage,
      warning: warning,
      notes: notes,
    );
  }

  // حساب الجرعة باستخدام معادلة Young للأطفال
  // تستخدم هذه المعادلة لتقدير جرعة الطفل بناءً على جرعة البالغ
  // الجرعة = (عمر الطفل / (عمر الطفل + 12)) × جرعة البالغ
  static double calculateYoungFormula(int childAge, double adultDose) {
    if (childAge <= 0) return 0;
    return (childAge / (childAge + 12)) * adultDose;
  }

  // حساب الجرعة باستخدام معادلة Clark للأطفال
  // تستخدم هذه المعادلة لتقدير جرعة الطفل بناءً على وزن الطفل وجرعة البالغ
  // الجرعة = (وزن الطفل بالكيلوجرام / 70) × جرعة البالغ
  static double calculateClarkFormula(double childWeight, double adultDose) {
    if (childWeight <= 0) return 0;
    return (childWeight / 70) * adultDose;
  }

  // حساب الجرعة باستخدام مساحة سطح الجسم (BSA)
  // تستخدم هذه المعادلة لتقدير جرعة الطفل بناءً على مساحة سطح الجسم
  // الجرعة = (مساحة سطح جسم الطفل / 1.73) × جرعة البالغ
  static double calculateBSAFormula(double childWeight, double childHeight, double adultDose) {
    if (childWeight <= 0 || childHeight <= 0) return 0;
    // حساب مساحة سطح الجسم باستخدام معادلة Mosteller
    double bsa = sqrt((childHeight * childWeight) / 3600);
    return (bsa / 1.73) * adultDose;
  }
}

// دالة مساعدة لحساب الجذر التربيعي
double sqrt(double value) {
  // تصحيح دالة الجذر التربيعي لتعمل بشكل صحيح
  return math.sqrt(value);
}