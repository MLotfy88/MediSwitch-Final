# دليل تكامل المصادر الخارجية لتطبيق MediSwitch

## المقدمة

يوفر هذا الدليل شرحاً تفصيلياً للمصادر الخارجية المستخدمة في تطبيق MediSwitch وكيفية دمجها بشكل فعال. يغطي هذا الدليل مصادر بيانات حساب الجرعات وتفاعلات الأدوية، مع خطوات التكامل التفصيلية لكل منها.

## المصادر الخارجية المجانية المتاحة

### 1. مصادر بيانات حساب الجرعات

#### RxNorm API
- **الوصف**: واجهة برمجة تطبيقات مجانية توفرها المكتبة الوطنية الأمريكية للطب، تحتوي على معلومات شاملة عن الأدوية والجرعات.
- **نوع البيانات**: معلومات الأدوية، الجرعات القياسية، أشكال الجرعات.
- **رابط الرئيسي**: [RxNorm](https://www.nlm.nih.gov/research/umls/rxnorm/index.html)
- **رابط API**: [RxNorm API](https://rxnav.nlm.nih.gov/RxNormAPIs.html)
- **طريقة الوصول**: REST API
- **مثال للاستعلام**:
  ```
  GET https://rxnav.nlm.nih.gov/REST/rxcui?name=Lipitor
  ```

#### OpenFDA API
- **الوصف**: واجهة برمجة تطبيقات مفتوحة المصدر من إدارة الغذاء والدواء الأمريكية.
- **نوع البيانات**: معلومات الأدوية، الجرعات، التحذيرات، الآثار الجانبية.
- **رابط الرئيسي**: [OpenFDA](https://open.fda.gov/)
- **رابط API**: [OpenFDA API](https://open.fda.gov/apis/)
- **طريقة الوصول**: REST API
- **مثال للاستعلام**:
  ```
  GET https://api.fda.gov/drug/label.json?search=openfda.brand_name:"Aspirin"
  ```

#### DailyMed
- **الوصف**: قاعدة بيانات رسمية للمعلومات الدوائية من المكتبة الوطنية الأمريكية للطب.
- **نوع البيانات**: نشرات الأدوية الرسمية، معلومات الجرعات، موانع الاستعمال.
- **رابط الرئيسي**: [DailyMed](https://dailymed.nlm.nih.gov/dailymed/)
- **رابط API**: [DailyMed API](https://dailymed.nlm.nih.gov/dailymed/app-support-web-services.cfm)
- **طريقة الوصول**: REST API أو تنزيل ملفات XML

### 2. مصادر بيانات تفاعلات الأدوية

#### DrugBank (النسخة المجانية للأبحاث)
- **الوصف**: قاعدة بيانات شاملة للأدوية وتفاعلاتها.
- **نوع البيانات**: تفاعلات الأدوية، الآليات، الشدة.
- **رابط الرئيسي**: [DrugBank](https://www.drugbank.ca/)
- **رابط التسجيل**: [DrugBank Registration](https://www.drugbank.ca/public_users/sign_up)
- **طريقة الوصول**: تنزيل ملفات XML للاستخدام غير التجاري.

#### NDF-RT (National Drug File - Reference Terminology)
- **الوصف**: مصطلحات مرجعية للأدوية من وزارة شؤون المحاربين القدامى الأمريكية.
- **نوع البيانات**: تصنيفات الأدوية، التفاعلات، موانع الاستعمال.
- **رابط الرئيسي**: [NDF-RT](https://www.nlm.nih.gov/research/umls/sourcereleasedocs/current/NDFRT/)
- **طريقة الوصول**: تنزيل ملفات XML أو من خلال UMLS

#### Liverpool Drug Interactions Checker
- **الوصف**: أداة مجانية للتحقق من تفاعلات الأدوية من جامعة ليفربول.
- **نوع البيانات**: تفاعلات الأدوية مع التركيز على أدوية فيروس نقص المناعة البشرية والتهاب الكبد.
- **رابط الرئيسي**: [Liverpool HIV Interactions](https://www.hiv-druginteractions.org/)
- **طريقة الوصول**: واجهة ويب (يمكن استخراج البيانات)

## دليل التكامل التفصيلي لكل مصدر

### 1. التكامل مع RxNorm API

#### خطوات التسجيل والحصول على مفتاح API
1. **التسجيل**: لا يتطلب التسجيل أو مفتاح API، فهو مجاني ومفتوح للاستخدام.
2. **حدود الاستخدام**: يوجد حد أقصى لعدد الطلبات (20 طلب في الثانية).

#### خطوات إعداد الاتصال
1. **إضافة مكتبة HTTP**: أضف مكتبة HTTP إلى مشروعك:
   ```yaml
   # في ملف pubspec.yaml
   dependencies:
     http: ^0.13.5
   ```

2. **إنشاء خدمة الاتصال**:
   ```dart
   // في ملف lib/data/sources/rxnorm_service.dart
   import 'dart:convert';
   import 'package:http/http.dart' as http;
   
   class RxNormService {
     final String baseUrl = 'https://rxnav.nlm.nih.gov/REST';
     final http.Client client;
     
     RxNormService({http.Client? client}) : this.client = client ?? http.Client();
     
     Future<Map<String, dynamic>> searchDrugByName(String name) async {
       final response = await client.get(
         Uri.parse('$baseUrl/drugs?name=$name'),
       );
       
       if (response.statusCode == 200) {
         return json.decode(response.body);
       } else {
         throw Exception('فشل في البحث عن الدواء: ${response.statusCode}');
       }
     }
     
     Future<Map<String, dynamic>> getDrugDetails(String rxcui) async {
       final response = await client.get(
         Uri.parse('$baseUrl/rxcui/$rxcui/allrelated'),
       );
       
       if (response.statusCode == 200) {
         return json.decode(response.body);
       } else {
         throw Exception('فشل في الحصول على تفاصيل الدواء: ${response.statusCode}');
       }
     }
     
     Future<Map<String, dynamic>> getDrugDosages(String rxcui) async {
       final response = await client.get(
         Uri.parse('$baseUrl/rxcui/$rxcui/allProperties?prop=attributes'),
       );
       
       if (response.statusCode == 200) {
         return json.decode(response.body);
       } else {
         throw Exception('فشل في الحصول على معلومات الجرعات: ${response.statusCode}');
       }
     }
   }
   ```

#### معالجة البيانات المستلمة
1. **إنشاء نماذج البيانات**:
   ```dart
   // في ملف lib/domain/models/drug.dart
   class Drug {
     final String id;
     final String name;
     final String? form;
     final String? strength;
     
     Drug({
       required this.id,
       required this.name,
       this.form,
       this.strength,
     });
     
     factory Drug.fromRxNorm(Map<String, dynamic> json) {
       final conceptProperties = json['conceptProperties']?[0];
       if (conceptProperties == null) {
         throw Exception('بيانات غير صالحة من RxNorm');
       }
       
       return Drug(
         id: conceptProperties['rxcui'] ?? '',
         name: conceptProperties['name'] ?? '',
         form: conceptProperties['dosageFormName'],
         strength: conceptProperties['strength'],
       );
     }
   }
   ```

2. **تنفيذ مصدر البيانات**:
   ```dart
   // في ملف lib/data/sources/rxnorm_data_source.dart
   import 'package:mediswitch/domain/models/drug.dart';
   import 'package:mediswitch/data/sources/rxnorm_service.dart';
   
   class RxNormDataSource implements DrugDataSource {
     final RxNormService _service;
     
     RxNormDataSource({RxNormService? service})
         : _service = service ?? RxNormService();
     
     @override
     Future<List<Drug>> searchDrugs(String query) async {
       final response = await _service.searchDrugByName(query);
       
       if (response['drugGroup']?['conceptGroup'] == null) {
         return [];
       }
       
       final List<dynamic> conceptGroups = response['drugGroup']['conceptGroup'];
       List<Drug> drugs = [];
       
       for (var group in conceptGroups) {
         if (group['conceptProperties'] != null) {
           for (var property in group['conceptProperties']) {
             drugs.add(Drug(
               id: property['rxcui'] ?? '',
               name: property['name'] ?? '',
               form: property['dosageFormName'],
               strength: property['strength'],
             ));
           }
         }
       }
       
       return drugs;
     }
     
     // تنفيذ باقي الطرق...
   }
   ```

### 2. التكامل مع OpenFDA API

#### خطوات التسجيل والحصول على مفتاح API
1. **التسجيل**: قم بزيارة [صفحة التسجيل في OpenFDA](https://open.fda.gov/apis/authentication/).
2. **إنشاء حساب**: انقر على "Get API Key" واملأ النموذج بمعلوماتك.
3. **تأكيد البريد الإلكتروني**: ستتلقى رسالة بريد إلكتروني للتأكيد، انقر على الرابط الموجود فيها.
4. **الحصول على مفتاح API**: بعد تأكيد البريد الإلكتروني، سيتم عرض مفتاح API الخاص بك.
5. **حدود الاستخدام**: بدون مفتاح API، يمكنك إجراء 240 طلباً في الدقيقة. مع مفتاح API، يمكنك إجراء 1200 طلب في الدقيقة.

#### خطوات إعداد الاتصال
1. **إنشاء ملف للإعدادات**:
   ```dart
   // في ملف lib/core/config/api_keys.dart
   class ApiKeys {
     static const String openFdaApiKey = 'YOUR_API_KEY_HERE';
   }
   ```

2. **إنشاء خدمة الاتصال**:
   ```dart
   // في ملف lib/data/sources/openfda_service.dart
   import 'dart:convert';
   import 'package:http/http.dart' as http;
   import 'package:mediswitch/core/config/api_keys.dart';
   
   class OpenFdaService {
     final String baseUrl = 'https://api.fda.gov';
     final String apiKey;
     final http.Client client;
     
     OpenFdaService({String? apiKey, http.Client? client})
         : this.apiKey = apiKey ?? ApiKeys.openFdaApiKey,
           this.client = client ?? http.Client();
     
     Future<Map<String, dynamic>> searchDrugByName(String name) async {
       final response = await client.get(
         Uri.parse('$baseUrl/drug/label.json?api_key=$apiKey&search=openfda.brand_name:"$name"&limit=10'),
       );
       
       if (response.statusCode == 200) {
         return json.decode(response.body);
       } else {
         throw Exception('فشل في البحث عن الدواء: ${response.statusCode}');
       }
     }
     
     Future<Map<String, dynamic>> getDrugDetails(String drugId) async {
       final response = await client.get(
         Uri.parse('$baseUrl/drug/label.json?api_key=$apiKey&search=openfda.application_number:"$drugId"'),
       );
       
       if (response.statusCode == 200) {
         return json.decode(response.body);
       } else {
         throw Exception('فشل في الحصول على تفاصيل الدواء: ${response.statusCode}');
       }
     }
     
     Future<Map<String, dynamic>> getDrugWarnings(String drugId) async {
       final response = await client.get(
         Uri.parse('$baseUrl/drug/label.json?api_key=$apiKey&search=openfda.application_number:"$drugId"&limit=1'),
       );
       
       if (response.statusCode == 200) {
         return json.decode(response.body);
       } else {
         throw Exception('فشل في الحصول على تحذيرات الدواء: ${response.statusCode}');
       }
     }
   }
   ```

#### معالجة البيانات المستلمة
1. **إنشاء نماذج البيانات**:
   ```dart
   // في ملف lib/domain/models/drug_details.dart
   class DrugDetails {
     final String id;
     final String name;
     final String? description;
     final List<String> warnings;
     final List<String> sideEffects;
     final List<String> dosageInstructions;
     
     DrugDetails({
       required this.id,
       required this.name,
       this.description,
       this.warnings = const [],
       this.sideEffects = const [],
       this.dosageInstructions = const [],
     });
     
     factory DrugDetails.fromOpenFda(Map<String, dynamic> json) {
       final results = json['results']?[0];
       if (results == null) {
         throw Exception('بيانات غير صالحة من OpenFDA');
       }
       
       final openfda = results['openfda'] ?? {};
       
       return DrugDetails(
         id: openfda['application_number']?[0] ?? '',
         name: openfda['brand_name']?[0] ?? '',
         description: results['description']?[0],
         warnings: List<String>.from(results['warnings'] ?? []),
         sideEffects: List<String>.from(results['adverse_reactions'] ?? []),
         dosageInstructions: List<String>.from(results['dosage_and_administration'] ?? []),
       );
     }
   }
   ```

2. **تنفيذ مصدر البيانات**:
   ```dart
   // في ملف lib/data/sources/openfda_data_source.dart
   import 'package:mediswitch/domain/models/drug.dart';
   import 'package:mediswitch/domain/models/drug_details.dart';
   import 'package:mediswitch/data/sources/openfda_service.dart';
   
   class OpenFdaDataSource implements DrugDataSource {
     final OpenFdaService _service;
     
     OpenFdaDataSource({OpenFdaService? service})
         : _service = service ?? OpenFdaService();
     
     @override
     Future<List<Drug>> searchDrugs(String query) async {
       final response = await _service.searchDrugByName(query);
       
       if (response['results'] == null) {
         return [];
       }
       
       final List<dynamic> results = response['results'];
       List<Drug> drugs = [];
       
       for (var result in results) {
         final openfda = result['openfda'];
         if (openfda != null) {
           drugs.add(Drug(
             id: openfda['application_number']?[0] ?? '',
             name: openfda['brand_name']?[0] ?? '',
             form: openfda['dosage_form']?[0],
             strength: openfda['route']?[0],
           ));
         }
       }
       
       return drugs;
     }
     
     @override
     Future<DrugDetails> getDrugDetails(String drugId) async {
       final response = await _service.getDrugDetails(drugId);
       return DrugDetails.fromOpenFda(response);
     }
     
     // تنفيذ باقي الطرق...
   }
   ```

### 3. التكامل مع DailyMed

#### خطوات التسجيل والحصول على مفتاح API
1. **التسجيل**: لا يتطلب التسجيل أو مفتاح API، فهو مجاني ومفتوح للاستخدام.

#### خطوات إعداد الاتصال
1. **إضافة المكتبات اللازمة**:
   ```yaml
   # في ملف pubspec.yaml
   dependencies:
     http: ^0.13.5
     xml: ^6.3.0
   ```

2. **إنشاء خدمة الاتصال**:
   ```dart
   // في ملف lib/data/sources/dailymed_service.dart
   import 'dart:convert';
   import 'package:http/http.dart' as http;
   import 'package:xml/xml.dart';
   
   class DailyMedService {
     final String baseUrl = 'https://dailymed.nlm.nih.gov/dailymed/services';
     final http.Client client;
     
     DailyMedService({http.Client? client})
         : this.client = client ?? http.Client();
     
     Future<List<Map<String, dynamic>>> searchDrugByName(String name) async {
       final response = await client.get(
         Uri.parse('$baseUrl/v2/drugnames.json?drug_name=$name'),
       );
       
       if (response.statusCode == 200) {
         final data = json.decode(response.body);
         return List<Map<String, dynamic>>.from(data['data'] ?? []);
       } else {
         throw Exception('فشل في البحث عن الدواء: ${response.statusCode}');
       }
     }
     
     Future<String> getDrugLabelXml(String setId) async {
       final response = await client.get(
         Uri.parse('$baseUrl/v2/spls/$setId.xml'),
       );
       
       if (response.statusCode == 200) {
         return response.body;
       } else {
         throw Exception('فشل في الحصول على نشرة الدواء: ${response.statusCode}');
       }
     }
     
     // استخراج معلومات الجرعات من ملف XML
     Map<String, dynamic> extractDosageInfo(String xmlString) {
       final document = XmlDocument.parse(xmlString);
       
       // استخراج معلومات الجرعات من XML
       final dosageSection = document.findAllElements('dosage').firstOrNull;
       final indicationsSection = document.findAllElements('indications').firstOrNull;
       
       return {
         'dosage': dosageSection?.innerText ?? '',
         'indications': indicationsSection?.innerText ?? '',
       };
     }
   }
   ```

#### معالجة البيانات المستلمة
1. **إنشاء نماذج البيانات**:
   ```dart
   // في ملف lib/domain/models/dosage.dart
   class Dosage {
     final String drugId;
     final String description;
     final String indications;
     
     Dosage({
       required this.drugId,
       required this.description,
       required this.indications,
     });
   }
   ```

2. **تنفيذ مصدر البيانات**:
   ```dart
   // في ملف lib/data/sources/dailymed_data_source.dart
   import 'package:mediswitch/domain/models/drug.dart';
   import 'package:mediswitch/domain/models/dosage.dart';
   import 'package:mediswitch/data/sources/dailymed_service.dart';
   
   class DailyMedDataSource implements DrugDataSource {
     final DailyMedService _service;
     
     DailyMedDataSource({DailyMedService? service})
         : _service = service ?? DailyMedService();
     
     @override
     Future<List<Drug>> searchDrugs(String query) async {
       final results = await _service.searchDrugByName(query);
       
       return results.map((result) => Drug(
         id: result['setid'] ?? '',
         name: result['drug_name'] ?? '',
       )).toList();
     }
     
     @override
     Future<List<Dosage>> getDrugDosages(String drugId) async {
       final xmlString = await _service.getDrugLabelXml(drugId);
       final dosageInfo = _service.extractDosageInfo(xmlString);
       
       return [
         Dosage(
           description: dosageInfo['dosage'] ?? '',
           indications: dosageInfo['indications'] ?? '',
           drugId: drugId,
         ),
       ];
     }
     
     // تنفيذ باقي الطرق...
   }
   ```

### 4. التكامل مع DrugBank (النسخة المجانية للأبحاث)

#### خطوات التسجيل والحصول على البيانات
1. **التسجيل**: قم بزيارة [صفحة التسجيل في DrugBank](https://www.drugbank.ca/public_users/sign_up).
2. **إنشاء حساب**: أنشئ حساباً جديداً للأبحاث باستخدام بريدك الإلكتروني المؤسسي.
3. **تأكيد البريد الإلكتروني**: انقر على رابط التأكيد في البريد الإلكتروني الذي ستتلقاه.
4. **تنزيل البيانات**: بعد تسجيل الدخول، انتقل إلى صفحة التنزيلات واختر "DrugBank Open Data" للاستخدام غير التجاري.
5. **قبول الشروط**: اقرأ واقبل شروط الاستخدام.
6. **تنزيل ملف XML**: قم بتنزيل ملف XML الذي يحتوي على بيانات الأدوية وتفاعلاتها.

#### خطوات إعداد الاتصال (باستخدام ملف XML المحلي)
1. **إضافة المكتبات اللازمة**:
   ```yaml
   # في ملف pubspec.yaml
   dependencies:
     xml: ^6.3.0
     path_provider: ^2.0.15
   ```

2. **نسخ ملف XML إلى مجلد الأصول**:
   ```yaml
   # في ملف pubspec.yaml
   flutter:
     assets:
       - assets/data/drugbank.xml
   ```

3. **إنشاء خدمة معالجة البيانات**:
   ```dart
   // في ملف lib/data/sources/drugbank_local_service.dart
   import 'dart:io';
   import 'package:flutter/services.dart';
   import 'package:path_provider/path_provider.dart';
   import 'package:xml/xml.dart';
   
   class DrugBankLocalService {
     late final XmlDocument _document;
     bool _isInitialized = false;
     
     Future<void> initialize() async {
       if (_isInitialized) return;
       
       try {
         // قراءة ملف XML من مجلد الأصول
         final xmlString = await rootBundle.loadString('assets/data/drugbank.xml');
         _document = XmlDocument.parse(xmlString);
         _isInitialized = true;
       } catch (e) {
         throw Exception('فشل في تحميل ملف DrugBank: $e');
       }
     }
     
     Future<List<Map<String, dynamic>>> searchDrugs(String query) async {
       await initialize();
       
       final drugs = _document.findAllElements('drug');
       final results = <Map<String, dynamic>>[];
       
       for (var drug in drugs) {
         final name = drug.findElements('name').firstOrNull?.innerText ?? '';
         if (name.toLowerCase().contains(query.toLowerCase())) {
           results.add({
             'id': drug.getAttribute('drugbank-id') ?? '',
             'name': name,
             'description': drug.findElements('description').firstOrNull?.innerText,
           });
         }
       }
       
       return results;
     }
     
     Future<List<Map<String, dynamic>>> getInteractions(String drugId) async {
       await initialize();
       
       final drug = _document.findAllElements('drug')
           .firstWhere((element) => element.getAttribute('drugbank-id') == drugId);
       
       final interactions = drug.findAllElements('drug-interaction');
       final results = <Map<String, dynamic>>[];
       
       for (var interaction in interactions) {
         results.add({
           'drug_id': interaction.findElements('drugbank-id').firstOrNull?.innerText ?? '',
           'name': interaction.findElements('name').firstOrNull?.innerText ?? '',
           'description': interaction.findElements('description').firstOrNull?.innerText ?? '',
         });
       }
       
       return results;
     }
   }
   ```

#### معالجة البيانات المستلمة
1. **إنشاء نماذج البيانات**:
   ```dart
   // في ملف lib/domain/models/drug_interaction.dart
   class DrugInteraction {
     final String drug1Id;
     final String drug2Id;
     final String drug2Name;
     final String description;
     final String severity;
     
     DrugInteraction({
       required this.drug1Id,
       required this.drug2Id,
       required this.drug2Name,
       required this.description,
       this.severity = 'غير معروف',
     });
   }
   ```

2. **تنفيذ مصدر البيانات**:
   ```dart
   // في ملف lib/