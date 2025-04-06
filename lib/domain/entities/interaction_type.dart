/// Enum representing the type or mechanism of a drug interaction.
enum InteractionType {
  /// Pharmacokinetic interaction: Affects absorption, distribution, metabolism, or excretion.
  pharmacokinetic,

  /// Pharmacodynamic interaction: Affects the drug's mechanism of action.
  pharmacodynamic,

  /// Therapeutic interaction: Affects the overall therapeutic outcome.
  therapeutic,

  /// Unknown interaction type.
  unknown,
}

// Helper extension for string conversion (optional but useful)
extension InteractionTypeExtension on InteractionType {
  String toJson() => name; // Use the enum value name directly

  static InteractionType fromJson(String json) {
    return InteractionType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => InteractionType.unknown, // Default if not found
    );
  }

  // Optional: Add Arabic names if needed for UI
  String get arabicName {
    switch (this) {
      case InteractionType.pharmacokinetic:
        return 'حركية الدواء';
      case InteractionType.pharmacodynamic:
        return 'ديناميكية الدواء';
      case InteractionType.therapeutic:
        return 'علاجي';
      case InteractionType.unknown:
        return 'غير محدد';
    }
  }
}
