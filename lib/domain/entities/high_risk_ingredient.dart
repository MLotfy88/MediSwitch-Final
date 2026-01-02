/// Represents a high-risk active ingredient with its danger metrics
class HighRiskIngredient {
  final String name;
  final int totalInteractions;
  final int severeCount;
  final int moderateCount;
  final int minorCount;
  final int dangerScore;

  /// The exact key used in the database (e.g. sorted words "oil olive" vs display "Olive Oil")
  final String? normalizedName;

  const HighRiskIngredient({
    required this.name,
    required this.totalInteractions,
    required this.severeCount,
    required this.moderateCount,
    required this.minorCount,
    required this.dangerScore,
    this.normalizedName,
  });

  /// Display name formatted for UI
  String get displayName => name;

  factory HighRiskIngredient.fromJson(Map<String, dynamic> json) {
    return HighRiskIngredient(
      name: json['name'] as String,
      totalInteractions: json['totalInteractions'] as int,
      severeCount: json['severeCount'] as int,
      moderateCount: json['moderateCount'] as int,
      minorCount: json['minorCount'] as int,
      dangerScore: json['dangerScore'] as int,
      normalizedName: json['normalizedName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'totalInteractions': totalInteractions,
      'severeCount': severeCount,
      'moderateCount': moderateCount,
      'minorCount': minorCount,
      'dangerScore': dangerScore,
      'normalizedName': normalizedName,
    };
  }
}
