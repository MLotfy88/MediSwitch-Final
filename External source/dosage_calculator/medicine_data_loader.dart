// // أداة تحميل بيانات الأدوية من ملف CSV
// 
// import 'dart:convert';
// import 'package:flutter/services.dart' show rootBundle;
// import 'dosage_calculator.dart';
// 
// /// فئة مسؤولة عن تحميل بيانات الأدوية من ملف CSV
// class MedicineDataLoader {
//   /// تحميل بيانات الأدوية من ملف CSV
//   static Future<List<Medicine>> loadMedicinesFromCsv() async {
//     try {
//       // تحميل محتوى ملف CSV
//       final String rawCsv = await rootBundle.loadString('assets/meds.csv');
//       
//       // تقسيم الملف إلى أسطر
//       final List<String> lines = const LineSplitter().convert(rawCsv);
//       
//       // الحصول على أسماء الأعمدة من السطر الأول
//       final List<String> headers = _parseCsvLine(lines[0]);
//       
//       // تحويل كل سطر إلى كائن Medicine
//       final List<Medicine> medicines = [];
//       
//       // تخطي السطر الأول (العناوين) والبدء من السطر الثاني
//       for (int i = 1; i < lines.length; i++) {
//         final Map<String, String> medicineData = {};
//         final List<String> values = _parseCsvLine(lines[i]);
//         
//         // التأكد من أن عدد القيم يساوي عدد العناوين
//         if (values.length != headers.length) continue;
//         
//         // تخزين البيانات في Map
//         for (int j = 0; j < headers.length; j++) {
//           medicineData[headers[j]] = values[j];
//         }
//         
//         // إنشاء كائن Medicine فقط إذا كان يحتوي على المعلومات الضرورية
//         if (_isValidMedicine(medicineData)) {
//           try {
//             final medicine = _createMedicineFromData(medicineData);
//             medicines.add(medicine);
//           } catch (e) {
//             // تجاهل الأدوية التي تسبب أخطاء
//             print('خطأ في تحويل الدواء: $e');
//           }
//         }
//       }
//       
//       return medicines;
//     } catch (e) {
//       print('خطأ في تحميل ملف الأدوية: $e');
//       return [];
//     }
//   }
//   
//   /// تقسيم سطر CSV إلى قيم منفصلة مع مراعاة الفواصل داخل النصوص
//   static List<String> _parseCsvLine(String line) {
//     final List<String> result = [];
//     bool inQuotes = false;
//     String currentValue = '';
//     
//     for (int i = 0; i < line.length; i++) {
//       final char = line[i];
//       
//       if (char == '"') {
//         inQuotes = !inQuotes;
//       } else if (char == ',' && !inQuotes) {
//         result.add(currentValue.trim());
//         currentValue = '';
//       } else {
//         currentValue += char;
//       }
//     }
//     
//     // إضافة القيمة الأخيرة
//     result.add(currentValue.trim());
//     
//     return result;
//   }
//   
//   /// التحقق من صحة بيانات الدواء
//   static bool _isValidMedicine(Map<String, String> data) {
//     // التحقق من وجود البيانات الضرورية
//     return data.containsKey('trade_name') && 
//            data.containsKey('arabic_name') && 
//            data.containsKey('active') && 
//            data.containsKey('dosage_form') && 
//            data.containsKey('dosage_form_ar') &&
//            data['trade_name']!.isNotEmpty &&
//            data['active']!.isNotEmpty &&
//            data['dosage_form']!.isNotEmpty;
//   }
//   
//   /// إنشاء كائن Medicine من البيانات
//   static Medicine _createMedicineFromData(Map<String, String> data) {
//     // استخراج تركيز الدواء من الاسم إذا كان متاحاً
//     double concentration = 0;
//     String tradeName = data['trade_name']!;
//     
//     // محاولة استخراج التركيز من اسم الدواء
//     final RegExp concentrationRegex = RegExp(r'(\d+)\s*(?:mg|مجم|مج)');
//     final match = concentrationRegex.firstMatch(tradeName);
//     
//     if (match != null && match.groupCount >= 1) {
//       concentration = double.tryParse(match.group(1) ?? '0') ?? 0;
//     } else {
//       // تعيين قيم افتراضية للتركيز بناءً على شكل الدواء
//       if (data['dosage_form'] == 'tablet' || data['dosage_form'] == 'capsule') {
//         concentration = 500; // قيمة افتراضية للأقراص والكبسولات
//       } else if (data['dosage_form'] == 'syrup') {
//         concentration = 125; // قيمة افتراضية للشراب
//       }
//     }
//     
//     return Medicine(
//       tradeName: data['trade_name']!,
//       arabicName: data['arabic_name'] ?? tradeName,
//       activeIngredient: data['active']!,
//       dosageForm: data['dosage_form']!,
//       dosageFormAr: data['dosage_form_ar'] ?? data['dosage_form']!,
//       concentration: concentration,
//     );
//   }
//   
//   /// الحصول على قائمة الأدوية المدعومة فقط (التي يمكن حساب جرعاتها)
//   static List<Medicine> filterSupportedMedicines(List<Medicine> allMedicines) {
//     return allMedicines.where((medicine) {
//       final String active = medicine.activeIngredient.toLowerCase();
//       
//       // فلترة الأدوية التي تدعمها الحاسبة فقط
//       return active.contains('paracetamol') ||
//              active.contains('acetaminophen') ||
//              active.contains('ibuprofen') ||
//              active.contains('amoxicillin') ||
//              active.contains('pseudoephedrine');
//     }).toList();
//   }
// }