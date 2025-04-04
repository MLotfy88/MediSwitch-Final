import 'package:equatable/equatable.dart';

// Represents the drug object in the domain layer.
// Contains only the properties needed by the business logic/UI.
class DrugEntity extends Equatable {
  final String tradeName;
  final String arabicName;
  final String price;
  final String mainCategory;
  // Added fields from MedicineModel
  final String active;
  final String company;
  final String dosageForm;
  final double concentration; // Added for dosage calculation
  final String unit;
  final String usage;
  final String description;
  final String lastPriceUpdate;
  const DrugEntity({
    required this.tradeName,
    required this.arabicName,
    required this.price,
    required this.mainCategory,
    // Add new fields to constructor
    required this.active,
    required this.company,
    required this.dosageForm,
    required this.concentration, // Added for dosage calculation
    required this.unit,
    required this.usage,
    required this.description,
    required this.lastPriceUpdate,
  });

  // Using Equatable for value comparison
  @override
  List<Object?> get props => [
    tradeName,
    arabicName,
    price,
    mainCategory,
    // Add new fields to props
    active,
    company,
    dosageForm,
    concentration, // Added for dosage calculation
    unit,
    usage,
    description,
    lastPriceUpdate,
  ];
}
