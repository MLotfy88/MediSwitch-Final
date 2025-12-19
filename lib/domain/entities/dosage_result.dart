/// Represents the result of a dosage calculation.
class DosageResult {
  /// The calculated dosage description (e.g., "5-10 ml every 6 hours").
  final String dosage;

  /// Optional warning message associated with the dosage.
  final String? warning;

  /// Optional additional notes regarding the dosage.
  final String? notes;

  /// Optional maximum dose information.
  final String? maxDose;

  /// The number of hours between doses (e.g., 8).
  final int? intervalHours;

  /// The clinical factor used for calculation in mg/kg (e.g., 15.0).
  final double? mgPerKgUsed;

  /// Calculated total quantity needed for the whole course (e.g., 30 tabs).
  final String? totalQuantity;

  /// The absolute maximum limit for 24 hours in mg.
  final double? dailyCeiling;

  /// Creates a new instance of [DosageResult].
  const DosageResult({
    required this.dosage,
    this.warning,
    this.notes,
    this.maxDose,
    this.intervalHours,
    this.mgPerKgUsed,
    this.totalQuantity,
    this.dailyCeiling,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DosageResult &&
        other.dosage == dosage &&
        other.warning == warning &&
        other.notes == notes &&
        other.maxDose == maxDose &&
        other.intervalHours == intervalHours &&
        other.mgPerKgUsed == mgPerKgUsed &&
        other.totalQuantity == totalQuantity &&
        other.dailyCeiling == dailyCeiling;
  }

  @override
  int get hashCode =>
      dosage.hashCode ^
      warning.hashCode ^
      notes.hashCode ^
      maxDose.hashCode ^
      intervalHours.hashCode ^
      mgPerKgUsed.hashCode ^
      totalQuantity.hashCode ^
      dailyCeiling.hashCode;

  @override
  String toString() =>
      'DosageResult(dosage: $dosage, warning: $warning, notes: $notes, maxDose: $maxDose, intervalHours: $intervalHours, mgPerKgUsed: $mgPerKgUsed, totalQuantity: $totalQuantity, dailyCeiling: $dailyCeiling)';
}
