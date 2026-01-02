import 'package:equatable/equatable.dart';

// Represents the drug object in the domain layer.
class DrugEntity extends Equatable {
  final int? id; // Add optional ID field
  final String tradeName;
  final String arabicName;
  final String price;
  final String? oldPrice; // Add optional old price field
  final String? category; // Add optional category field
  final String active;
  final String company;
  final String dosageForm;
  final String? dosageFormAr; // New Field
  final String concentration;
  final String unit;
  final String usage;
  final String? pharmacology;
  final String? barcode;
  final String? qrCode; // New Field
  final int visits; // New Field
  final String lastPriceUpdate;

  // Clinical Data Fields
  final String? indication;
  final String? mechanismOfAction;
  final String? pharmacodynamics;
  final String? dataSourcePharmacology;

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
    this.category,
    required this.active,
    required this.company,
    required this.dosageForm,
    this.dosageFormAr,
    required this.concentration,
    required this.unit,
    required this.usage,
    this.pharmacology,
    this.barcode,
    this.qrCode,
    this.visits = 0,
    required this.lastPriceUpdate,
    this.indication,
    this.mechanismOfAction,
    this.pharmacodynamics,
    this.dataSourcePharmacology,
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
      category: null,
      active: '',
      company: '',
      dosageForm: '',
      concentration: '',
      unit: '',
      usage: '',
      lastPriceUpdate: '',
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
      category: category,
      active: active,
      company: company,
      dosageForm: dosageForm,
      dosageFormAr: dosageFormAr,
      concentration: concentration,
      unit: unit,
      usage: usage,
      pharmacology: pharmacology,
      barcode: barcode,
      qrCode: qrCode,
      visits: visits,
      lastPriceUpdate: lastPriceUpdate,
      indication: indication,
      mechanismOfAction: mechanismOfAction,
      pharmacodynamics: pharmacodynamics,
      dataSourcePharmacology: dataSourcePharmacology,
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
    category,
    active,
    company,
    dosageForm,
    dosageFormAr,
    concentration,
    unit,
    usage,
    pharmacology,
    barcode,
    qrCode,
    visits,
    lastPriceUpdate,
    indication,
    mechanismOfAction,
    pharmacodynamics,
    dataSourcePharmacology,
    isPopular,
    isNew,
    hasDrugInteraction,
    hasFoodInteraction,
    hasDiseaseInteraction,
  ];
}
