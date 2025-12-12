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
  final String concentration;
  final String unit;
  final String usage;
  final String description;
  final String lastPriceUpdate;
  final String? imageUrl;

  // Aliases for compatibility
  String get nameAr => arabicName;
  String get form => dosageForm;

  // New fields for UI
  final bool isPopular;
  final bool isNew;

  const DrugEntity({
    this.id,
    required this.tradeName,
    required this.arabicName,
    required this.price,
    this.oldPrice,
    required this.mainCategory,
    this.category,
    this.category_ar,
    required this.active,
    required this.company,
    required this.dosageForm,
    required this.concentration,
    required this.unit,
    required this.usage,
    required this.description,
    required this.lastPriceUpdate,
    this.imageUrl,
    this.isPopular = false,
    this.isNew = false,
  });

  factory DrugEntity.empty() {
    return const DrugEntity(
      id: null,
      tradeName: '',
      arabicName: '',
      price: '',
      oldPrice: null,
      mainCategory: '',
      category: null,
      category_ar: null,
      active: '',
      company: '',
      dosageForm: '',
      concentration: '',
      unit: '',
      usage: '',
      description: '',
      lastPriceUpdate: '',
      imageUrl: null,
      isPopular: false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tradeName,
    arabicName,
    price,
    oldPrice,
    mainCategory,
    category,
    category_ar,
    active,
    company,
    dosageForm,
    concentration,
    unit,
    usage,
    description,
    lastPriceUpdate,
    imageUrl,
    isPopular,
  ];
}
