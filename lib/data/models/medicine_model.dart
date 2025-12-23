import 'dart:convert';

import '../../core/database/database_helper.dart'; // Import DatabaseHelper for column names
import '../../domain/entities/drug_entity.dart'; // Import DrugEntity

class MedicineModel extends DrugEntity {
  final int updatedAt;

  const MedicineModel({
    super.id,
    required super.tradeName,
    required super.arabicName,
    required super.price,
    super.oldPrice,
    required super.active,
    required super.company,
    required super.dosageForm,
    super.dosageFormAr,
    required super.concentration,
    required super.unit,
    required super.usage,
    super.category,
    super.categoryAr,
    super.mainCategory = '',
    required super.description,
    super.pharmacology,
    super.barcode,
    super.qrCode,
    super.visits = 0,
    required super.lastPriceUpdate,
    super.imageUrl,
    super.hasDrugInteraction = false,
    super.hasFoodInteraction = false,
    this.updatedAt = 0,
  });

  // Helper function to safely parse string from dynamic row data
  static String _parseString(dynamic value) => value?.toString().trim() ?? '';

  // Helper to normalize date (YYYY-MM-DD or DD/MM/YYYY)
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

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  factory MedicineModel.fromCsv(List<dynamic> row) {
    // CSV Header: id,trade_name,arabic_name,active,category,company,price,old_price,last_price_update,units,barcode,qr_code,pharmacology,usage,visits,concentration,dosage_form,dosage_form_ar
    final cat = row.length > 4 ? _parseString(row[4]) : '';
    final pharm = row.length > 12 ? _parseString(row[12]) : '';
    final desc =
        row.length > 12
            ? _parseString(row[12])
            : ''; // Use pharmacology as fallback for description

    return MedicineModel(
      id: row.isNotEmpty ? _parseInt(row[0]) : 0,
      tradeName: row.length > 1 ? _parseString(row[1]) : '',
      arabicName: row.length > 2 ? _parseString(row[2]) : '',
      active: row.length > 3 ? _parseString(row[3]) : '',
      category: cat,
      mainCategory: cat,
      company: row.length > 5 ? _parseString(row[5]) : '',
      price: row.length > 6 ? _parseString(row[6]) : '0',
      oldPrice: row.length > 7 ? _parseString(row[7]) : '',
      lastPriceUpdate:
          row.length > 8 ? _normalizeDate(_parseString(row[8])) : '',
      unit: row.length > 9 ? _parseString(row[9]) : '',
      barcode: row.length > 10 ? _parseString(row[10]) : '',
      qrCode: row.length > 11 ? _parseString(row[11]) : '',
      pharmacology: pharm,
      description: desc,
      usage: row.length > 13 ? _parseString(row[13]) : '',
      visits: row.length > 14 ? _parseInt(row[14]) : 0,
      concentration: row.length > 15 ? _parseString(row[15]) : '',
      dosageForm: row.length > 16 ? _parseString(row[16]) : '',
      dosageFormAr: row.length > 17 ? _parseString(row[17]) : '',
      updatedAt: 0,
    );
  }

  // Specialized factory for Cloudflare D1 Sync Data (Snake Case)
  factory MedicineModel.fromSyncJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: _parseInt(json['id']),
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
      updatedAt: _parseInt(json['updated_at']),
      oldPrice: _parseString(json['old_price']),
      dosageForm: _parseString(json['dosage_form']),
      dosageFormAr: _parseString(json['dosage_form_ar']),
      concentration: _parseString(json['concentration']),
      unit: _parseString(json['unit']),
      usage: _parseString(json['usage']),
      barcode: _parseString(json['barcode']),
      qrCode: _parseString(json['qr_code']),
      visits: _parseInt(json['visits']),
      hasDrugInteraction:
          json['has_drug_interaction'] == 1 ||
          json['has_drug_interaction'] == true,
      hasFoodInteraction:
          json['has_food_interaction'] == 1 ||
          json['has_food_interaction'] == true,
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
      DatabaseHelper.colCategory: category,
      DatabaseHelper.colCategoryAr: categoryAr,
      DatabaseHelper.colMainCategory: mainCategory,
      DatabaseHelper.colDescription: description,
      DatabaseHelper.colPharmacology: pharmacology,
      DatabaseHelper.colBarcode: barcode,
      DatabaseHelper.colQrCode: qrCode,
      DatabaseHelper.colVisits: visits,
      DatabaseHelper.colLastPriceUpdate: lastPriceUpdate,
      DatabaseHelper.colImageUrl: imageUrl,
      DatabaseHelper.colUpdatedAt: updatedAt,
      'has_drug_interaction': hasDrugInteraction ? 1 : 0,
      'has_food_interaction': hasFoodInteraction ? 1 : 0,
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
      category: map[DatabaseHelper.colCategory]?.toString() ?? '',
      categoryAr: map[DatabaseHelper.colCategoryAr]?.toString() ?? '',
      mainCategory: map[DatabaseHelper.colMainCategory]?.toString() ?? '',
      description: map[DatabaseHelper.colDescription]?.toString() ?? '',
      pharmacology: map[DatabaseHelper.colPharmacology]?.toString() ?? '',
      barcode: map[DatabaseHelper.colBarcode]?.toString() ?? '',
      qrCode: map[DatabaseHelper.colQrCode]?.toString() ?? '',
      visits: map[DatabaseHelper.colVisits] as int? ?? 0,
      lastPriceUpdate: map[DatabaseHelper.colLastPriceUpdate]?.toString() ?? '',
      imageUrl: map[DatabaseHelper.colImageUrl]?.toString(),
      updatedAt: map[DatabaseHelper.colUpdatedAt] as int? ?? 0,
      hasDrugInteraction:
          map['has_drug_interaction'] == 1 ||
          map['has_drug_interaction'] == true,
      hasFoodInteraction:
          map['has_food_interaction'] == 1 ||
          map['has_food_interaction'] == true,
    );
  }

  DrugEntity toEntity() {
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
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('trade_name')) {
      return MedicineModel.fromSyncJson(json);
    }
    return MedicineModel.fromMap(json);
  }

  factory MedicineModel.fromEntity(DrugEntity entity) {
    return MedicineModel(
      id: entity.id,
      tradeName: entity.tradeName,
      arabicName: entity.arabicName,
      price: entity.price,
      oldPrice: entity.oldPrice,
      active: entity.active,
      company: entity.company,
      dosageForm: entity.dosageForm,
      dosageFormAr: entity.dosageFormAr,
      concentration: entity.concentration,
      unit: entity.unit,
      usage: entity.usage,
      category: entity.category,
      categoryAr: entity.categoryAr,
      mainCategory: entity.mainCategory,
      description: entity.description,
      pharmacology: entity.pharmacology,
      barcode: entity.barcode,
      qrCode: entity.qrCode,
      visits: entity.visits,
      lastPriceUpdate: entity.lastPriceUpdate,
      imageUrl: entity.imageUrl,
      updatedAt: 0,
    );
  }
}
