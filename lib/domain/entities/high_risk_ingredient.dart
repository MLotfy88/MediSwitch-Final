/// Represents a high-risk active ingredient with its danger metrics
class HighRiskIngredient {
  final String name;
  final int totalInteractions;
  final int severeCount;
  final int moderateCount;
  final int minorCount;
  final int dangerScore;

  const HighRiskIngredient({
    required this.name,
    required this.totalInteractions,
    required this.severeCount,
    required this.moderateCount,
    required this.minorCount,
    required this.dangerScore,
  });

  /// Display name formatted for UI
  String get displayName => name;
}
