
# 🎯 مفهوم "البطاقة المركزة" (The Focused Card Concept)

لحل مشكلة "توهان الطبيب" وسط النصوص، نقترح تطبيق **"التسلسل الهرمي للمعلومات"** (Information Hierarchy).
الفكرة هي ألا نعرض كل شيء بنفس الحجم والأهمية.

## 🆚 مقارنة عملية (Before vs After)

---

### ❌ الطريقة الحالية (The Wall of Text)
*(هكذا تبدو في النموذج السابق - النص مزدحم)*

> **📱 Adult Pre-op Sedation (IM)**
>
> The recommended premedication dose of midazolam for good risk (ASA Physical Status I & II) adult patients below the age of 60 years is 0.07 to 0.08 mg/kg IM (approximately 5 mg IM) administered up to 1 hour before surgery. The dose must be individualized and reduced when IM midazolam is administered to patients with chronic obstructive pulmonary disease, other higher risk surgical patients... (10 more lines) (Max 5 mg) ...

---

### ✅ الطريقة المقترحة: "التركيز الذكي" (Smart Focus)
*(هكذا يمكن أن تبدو بعد المعالجة - المعلومة تقفز للعين)*

> **📱 Adult Pre-op Sedation (IM)**
>
> # **0.07 - 0.08 mg/kg**
> *(Average: 5 mg)*
>
> ---
>
> ⛔ **Max Dose:** 5 mg
> ⏱️ **Timing:** 1 hr before surgery
> 💉 **Route:** Deep IM injection
>
> ---
>
> **🔽 Adjustments & Warnings (Show Details)**
> *   👴 **Geriatric (>60):** Reduce dose (use 2-3 mg).
> *   🫁 **COPD/High Risk:** Reduce dose.
> *   💊 **With Narcotics:** Reduce midazolam by 50%.
> *   *Original Text:* The recommended premedication dose... (rest of the text hidden here)

---

## 🧠 كيف سنحقق ذلك تقنياً؟

هذا يتطلب أن يقوم الـ **Parser** الخاص بنا بعمل أكثر من مجرد "نسخ ولصق". عليه أن يقوم بـ **Extraction + Formatting**:

1.  **اقتناص "الرقم البطل" (Regex):** البحث عن نمط `X to Y mg/kg` وعرضه بخط كبير.
2.  **اقتناص القيود:** البحث عن `Max X mg` وعرضه بجانب أيقونة ⛔.
3.  **التلخيص (Summarization):** البحث عن كلمات مفتاحية مثل "Geriatric" أو "Elderly" وإنشاء نقطة تنبيه 👴.
4.  **الإخفاء الذكي:** وضع النص الأصلي الكامل في قسم "قابل للتوسيع" (Expandable) للرجوع إليه عند الحاجة فقط.

**النتيجة:** الطبيب يرى الرقم الذي يحتاجه بنسبة 90% في ثانية واحدة. وإذا كان المريض "حالة خاصة" (الـ 10% الباقية)، يضغط لرؤية التفاصيل.

ما رأيك في هذا "الهيكل"؟
