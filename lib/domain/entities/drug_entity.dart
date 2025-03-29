import 'package:equatable/equatable.dart';

// Represents the drug object in the domain layer.
// Contains only the properties needed by the business logic/UI.
class DrugEntity extends Equatable {
  final String tradeName;
  final String arabicName;
  final String price;
  final String mainCategory;
  // Add other fields as needed, e.g., company, dosageForm, activeIngredient

  const DrugEntity({
    required this.tradeName,
    required this.arabicName,
    required this.price,
    required this.mainCategory,
    // Add other fields to constructor
  });

  // Using Equatable for value comparison
  @override
  List<Object?> get props => [
    tradeName,
    arabicName,
    price,
    mainCategory,
    // Add other fields here
  ];
}
