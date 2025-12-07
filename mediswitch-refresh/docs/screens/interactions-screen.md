# Interactions Screen Documentation
# توثيق شاشة فاحص التفاعلات الدوائية

---

## 📱 نظرة عامة (Overview)

شاشة فاحص التفاعلات الدوائية تتيح للمستخدم إضافة أدوية متعددة والتحقق من التفاعلات المحتملة بينها.

**الملف:** `src/components/screens/InteractionsScreen.tsx`

---

## 🏗️ الهيكل العام (Structure)

```
InteractionsScreen
├── Header (Warning Gradient)
│   ├── Back Button
│   ├── Icon & Title
├── Selected Drugs Card
│   ├── Drug Tags
│   └── Add Drug Button/Search
├── Interaction Results
│   ├── No Interactions State
│   └── Interaction Cards
└── Disclaimer
```

---

## 🎨 المكونات التفصيلية

### 1. Header (الهيدر)

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الموضع** | `sticky top-0 z-40` |
| **الخلفية** | `bg-gradient-to-br from-warning/90 to-warning` |
| **لون النص** | `text-warning-foreground` |
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
| **الأيقونة** | `AlertTriangle w-5 h-5` |

---

#### Title Section:
| العنصر | الخط | اللون |
|--------|------|-------|
| **العنوان** | `text-lg font-bold` | `text-warning-foreground` |
| **الوصف** | `text-xs` | `opacity-80` |

#### النصوص:
| اللغة | العنوان | الوصف |
|-------|---------|-------|
| English | "Drug Interaction Checker" | "Add drugs to check for interactions" |
| العربية | "فاحص التفاعلات الدوائية" | "أضف الأدوية للتحقق من التفاعلات" |

---

### 2. Selected Drugs Card (بطاقة الأدوية المحددة)

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-card` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |
| **الظل** | `card-shadow` |

---

#### Section Title:
| العنصر | التفاصيل |
|--------|----------|
| **التخطيط** | `flex items-center gap-2` |
| **الخط** | `font-semibold` |
| **اللون** | `text-foreground` |
| **الأيقونة** | `Pill w-4 h-4 text-primary` |
| **البادج** | `variant="secondary" size="sm"` |

---

#### Drug Tag:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex items-center gap-2` |
| **الخلفية** | `bg-primary/10` |
| **لون النص** | `text-primary` |
| **الـ Padding** | `px-3 py-2` |
| **الشكل** | `rounded-full` |

| العنصر | التفاصيل |
|--------|----------|
| **الأيقونة** | `Pill w-4 h-4` |
| **الاسم** | `text-sm font-medium` |
| **زر الحذف** | `w-5 h-5 rounded-full bg-primary/20 hover:bg-primary/30` |
| **أيقونة الحذف** | `X w-3 h-3` |

---

#### Empty State:
| الخاصية | القيمة |
|---------|--------|
| **الخط** | `text-sm` |
| **اللون** | `text-muted-foreground` |

#### النصوص:
| اللغة | النص |
|-------|------|
| English | "No drugs selected yet" |
| العربية | "لم يتم تحديد أي أدوية بعد" |

---

### 3. Add Drug Button

#### Default State:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex items-center justify-center gap-2` |
| **الـ Padding** | `py-3` |
| **الحدود** | `border-2 border-dashed border-muted-foreground/30` |
| **الشكل** | `rounded-xl` |
| **لون النص** | `text-muted-foreground` |
| **Hover** | `hover:border-primary hover:text-primary` |
| **الأيقونة** | `Plus w-5 h-5` |

---

#### Search Mode:
##### Search Input:
| الخاصية | القيمة |
|---------|--------|
| **الأيقونة** | `Search w-4 h-4` في `absolute left-3` |
| **الـ Padding** | `pl-10` |

##### Results List:
| الخاصية | القيمة |
|---------|--------|
| **الارتفاع الأقصى** | `max-h-48` |
| **التمرير** | `overflow-y-auto` |
| **التخطيط** | `space-y-1` |

##### Result Item:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex items-center gap-2` |
| **الـ Padding** | `p-3` |
| **الشكل** | `rounded-lg` |
| **Hover** | `hover:bg-muted` |

---

### 4. Interaction Results

#### Section Title:
| العنصر | التفاصيل |
|--------|----------|
| **التخطيط** | `flex items-center gap-2` |
| **الخط** | `font-semibold` |
| **اللون** | `text-foreground` |
| **الأيقونة** | `AlertTriangle w-4 h-4 text-warning` |

---

#### No Interactions State:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-success/10` |
| **الحدود** | `border border-success/30` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |
| **التخطيط** | `flex items-center gap-3` |

##### Icon Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-10 h-10` |
| **الشكل** | `rounded-full` |
| **الخلفية** | `bg-success/20` |
| **الأيقونة** | `ShieldCheck w-5 h-5 text-success` |

##### Text:
| العنصر | الخط | اللون |
|--------|------|-------|
| **العنوان** | `font-semibold` | `text-success` |
| **الوصف** | `text-sm` | `text-success/80` |

---

### 5. Interaction Card

#### Severity Config:
| المستوى | الأيقونة | الخلفية | الحدود | لون النص |
|---------|----------|---------|--------|----------|
| `major` | `ShieldAlert` | `bg-danger/10` | `border-danger/30` | `text-danger` |
| `moderate` | `AlertCircle` | `bg-warning/10` | `border-warning/30` | `text-warning` |
| `minor` | `Info` | `bg-info/10` | `border-info/30` | `text-info` |

---

#### Card Container:
| الخاصية | القيمة |
|---------|--------|
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |

---

#### Icon Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-10 h-10` |
| **الشكل** | `rounded-full` |
| **الأيقونة** | `w-5 h-5` |

---

#### Content:
| العنصر | الخط | اللون |
|--------|------|-------|
| **أسماء الأدوية** | `font-semibold` | `text-foreground` |
| **الوصف** | `text-sm` | `text-muted-foreground` |

---

#### Recommendation Box:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-background/50` |
| **الشكل** | `rounded-lg` |
| **الـ Padding** | `p-3` |

| العنصر | الخط | اللون |
|--------|------|-------|
| **التسمية** | `text-xs font-semibold` | `text-foreground` |
| **النص** | `text-sm` | `text-muted-foreground` |

---

### 6. Disclaimer (إخلاء المسؤولية)

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

## 📐 التخطيط والمسافات

### الـ Padding الأساسي:
- الصفحة: `pb-24` (لـ Bottom Navigation)
- المحتوى: `px-4 py-4`

### الفواصل:
- بين الأقسام: `space-y-4`
- بين Drug Tags: `gap-2`
- بين نتائج التفاعلات: `space-y-3`

---

## 🌐 دعم RTL (العربية)

### العناصر المتأثرة:
- `dir="rtl"` على عناصر النص
- `rotate-180` على ArrowLeft
- النصوص تتغير حسب اللغة
