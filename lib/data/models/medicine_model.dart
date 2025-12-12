import '../../core/database/database_helper.dart'; // Import DatabaseHelper for column names
import '../../domain/entities/drug_entity.dart'; // Import DrugEntity

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
  final String concentration;
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
    required this.concentration,
    this.imageUrl,
    this.id,
  });

  // Helper function to safely parse string from dynamic row data
  static String _parseString(dynamic value) => value?.toString() ?? '';
  // Helper function to safely parse double from dynamic row data
  static double? _parseDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '');

  // Helper to normalize date from dd/MM/yyyy to yyyy-MM-dd for sorting
  static String _normalizeDate(String date) {
    if (date.isEmpty) return '';
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        // Assume dd/MM/yyyy
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    } catch (e) {
      // Ignore error and return original
    }
    return date;
  }

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
      lastPriceUpdate:
          row.length > 16 ? _normalizeDate(_parseString(row[16])) : '',
      concentration: row.length > 17 ? _parseString(row[17]) : '',
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
      DatabaseHelper.colConcentration:
          concentration.isNotEmpty ? concentration : null,
      DatabaseHelper.colImageUrl: imageUrl,
      // Add category fields to the map (assuming columns exist in DB schema)
      DatabaseHelper.colCategory: category,
      DatabaseHelper.colCategoryAr: categoryAr,
      // Note: Fields like mainCategoryAr, dosageFormAr, usageAr are still not mapped
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
      mainCategoryAr: '', // Not stored (or read if added to DB)
      category:
          map[DatabaseHelper.colCategory]?.toString() ?? '', // Read from map
      categoryAr:
          map[DatabaseHelper.colCategoryAr]?.toString() ?? '', // Read from map
      company: map[DatabaseHelper.colCompany]?.toString() ?? '',
      dosageForm: map[DatabaseHelper.colDosageForm]?.toString() ?? '',
      dosageFormAr: '', // Not stored
      unit: map[DatabaseHelper.colUnit]?.toString() ?? '',
      usage: map[DatabaseHelper.colUsage]?.toString() ?? '',
      usageAr: '', // Not stored (or read if added to DB)
      description: map[DatabaseHelper.colDescription]?.toString() ?? '',
      lastPriceUpdate: map[DatabaseHelper.colLastPriceUpdate]?.toString() ?? '',
      concentration: map[DatabaseHelper.colConcentration]?.toString() ?? '',
      imageUrl: map[DatabaseHelper.colImageUrl]?.toString(),
    );
  }

  // Convert MedicineModel to DrugEntity
  DrugEntity toEntity() {
    return DrugEntity(
      id: id,
      tradeName: tradeName,
      arabicName: arabicName,
      price: price,
      oldPrice: oldPrice.isNotEmpty ? oldPrice : null,
      mainCategory: mainCategory,
      active: active,
      company: company,
      category:
          category.isNotEmpty ? category : null, // Pass category if available
      category_ar:
          categoryAr.isNotEmpty
              ? categoryAr
              : null, // Pass categoryAr if available
      dosageForm: dosageForm,
      concentration: concentration,
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
