# Dose Calculator Screen Documentation
# توثيق شاشة حاسبة الجرعات

---

## 📱 نظرة عامة (Overview)

شاشة حاسبة الجرعات تتيح للمستخدم حساب الجرعة المناسبة للأدوية بناءً على وزن وعمر المريض.

**الملف:** `src/components/screens/DoseCalculatorScreen.tsx`

---

## 🏗️ الهيكل العام (Structure)

```
DoseCalculatorScreen
├── Header (Primary Gradient)
│   ├── Back Button
│   ├── Icon & Title
├── Patient Info Card
│   ├── Weight Input
│   ├── Age Input
│   └── Patient Type Badge
├── Drug Selection Card
│   └── Drug List Dropdown
├── Calculation Result
└── Disclaimer
```

---

## 🎨 المكونات التفصيلية

### 1. Header (الهيدر)

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الموضع** | `sticky top-0 z-40` |
| **الخلفية** | `bg-gradient-to-br from-primary to-primary-dark` |
| **لون النص** | `text-primary-foreground` |
| **الـ Padding** | `px-4 py-4` |

---

#### Back Button:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `p-2` |
| **الشكل** | `rounded-xl` |
| **الخلفية** | `bg-white/10` |
| **Hover** | `hover:bg-white/20` |
| **الأيقونة** | `ArrowLeft w-5 h-5` |
| **RTL** | `rotate-180` |

---

#### Icon Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-10 h-10` |
| **الشكل** | `rounded-xl` |
| **الخلفية** | `bg-white/20` |
| **الأيقونة** | `Calculator w-5 h-5` |

---

#### Title Section:
| العنصر | الخط | اللون |
|--------|------|-------|
| **العنوان** | `text-lg font-bold` | `text-primary-foreground` |
| **الوصف** | `text-xs` | `opacity-80` |

#### النصوص:
| اللغة | العنوان | الوصف |
|-------|---------|-------|
| English | "Dose Calculator" | "Calculate appropriate dose based on weight" |
| العربية | "حاسبة الجرعات" | "احسب الجرعة المناسبة بناءً على الوزن" |

---

### 2. Patient Info Card (بطاقة بيانات المريض)

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-card` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |
| **الظل** | `card-shadow` |

---

#### Header Row:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex items-center justify-between` |
| **الهامش السفلي** | `mb-4` |

##### Title:
| العنصر | التفاصيل |
|--------|----------|
| **التخطيط** | `flex items-center gap-2` |
| **الخط** | `font-semibold` |
| **اللون** | `text-foreground` |
| **الأيقونة** | `User w-4 h-4 text-primary` |

##### Reset Button:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `p-2` |
| **الشكل** | `rounded-lg` |
| **الخلفية** | `bg-muted` |
| **Hover** | `hover:bg-muted/80` |
| **الأيقونة** | `RotateCcw w-4 h-4 text-muted-foreground` |

---

#### Weight Input:
##### Label:
| العنصر | التفاصيل |
|--------|----------|
| **التخطيط** | `flex items-center gap-2` |
| **الخط** | `text-sm` |
| **اللون** | `text-muted-foreground` |
| **الأيقونة** | `Weight w-4 h-4` |

##### Input:
| الخاصية | القيمة |
|---------|--------|
| **النوع** | `number` |
| **الخط** | `text-lg` |
| **Placeholder EN** | "Enter weight..." |
| **Placeholder AR** | "أدخل الوزن..." |

---

#### Age Input:
##### Layout:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex gap-2` |

##### Input:
| الخاصية | القيمة |
|---------|--------|
| **العرض** | `flex-1` |
| **النوع** | `number` |

##### Unit Toggle:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex rounded-lg overflow-hidden` |
| **الحدود** | `border border-border` |

| الحالة | الخلفية | لون النص |
|--------|---------|----------|
| Active | `bg-primary` | `text-primary-foreground` |
| Inactive | `bg-muted` | `text-muted-foreground` |
| Hover (Inactive) | `hover:bg-muted/80` | - |

| الوحدة | EN | AR |
|--------|----|----|
| Years | "Years" | "سنة" |
| Months | "Months" | "شهر" |

---

#### Patient Type Badge:
| النوع | Variant | الأيقونة | النص EN | النص AR |
|-------|---------|----------|---------|---------|
| Pediatric | `info` | `Baby w-3 h-3` | "Pediatric" | "طفل" |
| Adult | `secondary` | `PersonStanding w-3 h-3` | "Adult" | "بالغ" |

---

### 3. Drug Selection Card

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-card` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |
| **الظل** | `card-shadow` |

---

#### Title:
| العنصر | التفاصيل |
|--------|----------|
| **التخطيط** | `flex items-center gap-2` |
| **الخط** | `font-semibold` |
| **اللون** | `text-foreground` |
| **الأيقونة** | `Pill w-4 h-4 text-primary` |

---

#### Dropdown Button:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex items-center justify-between` |
| **الـ Padding** | `p-4` |
| **الحدود** | `border border-border` |
| **الشكل** | `rounded-xl` |
| **Hover** | `hover:bg-muted/50` |

| العنصر | الخط | اللون |
|--------|------|-------|
| **النص (مختار)** | `font-medium` | `text-foreground` |
| **النص (placeholder)** | `font-medium` | `text-muted-foreground` |
| **الأيقونة** | `ChevronDown w-5 h-5` | `text-muted-foreground` |
| **الأيقونة (مفتوح)** | `rotate-180` | - |

---

#### Drug List:
| الخاصية | القيمة |
|---------|--------|
| **الهامش العلوي** | `mt-2` |
| **الارتفاع الأقصى** | `max-h-64` |
| **التمرير** | `overflow-y-auto` |
| **الحدود** | `border border-border` |
| **الشكل** | `rounded-xl` |
| **التقسيم** | `divide-y divide-border` |

##### Drug Item:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `p-4` |
| **Hover** | `hover:bg-muted/50` |
| **Selected** | `bg-primary/10` |

| العنصر | الخط | اللون |
|--------|------|-------|
| **الاسم** | `font-medium` | `text-foreground` |
| **التفاصيل** | `text-xs` | `text-muted-foreground` |

---

### 4. Calculation Result

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-gradient-to-br from-success/10 to-success/5` |
| **الحدود** | `border border-success/30` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |
| **Animation** | `animate-fade-in` |

---

#### Title:
| العنصر | التفاصيل |
|--------|----------|
| **التخطيط** | `flex items-center gap-2` |
| **الخط** | `font-semibold` |
| **اللون** | `text-success` |
| **الأيقونة** | `Calculator w-4 h-4` |

---

#### Result Display:
| العنصر | الخط | اللون |
|--------|------|-------|
| **الجرعة** | `text-4xl font-bold` | `text-success` |
| **التكرار** | `text-sm` | `text-success/80` |

#### Max Dose Badge:
| الخاصية | القيمة |
|---------|--------|
| **Variant** | `warning` |
| **الهامش العلوي** | `mt-3` |

---

#### Drug Info Section:
| الخاصية | القيمة |
|---------|--------|
| **الهامش العلوي** | `mt-4 pt-4` |
| **الحدود** | `border-t border-success/20` |
| **التخطيط** | `space-y-3` |

##### Info Row:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex justify-between` |
| **الخط** | `text-sm` |

| العنصر | اللون |
|--------|-------|
| **التسمية** | `text-muted-foreground` |
| **القيمة** | `font-medium text-foreground` |

##### Notes Box:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-background/50` |
| **الشكل** | `rounded-lg` |
| **الـ Padding** | `p-3` |
| **الهامش العلوي** | `mt-3` |

---

### 5. Disclaimer (إخلاء المسؤولية)

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-muted/50` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |
| **التخطيط** | `flex items-start gap-3` |
| **الأيقونة** | `Info w-5 h-5 text-muted-foreground` |

| العنصر | الخط | اللون |
|--------|------|-------|
| **النص** | `text-xs` | `text-muted-foreground` |

---

## 📋 Drug Data Structure

```typescript
interface DrugDosage {
  id: string;
  nameEn: string;
  nameAr: string;
  dosePerKg: number;
  maxDose: number;
  unit: string;
  frequency: string;
  frequencyAr: string;
  notes?: string;
  notesAr?: string;
}
```

### الأدوية المتاحة:
| الدواء | الجرعة/كجم | الحد الأقصى | الوحدة | التكرار |
|--------|------------|-------------|--------|---------|
| Amoxicillin | 25 | 500 | mg | every 8 hours |
| Ibuprofen | 10 | 400 | mg | every 6-8 hours |
| Paracetamol | 15 | 1000 | mg | every 4-6 hours |
| Azithromycin | 10 | 500 | mg | once daily |
| Cetirizine | 0.25 | 10 | mg | once daily |
| Metronidazole | 7.5 | 500 | mg | every 8 hours |

---

## 📐 التخطيط والمسافات

### الـ Padding الأساسي:
- الصفحة: `pb-24` (لـ Bottom Navigation)
- المحتوى: `px-4 py-4`

### الفواصل:
- بين البطاقات: `space-y-4`
- داخل البطاقات: `space-y-4`

---

## 🌐 دعم RTL (العربية)

### العناصر المتأثرة:
- `dir="rtl"` على عناصر النص
- `rotate-180` على ArrowLeft
- النصوص تتغير حسب اللغة
