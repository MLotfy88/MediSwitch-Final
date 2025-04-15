import '../../domain/entities/drug_entity.dart'; // Import DrugEntity
import '../../core/database/database_helper.dart'; // Import DatabaseHelper for column names

class MedicineModel {
  final String tradeName;
  final String arabicName;
  final String oldPrice;
  final String price;
  final String active;
  final String mainCategory;
  final String mainCategoryAr;
  final String category;
  final String categoryAr;
  final String company;
  final String dosageForm;
  final String dosageFormAr;
  final String unit;
  final String usage;
  final String usageAr;
  final String description;
  final String lastPriceUpdate;
  final double? concentration;
  final String? imageUrl;
  final int? id; // Optional ID from database

  MedicineModel({
    required this.tradeName,
    required this.arabicName,
    required this.oldPrice,
    required this.price,
    required this.active,
    required this.mainCategory,
    required this.mainCategoryAr,
    required this.category,
    required this.categoryAr,
    required this.company,
    required this.dosageForm,
    required this.dosageFormAr,
    required this.unit,
    required this.usage,
    required this.usageAr,
    required this.description,
    required this.lastPriceUpdate,
    this.concentration,
    this.imageUrl,
    this.id,
  });

  // Helper function to safely parse string from dynamic row data
  static String _parseString(dynamic value) => value?.toString() ?? '';
  // Helper function to safely parse double from dynamic row data
  static double? _parseDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '');

  factory MedicineModel.fromCsv(List<dynamic> row) {
    // Assuming CSV columns are in the order defined by the fields
    return MedicineModel(
      tradeName: row.length > 0 ? _parseString(row[0]) : '',
      arabicName: row.length > 1 ? _parseString(row[1]) : '',
      oldPrice:
          row.length > 2 ? _parseString(row[2]) : '', // Column 3 (index 2)
      price: row.length > 3 ? _parseString(row[3]) : '', // Column 4 (index 3)
      active: row.length > 4 ? _parseString(row[4]) : '',
      mainCategory: row.length > 5 ? _parseString(row[5]) : '',
      mainCategoryAr: row.length > 6 ? _parseString(row[6]) : '',
      category: row.length > 7 ? _parseString(row[7]) : '',
      categoryAr: row.length > 8 ? _parseString(row[8]) : '',
      company: row.length > 9 ? _parseString(row[9]) : '',
      dosageForm: row.length > 10 ? _parseString(row[10]) : '',
      dosageFormAr: row.length > 11 ? _parseString(row[11]) : '',
      unit: row.length > 12 ? _parseString(row[12]) : '',
      usage: row.length > 13 ? _parseString(row[13]) : '',
      usageAr: row.length > 14 ? _parseString(row[14]) : '',
      description: row.length > 15 ? _parseString(row[15]) : '',
      lastPriceUpdate: row.length > 16 ? _parseString(row[16]) : '',
      concentration: row.length > 17 ? _parseDouble(row[17]) : null,
      imageUrl: row.length > 18 ? _parseString(row[18]) : null,
    );
  }

  // Convert model to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.colTradeName: tradeName,
      DatabaseHelper.colArabicName: arabicName,
      DatabaseHelper.colOldPrice: oldPrice, // Use constant from DatabaseHelper
      DatabaseHelper.colPrice: price,
      DatabaseHelper.colActive: active,
      DatabaseHelper.colMainCategory: mainCategory,
      DatabaseHelper.colCompany: company,
      DatabaseHelper.colDosageForm: dosageForm,
      DatabaseHelper.colUnit: unit,
      DatabaseHelper.colUsage: usage,
      DatabaseHelper.colDescription: description,
      DatabaseHelper.colLastPriceUpdate: lastPriceUpdate,
      DatabaseHelper.colConcentration: concentration,
      DatabaseHelper.colImageUrl: imageUrl,
      // Note: Fields like mainCategoryAr, category, categoryAr, dosageFormAr, usageAr are not mapped as they are not in the DB schema defined in DatabaseHelper
    };
  }

  // Create model from Map (from database)
  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'] as int?, // Assuming 'id' is the primary key if needed later
      tradeName: map[DatabaseHelper.colTradeName]?.toString() ?? '',
      arabicName: map[DatabaseHelper.colArabicName]?.toString() ?? '',
      oldPrice:
          map[DatabaseHelper.colOldPrice]?.toString() ?? '', // Use constant
      price: map[DatabaseHelper.colPrice]?.toString() ?? '',
      active: map[DatabaseHelper.colActive]?.toString() ?? '',
      mainCategory: map[DatabaseHelper.colMainCategory]?.toString() ?? '',
      mainCategoryAr: '', // Not stored
      category: '', // Not stored
      categoryAr: '', // Not stored
      company: map[DatabaseHelper.colCompany]?.toString() ?? '',
      dosageForm: map[DatabaseHelper.colDosageForm]?.toString() ?? '',
      dosageFormAr: '', // Not stored
      unit: map[DatabaseHelper.colUnit]?.toString() ?? '',
      usage: map[DatabaseHelper.colUsage]?.toString() ?? '',
      usageAr: '', // Not stored
      description: map[DatabaseHelper.colDescription]?.toString() ?? '',
      lastPriceUpdate: map[DatabaseHelper.colLastPriceUpdate]?.toString() ?? '',
      concentration:
          map[DatabaseHelper.colConcentration] != null
              ? double.tryParse(map[DatabaseHelper.colConcentration].toString())
              : null,
      imageUrl: map[DatabaseHelper.colImageUrl]?.toString(),
    );
  }

  // Convert MedicineModel to DrugEntity
  DrugEntity toEntity() {
    return DrugEntity(
      tradeName: tradeName,
      arabicName: arabicName,
      price: price,
      oldPrice: oldPrice.isNotEmpty ? oldPrice : null,
      mainCategory: mainCategory,
      active: active,
      company: company,
      dosageForm: dosageForm,
      concentration: concentration ?? 0.0,
      unit: unit,
      usage: usage,
      description: description,
      lastPriceUpdate: lastPriceUpdate,
      imageUrl: imageUrl,
    );
  }

  @override
  String toString() {
    return '$tradeName - $arabicName - $price';
  }
}
