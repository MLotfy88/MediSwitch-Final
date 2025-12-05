import 'package:equatable/equatable.dart';

// Represents the drug object in the domain layer.
class DrugEntity extends Equatable {
  final int? id; // Add optional ID field
  final String tradeName;
  final String arabicName;
  final String price;
  final String? oldPrice; // Add optional old price field
  final String mainCategory;
  final String? category; // Add optional category field
  final String? category_ar; // Add optional Arabic category field
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
    this.id, // Add to constructor
    required this.tradeName,
    required this.arabicName,
    required this.price,
    this.oldPrice, // Add to constructor
    required this.mainCategory,
    this.category, // Add to constructor
    this.category_ar, // Add to constructor
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
      id: null,
      tradeName: '',
      arabicName: '',
      price: '',
      oldPrice: null, // Initialize as null
      mainCategory: '',
      category: null, // Initialize as null
      category_ar: null, // Initialize as null
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
    id, // Add to props
    tradeName,
    arabicName,
    price,
    oldPrice, // Add to props
    mainCategory,
    category, // Add to props
    category_ar, // Add to props
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
