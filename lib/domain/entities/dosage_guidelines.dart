class DosageGuidelines {
  final int? id;
  final String activeIngredient;
  final String? strength;
  final String standardDose;
  final String maxDose;
  final String packageLabel;

  const DosageGuidelines({
    this.id,
    required this.activeIngredient,
    this.strength,
    required this.standardDose,
    required this.maxDose,
    required this.packageLabel,
  });
}
