# متطلبات حاسبة الجرعات - المتغيرات المطلوبة
## Variables Required for Accurate Dosage Calculator

> **الهدف:** تحديد جميع المتغيرات والبيانات المطلوبة لبناء حاسبة جرعات دقيقة وآمنة

---

## 📊 المتغيرات الأساسية (Core Variables)

### 1️⃣ معلومات الدواء (Drug Information)

| Variable | Type | Example | Priority | Source |
|----------|------|---------|----------|--------|
| **Active Ingredient** | String | "Ibuprofen" | ⭐⭐⭐ Critical | OpenFDA |
| **Strength** | Number + Unit | "400 mg" | ⭐⭐⭐ Critical | OpenFDA |
| **Dose Form** | Enum | "Oral Tablet", "Injection", "Syrup" | ⭐⭐⭐ Critical | OpenFDA |
| **Concentration** | Number + Unit | "100 mg/5ml" (للشراب) | ⭐⭐ High | OpenFDA |

---

### 2️⃣ معلومات المريض (Patient Information)

| Variable | Type | Range | Priority | Used For |
|----------|------|-------|----------|----------|
| **Age** | Number (years) | 0-120 | ⭐⭐⭐ Critical | Pediatric/Geriatric dosing |
| **Weight** | Number (kg) | 2-200 | ⭐⭐⭐ Critical | mg/kg calculations |
| **Height** | Number (cm) | 40-220 | ⭐⭐ High | BSA calculations |
| **Pregnancy Status** | Boolean | Yes/No | ⭐⭐ High | Contraindications |

---

### 3️⃣ جرعات قياسية (Standard Dosing)

| Variable | Example | Priority | Notes |
|----------|---------|----------|-------|
| **Adult Standard Dose** | "400 mg" | ⭐⭐⭐ Critical | الجرعة المعتادة للبالغين |
| **Pediatric Dose (mg/kg)** | "10 mg/kg" | ⭐⭐⭐ Critical | للأطفال بناءً على الوزن |
| **Max Single Dose** | "600 mg" | ⭐⭐⭐ Critical | أقصى جرعة واحدة |
| **Max Daily Dose** | "2400 mg/day" | ⭐⭐⭐ Critical | أقصى جرعة يومية |
| **Frequency** | "Every 6 hours" | ⭐⭐⭐ Critical | تكرار الجرعة |

---

### 4️⃣ تعديلات الجرعة (Dose Adjustments)

#### أ) وظائف الكلى (Renal Function)
- Creatinine Clearance (CrCl)
- Adjustment formulas for impairment

#### ب) وظائف الكبد (Hepatic Function)
- Child-Pugh Score
- Dose reduction guidelines

---

## 🎯 مثال عملي كامل

### حالة: طفل عمره 5 سنوات، وزن 18 كجم، يحتاج Ibuprofen

```json
{
  "drug": {
    "active_ingredient": "Ibuprofen",
    "strength": "100 mg/5ml",
    "dose_form": "Oral Suspension"
  },
  
  "patient": {
    "age": 5,
    "weight_kg": 18
  },
  
  "dosing_parameters": {
    "pediatric_dose_mg_kg": 10,
    "max_single_dose_mg": 400,
    "max_daily_dose_mg": 1200,
    "frequency": "every 6-8 hours"
  },
  
  "calculation": {
    "calculated_dose_mg": 180,
    "volume_needed": "9 ml",
    "final_recommendation": "Give 9 ml orally every 6-8 hours"
  }
}
```

---

## 🔍 تقييم OpenFDA للمتغيرات المطلوبة

| Variable | Available in OpenFDA? | Quality |
|----------|----------------------|---------|
| Active Ingredient | ✅ Yes | ⭐⭐⭐ Good |
| Strength | ✅ Yes | ⭐⭐ Moderate |
| Adult Dose | ✅ Yes | ⭐⭐ Moderate |
| Pediatric Dose (mg/kg) | ⚠️ Partial | ⭐ Poor |
| Max Daily Dose | ⚠️ Partial | ⭐ Poor |
| Renal Adjustments | ❌ Rare | ⭐ Poor |
| Hepatic Adjustments | ❌ Rare | ⭐ Poor |
| Contraindications | ✅ Yes | ⭐⭐⭐ Good |
| Drug Interactions | ✅ Yes | ⭐⭐⭐ Good |

---

## 💡 التوصية النهائية

### ما هو متوفر في OpenFDA:
✅ **معلومات أساسية جيدة:**
- Active ingredients
- General dosing guidelines
- Contraindications
- Drug interactions

### ما هو ناقص/ضعيف:
❌ **بيانات سريرية دقيقة:**
- Structured pediatric dosing (mg/kg)
- Renal/Hepatic dose adjustments
- Precise frequency schedules

---

**الخلاصة:**
OpenFDA وحده **غير كافٍ** لحاسبة جرعات دقيقة (يغطي 60-70% فقط). 

**ستحتاج مصدر إضافي** للبيانات السريرية المتخصصة.
