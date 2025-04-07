# توثيق مفصل لحاسبة الجرعات الدوائية

## نظرة عامة

حاسبة الجرعات الدوائية هي أداة متطورة تهدف إلى مساعدة الأطباء والصيادلة في حساب الجرعات المناسبة للأدوية الشائعة بناءً على وزن المريض وعمره. تم تصميم هذه الأداة لتكون جزءًا من تطبيق MediSwitch، وتعمل بشكل متكامل مع قاعدة بيانات الأدوية الرئيسية.

## المعادلات الطبية المستخدمة

### 1. حساب الجرعة بناءً على الوزن

هذه هي الطريقة الأساسية والأكثر دقة لحساب جرعات الأدوية، خاصة للأطفال. تستخدم المعادلة التالية:

```
الجرعة (مجم) = الوزن (كجم) × معدل الجرعة (مجم/كجم)
```

حيث يختلف معدل الجرعة حسب نوع الدواء:

| الدواء | معدل الجرعة الفردية | الحد الأقصى اليومي | فترة الجرعات |
|--------|---------------------|---------------------|---------------|
| باراسيتامول | 10-15 مجم/كجم | 60 مجم/كجم/يوم | كل 4-6 ساعات |
| إيبوبروفين | 5-10 مجم/كجم | 40 مجم/كجم/يوم | كل 6-8 ساعات |
| أموكسيسيلين | 20-40 مجم/كجم/يوم مقسمة على 3 جرعات | 90 مجم/كجم/يوم | كل 8 ساعات |

### 2. معادلة Young للأطفال

تستخدم هذه المعادلة لتقدير جرعة الطفل بناءً على جرعة البالغ وعمر الطفل:

```
جرعة الطفل = (عمر الطفل بالسنوات / (عمر الطفل بالسنوات + 12)) × جرعة البالغ
```

**مثال تطبيقي**: طفل عمره 6 سنوات، وجرعة البالغ هي 500 مجم
```
جرعة الطفل = (6 / (6 + 12)) × 500 = (6 / 18) × 500 = 0.33 × 500 = 166.67 مجم
```

### 3. معادلة Clark للأطفال

تستخدم هذه المعادلة لتقدير جرعة الطفل بناءً على وزن الطفل وجرعة البالغ:

```
جرعة الطفل = (وزن الطفل بالكيلوجرام / 70) × جرعة البالغ
```

**مثال تطبيقي**: طفل وزنه 20 كجم، وجرعة البالغ هي 500 مجم
```
جرعة الطفل = (20 / 70) × 500 = 0.286 × 500 = 143 مجم
```

### 4. حساب الجرعة باستخدام مساحة سطح الجسم (BSA)

تستخدم هذه المعادلة لتقدير جرعة الطفل بناءً على مساحة سطح الجسم:

```
جرعة الطفل = (مساحة سطح جسم الطفل / 1.73) × جرعة البالغ
```

حيث يتم حساب مساحة سطح الجسم باستخدام معادلة Mosteller:

```
BSA (م²) = √((الطول بالسنتيمتر × الوزن بالكيلوجرام) / 3600)
```

**مثال تطبيقي**: طفل طوله 120 سم ووزنه 25 كجم، وجرعة البالغ هي 500 مجم
```
BSA = √((120 × 25) / 3600) = √(3000 / 3600) = √0.833 = 0.913 م²
جرعة الطفل = (0.913 / 1.73) × 500 = 0.528 × 500 = 264 مجم
```

## خوارزميات حساب الجرعات

### خوارزمية حساب جرعة الباراسيتامول

```dart
DosageResult calculateParacetamolDosage(Medicine medicine, double weight, int age) {
  // 1. حساب الجرعة الأساسية بناءً على الوزن
  final double minDose = weight * 10; // الحد الأدنى: 10 مجم/كجم
  final double maxDose = weight * 15; // الحد الأقصى: 15 مجم/كجم
  
  // 2. تحديد الجرعة بناءً على شكل الدواء والعمر
  if (medicine.dosageForm == "tablet") {
    if (age >= 12) {
      // للبالغين والأطفال فوق 12 سنة
      return DosageResult(
        dosage: "قرص واحد (${medicine.concentration} مجم) كل 4-6 ساعات حسب الحاجة",
        notes: "الحد الأقصى: 4 أقراص في اليوم"
      );
    } else if (age >= 6) {
      // للأطفال بين 6-12 سنة
      final double tabletDose = medicine.concentration;
      final double numTablets = minDose / tabletDose;
      return DosageResult(
        dosage: "${numTablets < 0.5 ? '1/2' : (numTablets < 1 ? '3/4' : '1')} قرص كل 4-6 ساعات",
        notes: "الجرعة المحسوبة: ${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم"
      );
    } else {
      // للأطفال أقل من 6 سنوات
      return DosageResult(
        dosage: "${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم كل 4-6 ساعات",
        warning: "يفضل استخدام شراب الباراسيتامول للأطفال أقل من 6 سنوات"
      );
    }
  } else if (medicine.dosageForm == "syrup") {
    // 3. حساب حجم الشراب بناءً على التركيز (مجم/مل)
    final double minMl = (minDose / medicine.concentration);
    final double maxMl = (maxDose / medicine.concentration);
    return DosageResult(
      dosage: "${minMl.toStringAsFixed(1)}-${maxMl.toStringAsFixed(1)} مل كل 4-6 ساعات",
      notes: "الحد الأقصى: 5 جرعات في اليوم"
    );
  }
  
  // 4. إضافة تحذير للأطفال الصغار
  if (age < 2) {
    return DosageResult(
      dosage: dosage,
      warning: "تحذير: يجب استشارة الطبيب قبل إعطاء أي دواء للأطفال أقل من سنتين"
    );
  }
}
```

### خوارزمية حساب جرعة الإيبوبروفين

```dart
DosageResult calculateIbuprofenDosage(Medicine medicine, double weight, int age) {
  // 1. حساب الجرعة الأساسية بناءً على الوزن
  final double minDose = weight * 5;  // الحد الأدنى: 5 مجم/كجم
  final double maxDose = weight * 10; // الحد الأقصى: 10 مجم/كجم
  final double maxDailyDose = weight * 40; // الحد الأقصى اليومي: 40 مجم/كجم/يوم
  
  // 2. تحديد الجرعة بناءً على شكل الدواء والعمر
  if (medicine.dosageForm == "tablet") {
    if (age >= 12) {
      // للبالغين والأطفال فوق 12 سنة
      return DosageResult(
        dosage: "قرص واحد (${medicine.concentration} مجم) كل 6-8 ساعات حسب الحاجة",
        notes: "الحد الأقصى: 3 أقراص في اليوم"
      );
    } else if (age >= 6) {
      // للأطفال بين 6-12 سنة
      final double tabletDose = medicine.concentration;
      final double numTablets = minDose / tabletDose;
      return DosageResult(
        dosage: "${numTablets < 0.5 ? '1/2' : (numTablets < 1 ? '3/4' : '1')} قرص كل 6-8 ساعات",
        notes: "الجرعة المحسوبة: ${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم"
      );
    } else {
      // للأطفال أقل من 6 سنوات
      return DosageResult(
        dosage: "${minDose.toStringAsFixed(1)}-${maxDose.toStringAsFixed(1)} مجم كل 6-8 ساعات",
        warning: "يفضل استخدام شراب الإيبوبروفين للأطفال أقل من 6 سنوات"
      );
    }
  } else if (medicine.dosageForm == "syrup") {
    // 3. حساب حجم الشراب بناءً على التركيز (مجم/مل)
    final double minMl = (minDose / medicine.concentration);
    final double maxMl = (maxDose / medicine.concentration);
    return DosageResult(
      dosage: "${minMl.toStringAsFixed(1)}-${maxMl.toStringAsFixed(1)} مل كل 6-8 ساعات",
      notes: "الحد الأقصى اليومي: ${maxDailyDose.toStringAsFixed(1)} مجم"
    );
  }
  
  // 4. إضافة تحذير للأطفال الصغار
  if (age < 6) {
    return DosageResult(
      dosage: dosage,
      warning: "تحذير: يجب استشارة الطبيب قبل إعطاء الإيبوبروفين للأطفال أقل من 6 سنوات"
    );
  }
}
```

### خوارزمية حساب جرعة الأموكسيسيلين

```dart
DosageResult calculateAmoxicillinDosage(Medicine medicine, double weight, int age) {
  // 1. حساب الجرعة اليومية بناءً على الوزن
  final double dailyDose = weight * 25; // متوسط الجرعة اليومية: 25 مجم/كجم/يوم
  final double singleDose = dailyDose / 3; // الجرعة الواحدة (3 مرات يومياً)
  
  // 2. تحديد الجرعة بناءً على شكل الدواء والعمر
  if (medicine.dosageForm == "capsule") {
    if (age >= 12) {
      // للبالغين والأطفال فوق 12 سنة
      return DosageResult(
        dosage: "كبسولة واحدة (${medicine.concentration} مجم) 3 مرات يومياً",
        notes: "مدة العلاج: 7-10 أيام"
      );
    } else {
      // للأطفال أقل من 12 سنة
      return DosageResult(
        dosage: "${singleDose.toStringAsFixed(1)} مجم 3 مرات يومياً",
        warning: "يفضل استخدام شراب الأموكسيسيلين للأطفال أقل من 12 سنة",
        notes: "مدة العلاج: 7-10 أيام"
      );
    }
  } else if (medicine.dosageForm == "syrup") {
    // 3. حساب حجم الشراب بناءً على التركيز (مجم/مل)
    final double doseInMl = (singleDose / medicine.concentration);
    return DosageResult(
      dosage: "${doseInMl.toStringAsFixed(1)} مل 3 مرات يومياً",
      notes: "الجرعة اليومية الإجمالية: ${dailyDose.toStringAsFixed(1)} مجم، مدة العلاج: 7-10 أيام"
    );
  }
}
```

## هيكل البيانات

### فئة الدواء (Medicine)

```dart
class Medicine {
  final String tradeName;        // الاسم التجاري
  final String arabicName;       // الاسم العربي
  final String activeIngredient; // المادة الفعالة
  final String dosageForm;       // شكل الدواء (بالإنجليزية)
  final String dosageFormAr;     // شكل الدواء (بالعربية)
  final double concentration;    // تركيز المادة الفعالة (مجم/مل للسوائل أو مجم/قرص للأقراص)

  Medicine({
    required this.tradeName,
    required this.arabicName,
    required this.activeIngredient,
    required this.dosageForm,
    required this.dosageFormAr,
    required this.concentration,
  });
}
```

### فئة نتيجة حساب الجرعة (DosageResult)

```dart
class DosageResult {
  final String dosage;  // الجرعة المحسوبة
  final String? warning; // تحذيرات (إن وجدت)
  final String? notes;   // ملاحظات إضافية

  DosageResult({
    required this.dosage,
    this.warning,
    this.notes,
  });
}
```

## تكامل حاسبة الجرعات مع قاعدة بيانات الأدوية

لتكامل حاسبة الجرعات مع قاعدة بيانات الأدوية الرئيسية في تطبيق MediSwitch، يتم استخدام فئة `MedicineDataLoader` التي تقوم بتحميل بيانات الأدوية من ملف CSV وتحويلها إلى كائنات `Medicine`.

### خطوات التكامل:

1. **تحميل بيانات الأدوية**:
   ```dart
   List<Medicine> medicines = await MedicineDataLoader.loadMedicinesFromCsv();
   ```

2. **فلترة الأدوية المدعومة**:
   ```dart
   List<Medicine> supportedMedicines = MedicineDataLoader.filterSupportedMedicines(medicines);
   ```

3. **استخدام الأدوية في واجهة المستخدم**:
   ```dart
   // عرض الأدوية المدعومة في قائمة منسدلة
   DropdownButtonFormField<Medicine>(
     items: supportedMedicines.map((medicine) {
       return DropdownMenuItem<Medicine>(
         value: medicine,
         child: Text('${medicine.arabicName} (${medicine.tradeName}) - ${medicine.dosageFormAr} ${medicine.concentration} مجم'),
       );
     }).toList(),
     onChanged: (value) {
       setState(() {
         _selectedMedicine = value;
       });
     },
   )
   ```

4. **حساب الجرعة**:
   ```dart
   DosageResult result = DosageCalculator.calculateDosage(_selectedMedicine!, weight, age);
   ```

## تحسينات مقترحة للتنفيذ

### 1. دعم المزيد من الأدوية

يمكن توسيع نطاق حاسبة الجرعات لتشمل المزيد من الأدوية الشائعة مثل:

- أزيثرومايسين (مضاد حيوي)
- سيفالكسين (مضاد حيوي)
- ديكساميثازون (كورتيكوستيرويد)
- سالبوتامول (موسع للشعب الهوائية)
- لوراتادين (مضاد للهيستامين)

### 2. تحسين دقة الحسابات

- إضافة عوامل تصحيح للحالات الخاصة (مثل الخدج، كبار السن، أمراض الكلى والكبد)
- دعم حساب الجرعات للأدوية المركبة (التي تحتوي على أكثر من مادة فعالة)
- إضافة تحذيرات خاصة بالتفاعلات الدوائية المحتملة

### 3. تحسينات واجهة المستخدم

- إضافة رسوم بيانية توضح توزيع الجرعات على مدار اليوم
- إضافة خيار لحفظ الجرعات المحسوبة وتاريخها
- إضافة تذكيرات لمواعيد الجرعات
- دعم تصدير الجرعات المحسوبة كملف PDF

### 4. تحسينات تقنية

- تحسين أداء الخوارزميات للأجهزة منخفضة المواصفات
- تخزين مؤقت للحسابات المتكررة
- دعم وضع عدم الاتصال بالإنترنت
- إضافة اختبارات وحدة لضمان دقة الحسابات

## ملاحظات هامة للمطورين

1. **التحقق من المدخلات**: تأكد دائمًا من التحقق من صحة المدخلات (الوزن والعمر) قبل إجراء الحسابات.

2. **التقريب**: عند عرض الجرعات، قم بتقريب النتائج إلى أقرب قيمة عملية (مثلاً، تقريب 2.3 مل إلى 2.5 مل).

3. **إخلاء المسؤولية**: تأكد من عرض إخلاء مسؤولية واضح يشير إلى أن الحاسبة هي أداة مساعدة فقط ولا تغني عن استشارة الطبيب أو الصيدلي.

4. **التوثيق**: قم بتوثيق مصادر المعادلات والجرعات المستخدمة في التعليقات البرمجية.

5. **الاختبار**: قم باختبار الحاسبة مع مجموعة متنوعة من الحالات للتأكد من دقة النتائج.

## المصادر والمراجع

1. دليل BNF (British National Formulary) للأدوية
2. كتاب Pediatric & Neonatal Dosage Handbook
3. توصيات منظمة الصحة العالمية (WHO) لجرعات الأدوية للأطفال
4. قاعدة بيانات الأدوية المتوفرة في ملف `assets/meds.csv`
5. Lexicomp Drug Information Handbook
6. Micromedex Solutions
7. Epocrates