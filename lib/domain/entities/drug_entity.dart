import 'package:equatable/equatable.dart';

// Represents the drug object in the domain layer.
class DrugEntity extends Equatable {
  final String tradeName;
  final String arabicName;
  final String price;
  final String? oldPrice; // Add optional old price field
  final String mainCategory;
  final String active;
  final String company;
  final String dosageForm;
  final double concentration;
  final String unit;
  final String usage;
  final String description;
  final String lastPriceUpdate;
  final String? imageUrl;

  const DrugEntity({
    required this.tradeName,
    required this.arabicName,
    required this.price,
    this.oldPrice, // Add to constructor
    required this.mainCategory,
    required this.active,
    required this.company,
    required this.dosageForm,
    required this.concentration,
    required this.unit,
    required this.usage,
    required this.description,
    required this.lastPriceUpdate,
    this.imageUrl,
  });

  // Factory constructor for an empty instance
  factory DrugEntity.empty() {
    return const DrugEntity(
      tradeName: '',
      arabicName: '',
      price: '',
      oldPrice: null, // Initialize as null
      mainCategory: '',
      active: '',
      company: '',
      dosageForm: '',
      concentration: 0.0,
      unit: '',
      usage: '',
      description: '',
      lastPriceUpdate: '',
      imageUrl: null,
    );
  }

  @override
  List<Object?> get props => [
    tradeName,
    arabicName,
    price,
    oldPrice, // Add to props
    mainCategory,
    active,
    company,
    dosageForm,
    concentration,
    unit,
    usage,
    description,
    lastPriceUpdate,
    imageUrl,
  ];
}
