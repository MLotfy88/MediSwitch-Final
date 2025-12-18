import '../../core/database/database_helper.dart'; // Import DatabaseHelper for column names
import '../../domain/entities/drug_entity.dart'; // Import DrugEntity

class MedicineModel {
  final int? id; // Now the primary identifier from D1
  final String tradeName;
  final String arabicName;
  final String price;
  final String oldPrice;
  final String active;
  final String company;
  final String dosageForm;
  final String dosageFormAr;
  final String concentration;
  final String unit;
  final String usage;
  final String usageAr;
  final String category; // General Category
  final String categoryAr;
  final String mainCategory;
  final String description;
  final String barcode;
  final int visits;
  final String lastPriceUpdate;
  final String? imageUrl;
  final int updatedAt; // Unix timestamp for Sync

  MedicineModel({
    this.id,
    required this.tradeName,
    required this.arabicName,
    required this.price,
    required this.oldPrice,
    required this.active,
    required this.company,
    required this.dosageForm,
    required this.dosageFormAr,
    required this.concentration,
    required this.unit,
    required this.usage,
    required this.usageAr,
    required this.category,
    required this.categoryAr,
    this.mainCategory = '',
    required this.description,
    required this.barcode,
    required this.visits,
    required this.lastPriceUpdate,
    this.imageUrl,
    this.updatedAt = 0,
  });

  // Helper function to safely parse string from dynamic row data
  static String _parseString(dynamic value) => value?.toString().trim() ?? '';

  // Helper to normalize date
  static String _normalizeDate(String date) {
    if (date.isEmpty) return '';
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    } catch (e) {}
    return date;
  }

  factory MedicineModel.fromCsv(List<dynamic> row) {
    return MedicineModel(
      id: row.length > 0 ? int.tryParse(row[0].toString()) : null,
      tradeName: row.length > 1 ? _parseString(row[1]) : '',
      arabicName: row.length > 2 ? _parseString(row[2]) : '',
      price: row.length > 3 ? _parseString(row[3]) : '',
      oldPrice: row.length > 4 ? _parseString(row[4]) : '',
      active: row.length > 5 ? _parseString(row[5]) : '',
      company: row.length > 6 ? _parseString(row[6]) : '',
      dosageForm: row.length > 7 ? _parseString(row[7]) : '',
      dosageFormAr: row.length > 8 ? _parseString(row[8]) : '',
      concentration: row.length > 9 ? _parseString(row[9]) : '',
      unit: row.length > 10 ? _parseString(row[10]) : '',
      usage: row.length > 11 ? _parseString(row[11]) : '',
      usageAr: row.length > 12 ? _parseString(row[12]) : '',
      category: row.length > 13 ? _parseString(row[13]) : '',
      categoryAr: row.length > 14 ? _parseString(row[14]) : '',
      mainCategory: row.length > 13 ? _parseString(row[13]) : '',
      description: row.length > 15 ? _parseString(row[15]) : '',
      barcode: row.length > 16 ? _parseString(row[16]) : '',
      visits: row.length > 17 ? (int.tryParse(row[17].toString()) ?? 0) : 0,
      lastPriceUpdate: row.length > 18 ? _normalizeDate(_parseString(row[18])) : '',
      imageUrl: row.length > 19 ? _parseString(row[19]) : null,
      updatedAt: 0, // CSV doesn't have it generally
    );
  }

  // Specialized factory for Cloudflare D1 Sync Data (Snake Case)
  factory MedicineModel.fromSyncJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'] as int?,
      tradeName: _parseString(json['trade_name']),
      arabicName: _parseString(json['arabic_name']),
      active: _parseString(json['active']),
      company: _parseString(json['company']),
      category: _parseString(json['category']),
      categoryAr: _parseString(json['category_ar']),
      price: _parseString(json['price']),
      description: _parseString(json['description']),
      imageUrl: _parseString(json['image_url']),
      lastPriceUpdate: _parseString(json['last_price_update']),
      updatedAt: json['updated_at'] as int? ?? 0,
      // Mapping defaults for missing D1 fields if any
      oldPrice: _parseString(json['old_price']),
      dosageForm: _parseString(json['dosage_form']),
      dosageFormAr: _parseString(json['dosage_form_ar']),
      concentration: _parseString(json['concentration']),
      unit: _parseString(json['unit']),
      usage: _parseString(json['usage']),
      usageAr: _parseString(json['usage_ar']),
      barcode: _parseString(json['barcode']),
      visits: json['visits'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.colId: id,
      DatabaseHelper.colTradeName: tradeName,
      DatabaseHelper.colArabicName: arabicName,
      DatabaseHelper.colPrice: price,
      DatabaseHelper.colOldPrice: oldPrice,
      DatabaseHelper.colActive: active,
      DatabaseHelper.colCompany: company,
      DatabaseHelper.colDosageForm: dosageForm,
      DatabaseHelper.colDosageFormAr: dosageFormAr,
      DatabaseHelper.colConcentration: concentration,
      DatabaseHelper.colUnit: unit,
      DatabaseHelper.colUsage: usage,
      DatabaseHelper.colUsageAr: usageAr,
      DatabaseHelper.colCategory: category,
      DatabaseHelper.colCategoryAr: categoryAr,
      DatabaseHelper.colMainCategory: mainCategory,
      DatabaseHelper.colDescription: description,
      DatabaseHelper.colBarcode: barcode,
      DatabaseHelper.colVisits: visits,
      DatabaseHelper.colLastPriceUpdate: lastPriceUpdate,
      DatabaseHelper.colImageUrl: imageUrl,
      DatabaseHelper.colUpdatedAt: updatedAt,
    };
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map[DatabaseHelper.colId] as int?,
      tradeName: map[DatabaseHelper.colTradeName]?.toString() ?? '',
      arabicName: map[DatabaseHelper.colArabicName]?.toString() ?? '',
      price: map[DatabaseHelper.colPrice]?.toString() ?? '',
      oldPrice: map[DatabaseHelper.colOldPrice]?.toString() ?? '',
      active: map[DatabaseHelper.colActive]?.toString() ?? '',
      company: map[DatabaseHelper.colCompany]?.toString() ?? '',
      dosageForm: map[DatabaseHelper.colDosageForm]?.toString() ?? '',
      dosageFormAr: map[DatabaseHelper.colDosageFormAr]?.toString() ?? '',
      concentration: map[DatabaseHelper.colConcentration]?.toString() ?? '',
      unit: map[DatabaseHelper.colUnit]?.toString() ?? '',
      usage: map[DatabaseHelper.colUsage]?.toString() ?? '',
      usageAr: map[DatabaseHelper.colUsageAr]?.toString() ?? '',
      category: map[DatabaseHelper.colCategory]?.toString() ?? '',
      categoryAr: map[DatabaseHelper.colCategoryAr]?.toString() ?? '',
      mainCategory: map[DatabaseHelper.colMainCategory]?.toString() ?? '',
      description: map[DatabaseHelper.colDescription]?.toString() ?? '',
      barcode: map[DatabaseHelper.colBarcode]?.toString() ?? '',
      visits: map[DatabaseHelper.colVisits] as int? ?? 0,
      lastPriceUpdate: map[DatabaseHelper.colLastPriceUpdate]?.toString() ?? '',
      imageUrl: map[DatabaseHelper.colImageUrl]?.toString(),
      updatedAt: map[DatabaseHelper.colUpdatedAt] as int? ?? 0,
    );
  }

  DrugEntity toEntity() {
    return DrugEntity(
      id: id,
      tradeName: tradeName,
      arabicName: arabicName,
      price: price,
      oldPrice: oldPrice.isNotEmpty ? oldPrice : null,
      mainCategory: mainCategory,
      category: category.isNotEmpty ? category : null,
      category_ar: categoryAr.isNotEmpty ? categoryAr : null,
      active: active,
      company: company,
      dosageForm: dosageForm,
      concentration: concentration,
      unit: unit,
      usage: usage,
      description: description,
      lastPriceUpdate: lastPriceUpdate,
      imageUrl: imageUrl,
    );
  }
}
