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
  final String? categoryAr; // Standardized Naming
  final String active;
  final String company;
  final String dosageForm;
  final String? dosageFormAr; // New Field
  final String concentration;
  final String unit;
  final String usage;
  final String description;
  final String? pharmacology;
  final String? barcode;
  final String? qrCode; // New Field
  final int visits; // New Field
  final String? imageUrl;
  final String lastPriceUpdate;

  // Interaction Flags for UI
  final bool hasDrugInteraction;
  final bool hasFoodInteraction;
  final bool hasDiseaseInteraction;

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
    this.categoryAr,
    required this.active,
    required this.company,
    required this.dosageForm,
    this.dosageFormAr,
    required this.concentration,
    required this.unit,
    required this.usage,
    required this.description,
    this.pharmacology,
    this.barcode,
    this.qrCode,
    this.visits = 0,
    required this.lastPriceUpdate,
    this.imageUrl,
    this.isPopular = false,
    this.isNew = false,
    this.hasDrugInteraction = false,
    this.hasFoodInteraction = false,
    this.hasDiseaseInteraction = false,
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
      categoryAr: null,
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

  /// Creates a copy of this entity with the isPopular flag updated
  DrugEntity copyWith({bool? isPopular, bool? isNew}) {
    return DrugEntity(
      id: id,
      tradeName: tradeName,
      arabicName: arabicName,
      price: price,
      oldPrice: oldPrice,
      mainCategory: mainCategory,
      category: category,
      categoryAr: categoryAr,
      active: active,
      company: company,
      dosageForm: dosageForm,
      dosageFormAr: dosageFormAr,
      concentration: concentration,
      unit: unit,
      usage: usage,
      description: description,
      pharmacology: pharmacology,
      barcode: barcode,
      qrCode: qrCode,
      visits: visits,
      lastPriceUpdate: lastPriceUpdate,
      imageUrl: imageUrl,
      hasDrugInteraction: hasDrugInteraction,
      hasFoodInteraction: hasFoodInteraction,
      hasDiseaseInteraction: hasDiseaseInteraction,
      isPopular: isPopular ?? this.isPopular,
      isNew: isNew ?? this.isNew,
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
    categoryAr,
    active,
    company,
    dosageForm,
    dosageFormAr,
    concentration,
    unit,
    usage,
    description,
    pharmacology,
    barcode,
    qrCode,
    visits,
    lastPriceUpdate,
    imageUrl,
    isPopular,
    isNew,
    hasDrugInteraction,
    hasFoodInteraction,
    hasDiseaseInteraction,
  ];
}
