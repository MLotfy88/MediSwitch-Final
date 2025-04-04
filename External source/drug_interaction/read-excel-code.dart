import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class Medicine {
  final String tradeName;
  final String arabicName;
  final double oldPrice;
  final double price;
  final bool active;
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
  
  // معلومات إضافية للتفاعلات الدوائية
  final List<String> activeIngredients;
  final List<String> contraindicatedWith;
  
  Medicine({
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
    this.activeIngredients = const [],
    this.contraindicatedWith = const [],
  });
  
  factory Medicine.fromExcelRow(List<dynamic> row, List<String> headers) {
    // تحويل صف إكسل إلى كائن دواء
    Map<String, dynamic> data = {};
    
    for (int i = 0; i < headers.length; i++) {
      if (i < row.length) {
        data[headers[i]] = row[i];
      } else {
        data[headers[i]] = '';
      }
    }
    
    return Medicine(
      tradeName: data['trade_name']?.toString() ?? '',
      arabicName: data['arabic_name']?.toString() ?? '',
      oldPrice: double.tryParse(data['old_price']?.toString() ?? '0') ?? 0,
      price: double.tryParse(data['price']?.toString() ?? '0') ?? 0,
      active: data['active']?.toString().toLowerCase() == 'true',
      mainCategory: data['main_category']?.toString() ?? '',
      mainCategoryAr: data['main_category_ar']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      categoryAr: data['category_ar']?.toString() ?? '',
      company: data['company']?.toString() ?? '',
      dosageForm: data['dosage_form']?.toString() ?? '',
      dosageFormAr: data['dosage_form_ar']?.toString() ?? '',
      unit: data['unit']?.toString() ?? '',
      usage: data['usage']?.toString() ?? '',
      usageAr: data['usage_ar']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      lastPriceUpdate: data['last_price_update']?.toString() ?? '',
      // هنا يمكنك إضافة أي معلومات إضافية من قاعدة البيانات الخاصة بك
    );
  }
}

class MedicineDatabase {
  static List<Medicine> _medicines = [];
  
  static Future<void> loadMedicines() async {
    try {
      // الحصول على مسار التطبيق
      final directory = await getApplicationDocumentsDirectory();
      final excelFile = File('${directory.path}/assets/medicines_database.xlsx');
      
      // إذا لم يكن الملف موجودًا، نسخه من أصول التطبيق
      if (!await excelFile.exists()) {
        final byteData = await rootBundle.load('assets/medicines_database.xlsx');
        await excelFile.writeAsBytes(byteData.buffer.asUint8List());
      }
      
      // قراءة ملف الإكسل
      final bytes = await excelFile.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      final sheet = excel.tables.keys.first;
      final table = excel.tables[sheet]!;
      
      // قراءة رؤوس الأعمدة
      List<String> headers = [];
      for (var cell in table.rows[0]) {
        headers.add(cell?.value.toString() ?? '');
      }
      
      // قراءة بيانات الأدوية
      _medicines = [];
      for (int i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        final rowData = row.map((cell) => cell?.value).toList();
        _medicines.add(Medicine.fromExcelRow(rowData, headers));
      }
      
      print('تم تحميل ${_medicines.length} دواء من قاعدة البيانات');
    } catch (e) {
      print('خطأ في تحميل بيانات الأدوية: $e');
    }
  }
  
  static List<Medicine> getAllMedicines() {
    return _medicines;
  }
  
  static Medicine? getMedicineByName(String name) {
    try {
      return _medicines.firstWhere(
        (med) => med.tradeName.toLowerCase() == name.toLowerCase() ||
                med.arabicName.toLowerCase() == name.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }
}
