# هيكلة بيانات Dormicum (نموذج مقترح)

## 🔴 الوضع الحالي (The Problem)
**البيانات:** نص واحد طويل جداً (String) يحتوي على كل شيء متداخل.
**العرض في التطبيق:** يضطر الطبيب لقراءة 200 سطر للوصول لجرعة الأطفال.

```text
DOSAGE AND ADMINISTRATION: NOTE: CONTAINS BENZYL ALCOHOL... Midazolam injection is a potent sedative... 
USUAL ADULT DOSE: For preoperative sedation... 0.07 to 0.08 mg/kg IM... 
PEDIATRIC PATIENTS: UNLIKE ADULT PATIENTS... pediatric patients generally require higher doses... 
0.1 to 0.15 mg/kg...
```

---

## 🟢 الحل المقترح (The Structure)
سيقوم الـ Parser بتقسيم النص إلى **كائنات (Objects)** منفصلة تخزن في قاعدة البيانات (أو تعرض مباشرة).

### 1. بيانات الحاسبة (Calculator Context)
هذه بيانات "خفية" تستخدمها الـ Algorithm الخاصة بالحاسبة.

```json
{
  "drug_id": 3846,
  "dose_rules": [
    {
      "category": "Pediatric",
      "indication": "Preoperative Sedation",
      "route": "IM",
      "min_dose_mg_kg": 0.08,
      "max_dose_mg_kg": 0.2, 
      "notes": "Deep IM injection"
    },
    {
      "category": "Adult",
      "indication": "Preoperative Sedation",
      "route": "IM",
      "min_dose_mg_kg": 0.07,
      "max_dose_mg_kg": 0.08,
      "duration": "1 hour before surgery"
    }
  ]
}
```

### 2. بيانات العرض (Display Context)
هذه النصوص التي ستظهر في الـ Tab الخاصة بالجرعات، مقسمة لعناوين قابلة للطي (Collapsible Headers).

**🏷️ General Considerations**
> Midazolam injection is a potent sedative agent that requires slow administration and individualization of dosage.
> ⚠️ **Warning:** Contains Benzyl Alcohol.

**👨 Usual Adult Dose**
*   **Preoperative Sedation:** 0.07 to 0.08 mg/kg IM (approx. 5 mg).
*   **Conscious Sedation:** Titrate slowly. Initial dose 1 mg to 2.5 mg IV.

**👶 Pediatric Patients**
*   **Safety Note:** Monitor closely for respiratory depression.
*   **Preoperative Sedation (IM):**
    *   Age < 6 months: Not recommended.
    *   Age 6 mo - 5 yrs: 0.05 to 0.1 mg/kg.
    *   Age 6 - 12 yrs: 0.025 to 0.05 mg/kg.
*   **IV Induction:** 0.05 to 0.2 mg/kg.

**💉 Administration & Preparation**
*   Compatible with 5% Dextrose, 0.9% Sodium Chloride.
*   Do not mix with Dimennhydrinate.

---

## كيف سنصل لهذا؟
نصوص DailyMed تتبع معيار **SPL (Structured Product Labeling)**. العناوين مثل `USUAL ADULT DOSE` و `PEDIATRIC PATIENTS` مكتوبة بأحرف كبيرة أو مسبوقة بأرقام `2.1`.
الـ Parser القادم سيعمل بمرحلتين:
1.  **Segmentation:** قص النص بناءً على العناوين الرئيسية.
2.  **Extraction:** استخراج الأرقام من كل قسم على حدة.
