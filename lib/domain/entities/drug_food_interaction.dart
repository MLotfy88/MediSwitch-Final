import 'package:equatable/equatable.dart';

class DrugFoodInteraction extends Equatable {
  /// Unique ID
  final int? id;

  /// Drug identifier in DDInter
  final String drugId;

  /// Name of the interacting food
  final String foodName;

  /// Interaction severity
  final String severity;

  /// detailed description
  final String description;

  /// Clinical management
  final String management;

  /// Mechanism of action
  final String? mechanism;

  /// Bibliographic references
  final List<String> references;

  /// Creates a DrugFoodInteraction instance
  const DrugFoodInteraction({
    required this.drugId,
    required this.foodName,
    required this.severity,
    required this.description,
    required this.management,
    this.id,
    this.mechanism,
    this.references = const [],
  });

  /// Factory constructor to create an instance from JSON
  factory DrugFoodInteraction.fromJson(Map<String, dynamic> json) {
    return DrugFoodInteraction(
      id: json['id'] as int?,
      drugId: json['drug_id'] as String? ?? '',
      foodName: json['food_name'] as String? ?? '',
      severity: json['severity'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      management: json['management'] as String? ?? '',
      mechanism: json['mechanism_flags'] as String?,
      references: (json['reference_text'] as String?)?.split('|') ?? const [],
    );
  }

  @override
  List<Object?> get props => [id, drugId, foodName, severity, description];
}
