/// Represents the result of a dosage calculation.
class DosageResult {
  /// The calculated dosage description (e.g., "5-10 ml every 6 hours").
  final String dosage;

  /// Optional warning message associated with the dosage.
  final String? warning;

  /// Optional additional notes regarding the dosage.
  final String? notes;

  /// Creates a new instance of [DosageResult].
  DosageResult({required this.dosage, this.warning, this.notes});

  // Optional: Add factory constructor for JSON serialization if needed later
  // factory DosageResult.fromJson(Map<String, dynamic> json) { ... }
  // Map<String, dynamic> toJson() { ... }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DosageResult &&
        other.dosage == dosage &&
        other.warning == warning &&
        other.notes == notes;
  }

  @override
  int get hashCode => dosage.hashCode ^ warning.hashCode ^ notes.hashCode;

  @override
  String toString() =>
      'DosageResult(dosage: $dosage, warning: $warning, notes: $notes)';
}
