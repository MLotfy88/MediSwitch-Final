/// Enum representing the severity level of a drug interaction.
enum InteractionSeverity {
  /// Minor interaction: Usually does not require intervention.
  minor,

  /// Moderate interaction: May require monitoring or dosage adjustment.
  moderate,

  /// Major interaction: Requires medical intervention or therapy change.
  major,

  /// Severe interaction: Potentially life-threatening or causing significant harm.
  severe,

  /// Contraindicated interaction: Combination should be avoided.
  contraindicated,

  /// Unknown severity.
  unknown, // Added for cases where severity isn't specified
}

// Helper extension for string conversion (optional but useful)
extension InteractionSeverityExtension on InteractionSeverity {
  String toJson() => name; // Use the enum value name directly

  static InteractionSeverity fromJson(String json) {
    return InteractionSeverity.values.firstWhere(
      (e) => e.name == json,
      orElse: () => InteractionSeverity.unknown, // Default if not found
    );
  }

  // Optional: Add Arabic names if needed for UI
  String get arabicName {
    switch (this) {
      case InteractionSeverity.minor:
        return 'بسيط';
      case InteractionSeverity.moderate:
        return 'متوسط';
      case InteractionSeverity.major:
        return 'كبير';
      case InteractionSeverity.severe:
        return 'شديد';
      case InteractionSeverity.contraindicated:
        return 'مضاد استطباب';
      case InteractionSeverity.unknown:
        return 'غير معروف';
    }
  }
}
