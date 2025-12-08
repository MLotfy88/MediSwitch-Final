import '../../domain/entities/dosage_guidelines.dart';

class DosageGuidelinesModel extends DosageGuidelines {
  const DosageGuidelinesModel({
    super.id,
    required super.activeIngredient,
    super.strength,
    required super.standardDose,
    required super.maxDose,
    required super.packageLabel,
  });

  factory DosageGuidelinesModel.fromJson(Map<String, dynamic> json) {
    return DosageGuidelinesModel(
      id: json['id'] as int?,
      activeIngredient: json['active_ingredient'] as String? ?? '',
      strength: json['strength'] as String?,
      standardDose: json['standard_dose'] as String? ?? '',
      maxDose: json['max_dose'] as String? ?? '',
      packageLabel: json['package_label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'active_ingredient': activeIngredient,
      'strength': strength,
      'standard_dose': standardDose,
      'max_dose': maxDose,
      'package_label': packageLabel,
    };
  }

  factory DosageGuidelinesModel.fromMap(Map<String, dynamic> map) {
    return DosageGuidelinesModel(
      id: map['id'] as int?,
      activeIngredient: map['active_ingredient'] as String? ?? '',
      strength: map['strength'] as String?,
      standardDose: map['standard_dose'] as String? ?? '',
      maxDose: map['max_dose'] as String? ?? '',
      packageLabel: map['package_label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'active_ingredient': activeIngredient,
      'strength': strength,
      'standard_dose': standardDose,
      'max_dose': maxDose,
      'package_label': packageLabel,
    };
  }
}
