import '../../data/models/dosage_guidelines_model.dart';
import '../entities/dosage_result.dart';
import '../entities/drug_entity.dart';

/// خدمة حساب الجرعات باستخدام بيانات قاعدة البيانات
class DosageCalculatorService {
  DosageCalculatorService();

  /// حساب الجرعة بناءً على بيانات dosage_guidelines
  DosageResult calculateDosageFromDB(
    DrugEntity medicine,
    double weight,
    int age, {
    int? durationDays,
    List<DosageGuidelinesModel>? guidelines,
  }) {
    if (weight <= 0 || age < 0) {
      return DosageResult(
        dosage: "خطأ: يجب أن يكون الوزن موجباً والعمر غير سالب",
        warning: "يرجى إدخال قيم صحيحة",
      );
    }

    final dosageGuidelines = guidelines ?? <DosageGuidelinesModel>[];

    if (dosageGuidelines.isEmpty) {
      return _fallbackCalculation(medicine, weight, age);
    }

    final guideline = _selectBestGuideline(dosageGuidelines, age);
    return _calculateFromGuideline(
      medicine,
      guideline,
      weight,
      age,
      durationDays: durationDays,
    );
  }

  DosageGuidelinesModel _selectBestGuideline(
    List<DosageGuidelinesModel> guidelines,
    int age,
  ) {
    if (age < 18) {
      final pediatric = guidelines.where((g) => g.isPediatric).toList();
      if (pediatric.isNotEmpty) return pediatric.first;
    }
    final adult = guidelines.where((g) => !g.isPediatric).toList();
    if (adult.isNotEmpty) return adult.first;
    return guidelines.first;
  }

  DosageResult _calculateFromGuideline(
    DrugEntity medicine,
    DosageGuidelinesModel guideline,
    double weight,
    int age, {
    int? durationDays,
  }) {
    final minDose = guideline.minDose ?? 0;
    final maxDose = guideline.maxDose;
    final frequency = guideline.frequency ?? 24;

    final bool isMgPerKg = minDose > 0 && minDose < 50;

    double singleDoseMg;
    if (isMgPerKg) {
      singleDoseMg = weight * minDose;
    } else {
      singleDoseMg = minDose;
    }

    String? volumeInfo;
    final concentration = medicine.concentration;
    if (concentration.isNotEmpty) {
      final parsed = _parseConcentration(concentration);
      if (parsed != null) {
        final ml = (singleDoseMg / parsed['mg']!) * parsed['ml']!;
        volumeInfo = '${ml.toStringAsFixed(1)} مل';
      }
    }

    final doseText =
        volumeInfo != null
            ? '${singleDoseMg.toStringAsFixed(1)} مجم ($volumeInfo)'
            : '${singleDoseMg.toStringAsFixed(1)} مجم';

    final frequencyText = _formatFrequency(frequency);

    String dosage = 'الجرعة: $doseText، $frequencyText';

    if (guideline.duration != null && guideline.duration! > 0) {
      dosage += '، لمدة ${guideline.duration} أيام';
    }

    String? warning;
    if (maxDose != null && singleDoseMg > maxDose) {
      warning = 'تحذير: الجرعة تتجاوز الحد الأقصى (${maxDose} مجم)';
    }

    String? notes;
    if (guideline.instructions != null && guideline.instructions!.isNotEmpty) {
      notes = guideline.instructions;
      if (guideline.source != null) {
        notes = '$notes\n\nالمصدر: ${guideline.source}';
      }
    } else if (guideline.source != null) {
      notes = 'المصدر: ${guideline.source}';
    }

    return DosageResult(
      dosage: dosage,
      warning: warning,
      notes: notes,
      intervalHours: frequency,
      mgPerKgUsed: isMgPerKg ? minDose : null,
      dailyCeiling: maxDose,
    );
  }

  Map<String, double>? _parseConcentration(String concentration) {
    final regex = RegExp(
      r'(\d+(?:\.\d+)?)\s*mg\s*/\s*(\d+(?:\.\d+)?)\s*ml',
      caseSensitive: false,
    );
    final match = regex.firstMatch(concentration);

    if (match != null) {
      final mg = double.tryParse(match.group(1)!);
      final ml = double.tryParse(match.group(2)!);
      if (mg != null && ml != null) {
        return {'mg': mg, 'ml': ml};
      }
    }
    return null;
  }

  String _formatFrequency(int hours) {
    if (hours == 24) return 'مرة يومياً';
    if (hours == 12) return 'مرتين يومياً';
    if (hours == 8) return '3 مرات يومياً';
    if (hours == 6) return '4 مرات يومياً';
    return 'كل $hours ساعة';
  }

  DosageResult _fallbackCalculation(
    DrugEntity medicine,
    double weight,
    int age,
  ) {
    final activeIngredient = medicine.active.toLowerCase();

    if (activeIngredient.contains('paracetamol') ||
        activeIngredient.contains('acetaminophen')) {
      final doseMg = weight * 15;
      return DosageResult(
        dosage: 'الجرعة: ${doseMg.toStringAsFixed(0)} مجم كل 6 ساعات',
        warning: 'جرعة تقريبية. يرجى استشارة الطبيب.',
        notes: 'باراسيتامول: 10-15 مجم/كجم',
      );
    }

    if (activeIngredient.contains('ibuprofen')) {
      final doseMg = weight * 10;
      return DosageResult(
        dosage: 'الجرعة: ${doseMg.toStringAsFixed(0)} مجم كل 8 ساعات',
        warning: 'جرعة تقريبية. يرجى استشارة الطبيب.',
        notes: 'ايبوبروفين: 5-10 مجم/كجم',
      );
    }

    return DosageResult(
      dosage: 'لا توجد بيانات جرعات محددة',
      warning: 'يرجى استشارة الطبيب أو الصيدلي',
      notes: 'هذا الدواء غير مدعوم',
    );
  }

  /// للتوافق مع الكود القديم
  DosageResult calculateDosage(
    DrugEntity medicine,
    double weight,
    int age, {
    int? durationDays,
  }) {
    return _fallbackCalculation(medicine, weight, age);
  }
}
