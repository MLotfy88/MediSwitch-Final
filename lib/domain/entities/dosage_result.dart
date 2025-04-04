// lib/domain/entities/dosage_result.dart

class DosageResult {
  final String dosage; // الجرعة المحسوبة
  final String? warning; // تحذيرات (إن وجدت)
  final String? notes; // ملاحظات إضافية

  DosageResult({required this.dosage, this.warning, this.notes});

  // Optional: Add factory constructor or other methods if needed later
}
