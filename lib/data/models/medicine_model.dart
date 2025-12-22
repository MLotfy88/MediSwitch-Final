import 'dart:convert';

import '../../core/database/database_helper.dart'; // Import DatabaseHelper for column names
import '../../domain/entities/drug_entity.dart'; // Import DrugEntity

class MedicineModel extends DrugEntity {
  final String dosageFormAr;
  final String usageAr;
  final String categoryAr;
  final String barcode;
  final int visits;
  final int updatedAt;

  const MedicineModel({
    super.id,
    required super.tradeName,
    required super.arabicName,
    required super.price,
    required String oldPrice,
    required super.active,
    required super.company,
    required super.dosageForm,
    required this.dosageFormAr,
    required super.concentration,
    required super.unit,
    required super.usage,
    required this.usageAr,
    required String category,
    required this.categoryAr,
    super.mainCategory = '',
    required super.description,
    required String pharmacology,
    required this.barcode,
    required this.visits,
    required super.lastPriceUpdate,
    super.imageUrl,
    this.updatedAt = 0,
  }) : super(
         oldPrice: oldPrice == '' ? null : oldPrice,
         category: category == '' ? null : category,
         category_ar: categoryAr == '' ? null : categoryAr,
         pharmacology: pharmacology == '' ? null : pharmacology,
       );

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
      // 0: Trade Name
      tradeName: row.isNotEmpty ? _parseString(row[0]) : '',
      // 1: Arabic Name
      arabicName: row.length > 2 ? _parseString(row[2]) : '',
      // 2: Active Ingredient -> Mapped to 'active'
      active: row.length > 3 ? _parseString(row[3]) : '',
      // 3: Company
      company: row.length > 5 ? _parseString(row[5]) : '',
      // 4: Price
      price: row.length > 6 ? _parseString(row[6]) : '0',
      // Old Price
      oldPrice: row.length > 7 ? _parseString(row[7]) : '',
      // Last Price Update
      lastPriceUpdate:
          row.length > 8 ? _normalizeDate(_parseString(row[8])) : '',
      // Category
      category: row.length > 4 ? _parseString(row[4]) : '',
      categoryAr: '', // Not in CSV
      unit: row.length > 9 ? _parseString(row[9]) : '',
      barcode: row.length > 10 ? _parseString(row[10]) : '',
      description:
          row.length > 17
              ? _parseString(row[17])
              : '', // Assuming desc is further down now? No, let's re-check CSV header
      // id,trade_name,arabic_name,active,category,company,price,old_price,last_price_update,units,barcode,qr_code,pharmacology,usage,visits,concentration,dosage_form,dosage_form_ar
      // 0  1          2           3      4        5       6     7         8                 9     10      11      12           13    14     15            16          17
      pharmacology: row.length > 12 ? _parseString(row[12]) : '',
      usage: row.length > 13 ? _parseString(row[13]) : '',
      usageAr: '', // Not in CSV
      visits: row.length > 14 ? (int.tryParse(row[14].toString()) ?? 0) : 0,
      concentration: row.length > 15 ? _parseString(row[15]) : '',
      dosageForm: row.length > 16 ? _parseString(row[16]) : '',
      dosageFormAr: row.length > 17 ? _parseString(row[17]) : '',
      mainCategory: row.length > 4 ? _parseString(row[4]) : '',
      updatedAt: 0,
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
      pharmacology: _parseString(json['pharmacology']),
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
      DatabaseHelper.colPharmacology: pharmacology,
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
      pharmacology: map[DatabaseHelper.colPharmacology]?.toString() ?? '',
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
      oldPrice: oldPrice != null && oldPrice!.isNotEmpty ? oldPrice : null,
      mainCategory: mainCategory,
      category: category != null && category!.isNotEmpty ? category : null,
      category_ar: categoryAr.isNotEmpty ? categoryAr : null,
      active: active,
      company: company,
      dosageForm: dosageForm,
      concentration: concentration,
      unit: unit,
      usage: usage,
      description: description,
      pharmacology: pharmacology,
      lastPriceUpdate: lastPriceUpdate,
      imageUrl: imageUrl,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel.fromMap(json);
  }

  factory MedicineModel.fromEntity(DrugEntity entity) {
    return MedicineModel(
      id: entity.id,
      tradeName: entity.tradeName,
      arabicName: entity.arabicName,
      price: entity.price,
      oldPrice: entity.oldPrice ?? '',
      active: entity.active,
      company: entity.company,
      dosageForm: entity.dosageForm,
      dosageFormAr: '',
      concentration: entity.concentration,
      unit: entity.unit,
      usage: entity.usage,
      usageAr: '',
      category: entity.category ?? '',
      categoryAr: entity.category_ar ?? '',
      mainCategory: entity.mainCategory,
      description: entity.description,
      pharmacology: entity.pharmacology ?? '',
      barcode: '',
      visits: 0,
      lastPriceUpdate: entity.lastPriceUpdate,
      imageUrl: entity.imageUrl,
      updatedAt: 0,
    );
  }
}
