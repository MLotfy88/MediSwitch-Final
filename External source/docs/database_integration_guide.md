# دليل ربط تطبيق MediSwitch بمصادر قواعد بيانات مجانية للأدوية

## مقدمة

يقدم هذا الدليل شرحًا مفصلاً لكيفية ربط تطبيق MediSwitch بمصادر قواعد بيانات مجانية توفر معلومات عن حساب الجرعات وتفاعلات الأدوية. يهدف هذا الدليل إلى مساعدة المطورين على توسيع وظائف التطبيق من خلال الاستفادة من مصادر البيانات المفتوحة والمجانية المتاحة عبر الإنترنت.

## هيكل التطبيق الحالي

يستخدم تطبيق MediSwitch حاليًا نموذج البيانات التالي:

1. **مصدر البيانات المحلي**: يعتمد على ملفات CSV محلية (`assets/meds.csv`) من خلال `CsvLocalDataSource`.
2. **مصدر البيانات البعيد**: يستخدم `DrugRemoteDataSource` للاتصال بخادم API للحصول على تحديثات البيانات.
3. **نموذج المستودع**: يستخدم `DrugRepositoryImpl` لإدارة البيانات من المصادر المختلفة.

## مصادر قواعد بيانات الأدوية المجانية

### 1. قواعد بيانات حساب الجرعات

#### أ. RxNorm API

**الوصف**: توفر RxNorm واجهة برمجة تطبيقات (API) مجانية للوصول إلى معلومات الأدوية والجرعات.

**رابط**: [RxNorm API](https://rxnav.nlm.nih.gov/RxNormAPIs.html)

**كيفية الاستخدام**:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class RxNormDataSource {
  final String baseUrl = 'https://rxnav.nlm.nih.gov/REST';
  final http.Client client;

  RxNormDataSource({required this.client});

  Future<Map<String, dynamic>> getDrugInformation(String rxcui) async {
    final url = Uri.parse('$baseUrl/rxcui/$rxcui/allrelated');
    final response = await client.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('فشل في الحصول على معلومات الدواء');
    }
  }

  Future<Map<String, dynamic>> searchDrugByName(String name) async {
    final url = Uri.parse('$baseUrl/drugs?name=$name');
    final response = await client.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('فشل في البحث عن الدواء');
    }
  }
}
```

#### ب. OpenFDA API

**الوصف**: توفر OpenFDA واجهة برمجة تطبيقات مجانية للوصول إلى معلومات الأدوية بما في ذلك الجرعات والتحذيرات.

**رابط**: [OpenFDA API](https://open.fda.gov/apis/)

**كيفية الاستخدام**:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class OpenFdaDataSource {
  final String baseUrl = 'https://api.fda.gov/drug';
  final String apiKey; // يمكن الحصول على مفتاح API مجاني من موقع OpenFDA
  final http.Client client;

  OpenFdaDataSource({required this.apiKey, required this.client});

  Future<Map<String, dynamic>> getDrugDosage(String brandName) async {
    final url = Uri.parse('$baseUrl/label.json?search=openfda.brand_name:"$brandName"&limit=1&api_key=$apiKey');
    final response = await client.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('فشل في الحصول على معلومات الجرعة');
    }
  }
}
```

### 2. قواعد بيانات تفاعلات الأدوية

#### أ. DrugBank API

**الوصف**: توفر DrugBank واجهة برمجة تطبيقات للوصول إلى معلومات تفاعلات الأدوية. تتوفر نسخة مجانية محدودة.

**رابط**: [DrugBank API](https://www.drugbank.ca/releases/latest#open-data)

**كيفية الاستخدام**:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class DrugBankDataSource {
  final String baseUrl = 'https://api.drugbank.com/v1';
  final String apiKey;
  final http.Client client;

  DrugBankDataSource({required this.apiKey, required this.client});

  Future<List<Map<String, dynamic>>> getDrugInteractions(String drugName) async {
    final url = Uri.parse('$baseUrl/drug_names?q=$drugName&api_key=$apiKey');
    final response = await client.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['drugs'].isNotEmpty) {
        final drugId = data['drugs'][0]['drugbank_id'];
        return _getInteractionsById(drugId);
      }
      return [];
    } else {
      throw Exception('فشل في البحث عن الدواء');
    }
  }

  Future<List<Map<String, dynamic>>> _getInteractionsById(String drugId) async {
    final url = Uri.parse('$baseUrl/drugs/$drugId/interactions?api_key=$apiKey');
    final response = await client.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['interactions']);
    } else {
      throw Exception('فشل في الحصول على تفاعلات الدواء');
    }
  }
}
```

#### ب. NDF-RT API (National Drug File - Reference Terminology)

**الوصف**: توفر NDF-RT واجهة برمجة تطبيقات مجانية للوصول إلى معلومات تفاعلات الأدوية.

**رابط**: [NDF-RT API](https://rxnav.nlm.nih.gov/NdfrtAPIs.html)

**كيفية الاستخدام**:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class NdfRtDataSource {
  final String baseUrl = 'https://rxnav.nlm.nih.gov/REST/ndfdrtapi';
  final http.Client client;

  NdfRtDataSource({required this.client});

  Future<List<Map<String, dynamic>>> getDrugInteractions(String ndfrtId) async {
    final url = Uri.parse('$baseUrl/interaction?ndfrtid=$ndfrtId');
    final response = await client.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['interactions'] ?? []);
    } else {
      throw Exception('فشل في الحصول على تفاعلات الدواء');
    }
  }
}
```

## دمج مصادر البيانات في تطبيق MediSwitch

### 1. إنشاء مصادر بيانات جديدة

لدمج مصادر البيانات الخارجية، يجب إنشاء فئات جديدة تنفذ واجهة `DrugRemoteDataSource`:

```dart
// lib/data/datasources/remote/rxnorm_data_source.dart
import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import 'drug_remote_data_source.dart';

class RxNormDataSourceImpl implements DrugRemoteDataSource {
  final String baseUrl = 'https://rxnav.nlm.nih.gov/REST';
  final http.Client client;

  RxNormDataSourceImpl({required this.client});

  @override
  Future<Either<Failure, Map<String, dynamic>>> getLatestVersion() async {
    // تنفيذ الحصول على أحدث إصدار من RxNorm
    // ...
  }

  @override
  Future<Either<Failure, String>> downloadLatestData() async {
    // تنفيذ تنزيل أحدث بيانات من RxNorm
    // ...
  }

  // طرق إضافية خاصة بـ RxNorm
  Future<Either<Failure, Map<String, dynamic>>> getDrugDosage(String rxcui) async {
    // ...
  }
}
```

### 2. تحديث المستودع لاستخدام مصادر البيانات المتعددة

```dart
// lib/data/repositories/drug_repository_impl.dart
import '../datasources/remote/rxnorm_data_source.dart';
import '../datasources/remote/openfda_data_source.dart';
import '../datasources/remote/drugbank_data_source.dart';

class DrugRepositoryImpl implements DrugRepository {
  final CsvLocalDataSource localDataSource;
  final DrugRemoteDataSource remoteDataSource;
  final RxNormDataSourceImpl rxNormDataSource; // مصدر بيانات RxNorm
  final OpenFdaDataSourceImpl openFdaDataSource; // مصدر بيانات OpenFDA
  final DrugBankDataSourceImpl drugBankDataSource; // مصدر بيانات DrugBank

  DrugRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.rxNormDataSource,
    required this.openFdaDataSource,
    required this.drugBankDataSource,
  });

  // طرق جديدة للحصول على معلومات الجرعات
  Future<Either<Failure, DosageResult>> calculateDosage(DrugEntity drug, double weight, int age) async {
    // محاولة الحصول على معلومات الجرعة من OpenFDA أولاً
    final openFdaResult = await openFdaDataSource.getDrugDosage(drug.tradeName);
    
    return openFdaResult.fold(
      (failure) async {
        // إذا فشل OpenFDA، جرب RxNorm
        // ...
      },
      (dosageData) {
        // معالجة بيانات الجرعة وإرجاع النتيجة
        // ...
      }
    );
  }

  // طرق جديدة للحصول على معلومات التفاعلات
  Future<Either<Failure, List<DrugInteraction>>> getDrugInteractions(List<DrugEntity> drugs) async {
    // محاولة الحصول على معلومات التفاعلات من DrugBank أولاً
    // ...
  }
}
```

### 3. إنشاء حالات استخدام جديدة

```dart
// lib/domain/usecases/calculate_drug_dosage.dart
import 'package:dartz/dartz.dart';
import '../entities/drug_entity.dart';
import '../entities/dosage_result.dart';
import '../repositories/drug_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

class CalculateDrugDosageParams {
  final DrugEntity drug;
  final double weight;
  final int age;

  CalculateDrugDosageParams({
    required this.drug,
    required this.weight,
    required this.age,
  });
}

class CalculateDrugDosage implements UseCase<DosageResult, CalculateDrugDosageParams> {
  final DrugRepository repository;

  CalculateDrugDosage(this.repository);

  @override
  Future<Either<Failure, DosageResult>> call(CalculateDrugDosageParams params) async {
    return await repository.calculateDosage(
      params.drug,
      params.weight,
      params.age,
    );
  }
}
```

```dart
// lib/domain/usecases/check_drug_interactions.dart
import 'package:dartz/dartz.dart';
import '../entities/drug_entity.dart';
import '../entities/drug_interaction.dart';
import '../repositories/drug_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

class CheckDrugInteractionsParams {
  final List<DrugEntity> drugs;

  CheckDrugInteractionsParams({required this.drugs});
}

class CheckDrugInteractions implements UseCase<List<DrugInteraction>, CheckDrugInteractionsParams> {
  final DrugRepository repository;

  CheckDrugInteractions(this.repository);

  @override
  Future<Either<Failure, List<DrugInteraction>>> call(CheckDrugInteractionsParams params) async {
    return await repository.getDrugInteractions(params.drugs);
  }
}
```

## استراتيجيات التعامل مع البيانات

### 1. التخزين المؤقت (Caching)

لتحسين الأداء وتقليل الاعتماد على الاتصال بالإنترنت، يمكن تنفيذ استراتيجية تخزين مؤقت:

```dart
// lib/data/datasources/local/drug_interaction_cache.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/drug_interaction.dart';

class DrugInteractionCache {
  final SharedPreferences sharedPreferences;
  final String cacheKey = 'cached_drug_interactions';

  DrugInteractionCache({required this.sharedPreferences});

  Future<bool> cacheInteractions(String drugId, List<DrugInteraction> interactions) async {
    final Map<String, dynamic> allCachedData = _getCachedData();
    allCachedData[drugId] = interactions.map((interaction) => interaction.toJson()).toList();
    return await sharedPreferences.setString(cacheKey, json.encode(allCachedData));
  }

  List<DrugInteraction>? getInteractions(String drugId) {
    final Map<String, dynamic> allCachedData = _getCachedData();
    if (!allCachedData.containsKey(drugId)) return null;
    
    final List<dynamic> interactionsJson = allCachedData[drugId];
    return interactionsJson.map((json) => DrugInteraction.fromJson(json)).toList();
  }

  Map<String, dynamic> _getCachedData() {
    final String? cachedString = sharedPreferences.getString(cacheKey);
    if (cachedString == null) return {};
    return json.decode(cachedString);
  }
}
```

### 2. استراتيجية الاسترجاع المتعدد (Fallback Strategy)

لضمان توفر البيانات حتى في حالة فشل بعض المصادر، يمكن تنفيذ استراتيجية استرجاع متعدد:

```dart
// في DrugRepositoryImpl
Future<Either<Failure, List<DrugInteraction>>> getDrugInteractions(List<DrugEntity> drugs) async {
  // محاولة استرداد البيانات من التخزين المؤقت أولاً
  final cachedInteractions = _getCachedInteractions(drugs);
  if (cachedInteractions.isNotEmpty) {
    return Right(cachedInteractions);
  }

  // محاولة الحصول على البيانات من DrugBank
  final drugBankResult = await _getDrugInteractionsFromDrugBank(drugs);
  
  return drugBankResult.fold(
    (failure) async {
      // إذا فشل DrugBank، جرب NDF-RT
      final ndfRtResult = await _getDrugInteractionsFromNdfRt(drugs);
      
      return ndfRtResult.fold(
        (failure) async {
          // إذا فشل NDF-RT، استخدم البيانات المحلية
          return await _getDrugInteractionsFromLocalData(drugs);
        },
        (interactions) {
          // تخزين البيانات في التخزين المؤقت وإرجاعها
          _cacheInteractions(drugs, interactions);
          return Right(interactions);
        }
      );
    },
    (interactions) {
      // تخزين البيانات في التخزين المؤقت وإرجاعها
      _cacheInteractions(drugs, interactions);
      return Right(interactions);
    }
  );
}
```

## تحديث واجهة المستخدم

بعد دمج مصادر البيانات الجديدة، يجب تحديث واجهة المستخدم لعرض المعلومات الإضافية:

### 1. شاشة حاسبة الجرعات

```dart
// lib/presentation/screens/dose_calculator_screen.dart
import '../../domain/usecases/calculate_drug_dosage.dart';

class DoseCalculatorScreen extends StatelessWidget {
  final CalculateDrugDosage calculateDrugDosage;
  
  const DoseCalculatorScreen({required this.calculateDrugDosage});
  
  // ...
}
```

### 2. شاشة فحص التفاعلات

```dart
// lib/presentation/screens/interaction_checker_screen.dart
import '../../domain/usecases/check_drug_interactions.dart';

class InteractionCheckerScreen extends StatelessWidget {
  final CheckDrugInteractions checkDrugInteractions;
  
  const InteractionCheckerScreen({required this.checkDrugInteractions});
  
  // ...
}
```

## الخلاصة

يوفر هذا الدليل إطارًا شاملاً لربط تطبيق MediSwitch بمصادر قواعد بيانات مجانية للأدوية. من خلال اتباع هذه الإرشادات، يمكن للمطورين توسيع وظائف التطبيق لتشمل حساب الجرعات وفحص تفاعلات الأدوية باستخدام بيانات موثوقة ومحدثة من مصادر متعددة.

يجب ملاحظة أن بعض واجهات برمجة التطبيقات قد تتطلب التسجيل للحصول على مفتاح API، وقد تكون هناك قيود على عدد الطلبات المسموح بها. لذلك، من المهم تنفيذ استراتيجيات التخزين المؤقت والاسترجاع المتعدد لضمان أداء التطبيق حتى في حالة وجود قيود على الوصول إلى البيانات.