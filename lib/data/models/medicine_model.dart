import 'dart:convert';

import '../../domain/entities/drug_entity.dart';

class MedicineModel extends DrugEntity {
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
    super.pharmacology,
    super.barcode,
    super.qrCode,
    super.visits = 0,
    required super.lastPriceUpdate,
    super.indication,
    super.mechanismOfAction,
    super.pharmacodynamics,
    super.dataSourcePharmacology,
    super.hasDrugInteraction = false,
    super.hasFoodInteraction = false,
    super.hasDiseaseInteraction = false,
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
    // Remove any non-digit characters except for negative sign
    final clean = value.toString().replaceAll(RegExp(r'[^-0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  static String _parsePrice(dynamic value) {
    if (value == null) return '0';
    // Remove commas from price (e.g., "1,250" -> "1250")
    return value.toString().replaceAll(',', '').trim();
  }

  factory MedicineModel.fromCsv(List<dynamic> row) {
    // CSV Header: id,trade_name,arabic_name,active,category,company,price,old_price,last_price_update,units,barcode,qr_code,pharmacology,usage,visits,concentration,dosage_form,dosage_form_ar
    final cat = row.length > 4 ? _parseString(row[4]) : '';
    final pharm = row.length > 12 ? _parseString(row[12]) : '';

    return MedicineModel(
      id: row.isNotEmpty ? _parseInt(row[0]) : 0,
      tradeName: row.length > 1 ? _parseString(row[1]) : '',
      arabicName: row.length > 2 ? _parseString(row[2]) : '',
      active: row.length > 3 ? _parseString(row[3]) : '',
      category: cat,
      // mainCategory: cat,
      company: row.length > 5 ? _parseString(row[5]) : '',
      price: row.length > 6 ? _parsePrice(row[6]) : '0',
      oldPrice: row.length > 7 ? _parsePrice(row[7]) : '',
      lastPriceUpdate:
          row.length > 8 ? _normalizeDate(_parseString(row[8])) : '',
      unit: row.length > 9 ? _parseString(row[9]) : '',
      barcode: row.length > 10 ? _parseString(row[10]) : '',
      qrCode: row.length > 11 ? _parseString(row[11]) : '',
      pharmacology: pharm,
      usage: row.length > 13 ? _parseString(row[13]) : '',
      visits: row.length > 14 ? _parseInt(row[14]) : 0,
      concentration: row.length > 15 ? _parseString(row[15]) : '',
      dosageForm: row.length > 16 ? _parseString(row[16]) : '',
      dosageFormAr: row.length > 17 ? _parseString(row[17]) : '',
      indication: row.length > 18 ? _parseString(row[18]) : null,
      mechanismOfAction: row.length > 19 ? _parseString(row[19]) : null,
      pharmacodynamics: row.length > 20 ? _parseString(row[20]) : null,
      dataSourcePharmacology: row.length > 21 ? _parseString(row[21]) : null,
      hasDrugInteraction:
          row.length > 22
              ? (row[22] == 1 ||
                  row[22] == '1' ||
                  row[22] == true ||
                  row[22] == 'true')
              : false,
      hasFoodInteraction:
          row.length > 23
              ? (row[23] == 1 ||
                  row[23] == '1' ||
                  row[23] == true ||
                  row[23] == 'true')
              : false,
      hasDiseaseInteraction:
          row.length > 24
              ? (row[24] == 1 ||
                  row[24] == '1' ||
                  row[24] == true ||
                  row[24] == 'true')
              : false,
    );
  }

  // Specialized factory for Cloudflare D1 Sync Data (Snake Case)
  // Specialized factory for Cloudflare D1 Sync Data (Snake Case)
  factory MedicineModel.fromSyncJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: _parseInt(json['id']),
      tradeName: _parseString(json['trade_name']),
      arabicName: _parseString(json['arabic_name']),
      active: _parseString(json['active']),
      company: _parseString(json['company']),
      category: _parseString(json['category']),
      price: _parseString(json['price']),
      pharmacology: _parseString(json['pharmacology']),
      lastPriceUpdate: _parseString(json['last_price_update']),
      oldPrice: _parseString(json['old_price']),
      dosageForm: _parseString(json['dosage_form']),
      dosageFormAr: _parseString(json['dosage_form_ar']),
      concentration: _parseString(json['concentration']),
      unit: _parseString(json['unit']),
      usage: _parseString(json['usage']),
      barcode: _parseString(json['barcode']),
      qrCode: _parseString(json['qr_code']),
      visits: _parseInt(json['visits']),
      indication: _parseString(json['indication']),
      mechanismOfAction: _parseString(json['mechanism_of_action']),
      pharmacodynamics: _parseString(json['pharmacodynamics']),
      dataSourcePharmacology: _parseString(json['data_source_pharmacology']),
      hasDrugInteraction:
          json['has_drug_interaction'] == 1 ||
          json['has_drug_interaction'] == true,
      hasFoodInteraction:
          json['has_food_interaction'] == 1 ||
          json['has_food_interaction'] == true,
      hasDiseaseInteraction:
          json['has_disease_interaction'] == 1 ||
          json['has_disease_interaction'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trade_name': tradeName,
      'arabic_name': arabicName,
      'price': price,
      'old_price': oldPrice,
      'active': active,
      'company': company,
      'dosage_form': dosageForm,
      'dosage_form_ar': dosageFormAr,
      'concentration': concentration,
      'unit': unit,
      'usage': usage,
      'category': category,
      'pharmacology': pharmacology,
      'barcode': barcode,
      'qr_code': qrCode,
      'visits': visits,
      'last_price_update': lastPriceUpdate,
      'indication': indication,
      'mechanism_of_action': mechanismOfAction,
      'pharmacodynamics': pharmacodynamics,
      'data_source_pharmacology': dataSourcePharmacology,
      'has_drug_interaction': hasDrugInteraction ? 1 : 0,
      'has_food_interaction': hasFoodInteraction ? 1 : 0,
      'has_disease_interaction': hasDiseaseInteraction ? 1 : 0,
    };
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'] as int?,
      tradeName: map['trade_name']?.toString() ?? '',
      arabicName: map['arabic_name']?.toString() ?? '',
      price: map['price']?.toString() ?? '',
      oldPrice: map['old_price']?.toString() ?? '',
      active: map['active']?.toString() ?? '',
      company: map['company']?.toString() ?? '',
      dosageForm: map['dosage_form']?.toString() ?? '',
      dosageFormAr: map['dosage_form_ar']?.toString() ?? '',
      concentration: map['concentration']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      usage: map['usage']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      pharmacology: map['pharmacology']?.toString() ?? '',
      barcode: map['barcode']?.toString() ?? '',
      qrCode: map['qr_code']?.toString() ?? '',
      visits: map['visits'] as int? ?? 0,
      lastPriceUpdate: map['last_price_update']?.toString() ?? '',
      indication: map['indication']?.toString(),
      mechanismOfAction: map['mechanism_of_action']?.toString(),
      pharmacodynamics: map['pharmacodynamics']?.toString(),
      dataSourcePharmacology: map['data_source_pharmacology']?.toString(),
      hasDrugInteraction:
          map['has_drug_interaction'] == 1 ||
          map['has_drug_interaction'] == true,
      hasFoodInteraction:
          map['has_food_interaction'] == 1 ||
          map['has_food_interaction'] == true,
      hasDiseaseInteraction:
          map['has_disease_interaction'] == 1 ||
          map['has_disease_interaction'] == true,
    );
  }

  DrugEntity toEntity() {
    // Compute isNew: added within last 7 days based on updated_at timestamp
    final isNewDrug = false;

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
      isNew: isNewDrug,
      isPopular: false, // Will be set by provider based on top 50 visits
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
      pharmacology: entity.pharmacology,
      barcode: entity.barcode,
      qrCode: entity.qrCode,
      visits: entity.visits,
      lastPriceUpdate: entity.lastPriceUpdate,
      indication: entity.indication,
      mechanismOfAction: entity.mechanismOfAction,
      pharmacodynamics: entity.pharmacodynamics,
      dataSourcePharmacology: entity.dataSourcePharmacology,
      hasDrugInteraction: entity.hasDrugInteraction,
      hasFoodInteraction: entity.hasFoodInteraction,
      hasDiseaseInteraction: entity.hasDiseaseInteraction,
    );
  }
}
