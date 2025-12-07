# Home Screen Documentation
# توثيق الشاشة الرئيسية

---

## 📱 نظرة عامة (Overview)

الشاشة الرئيسية هي نقطة الدخول الأولى للتطبيق، تعرض البحث السريع، التخصصات الطبية، الأدوية عالية الخطورة، والأدوية المضافة حديثاً.

**الملف:** `src/components/screens/HomeScreen.tsx`  
**النسخة العربية:** `src/components/screens/HomeScreenAr.tsx`

---

## 🏗️ الهيكل العام (Structure)

```
HomeScreen
├── AppHeader (الهيدر)
├── Search Section (قسم البحث)
│   ├── SearchBar
│   ├── Quick Stats (إحصائيات سريعة)
│   └── Quick Tools (أدوات سريعة)
├── Categories Section (التخصصات الطبية)
├── Dangerous Drugs Section (الأدوية عالية الخطورة)
└── Recently Added Section (المضاف حديثاً)
```

---

## 🎨 المكونات التفصيلية

### 1. App Header (الهيدر)

**الملف:** `src/components/layout/AppHeader.tsx`

#### التصميم:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-surface/95 backdrop-blur-lg` |
| **الحدود** | `border-b border-border` |
| **الـ Padding** | `px-4 py-3` |
| **الموضع** | `sticky top-0 z-50` |

#### اللوجو:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-10 h-10` (40x40px) |
| **الشكل** | `rounded-xl` |
| **الخلفية** | `bg-gradient-to-br from-primary to-primary-dark` |
| **الظل** | `shadow-md` |
| **الأيقونة** | SVG مخصص (قلب + علامة زائد) - `w-6 h-6` |
| **لون الأيقونة** | `text-primary-foreground` |

#### العنوان والتحديث:
| العنصر | الخط | اللون |
|--------|------|-------|
| **العنوان** | `text-lg font-bold` | `text-foreground` |
| **تاريخ التحديث** | `text-xs` | `text-muted-foreground` |
| **أيقونة التحديث** | `RefreshCw w-3 h-3` | `text-muted-foreground` |

#### زر الإشعارات:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `p-2.5` |
| **الشكل** | `rounded-xl` |
| **الخلفية** | `bg-accent` |
| **Hover** | `hover:bg-accent/80` |
| **الأيقونة** | `Bell w-5 h-5` |
| **البادج (العداد)** | `min-w-[18px] h-[18px] rounded-full bg-danger text-[10px] font-bold` |

---

### 2. Search Section (قسم البحث)

#### Container:
```css
padding: px-4 py-4
```

#### SearchBar Component:

**الملف:** `src/components/layout/SearchBar.tsx`

| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-card` |
| **الحدود** | `border-2 border-transparent` (افتراضي) |
| **الحدود (Focus)** | `border-primary ring-4 ring-primary/10` |
| **الشكل** | `rounded-2xl` |
| **الـ Padding** | `px-4 py-3.5` |
| **الظل** | `card-shadow` |

##### عناصر SearchBar:
| العنصر | الحجم | اللون | التفاصيل |
|--------|-------|-------|----------|
| **أيقونة البحث** | `w-5 h-5` | `text-muted-foreground` → `text-primary` (focus) | - |
| **حقل الإدخال** | `text-sm` | `text-foreground` | placeholder: `text-muted-foreground` |
| **زر الميكروفون** | `p-2 rounded-xl` | `text-muted-foreground` | `Mic w-4 h-4` |
| **الفاصل** | `w-px h-6` | `bg-border` | - |
| **زر الفلاتر** | `p-2 rounded-xl bg-primary/10` | `text-primary` | `SlidersHorizontal w-4 h-4` |

---

#### Quick Stats (إحصائيات سريعة):

| الخاصية | القيمة |
|---------|--------|
| **الموضع** | `mt-4` |
| **الخلفية** | `bg-success-soft` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `px-4 py-3` |
| **التخطيط** | `flex items-center justify-between` |

##### المحتوى:
| العنصر | التفاصيل |
|--------|----------|
| **الأيقونة** | `TrendingUp w-5 h-5 text-success` |
| **النص** | `text-sm font-medium text-success` |
| **البادج** | `variant="new" size="lg"` - النص: "+30 Drugs" |

---

#### Quick Tools (الأدوات السريعة):

| الخاصية | القيمة |
|---------|--------|
| **الموضع** | `mt-4` |
| **التخطيط** | `grid grid-cols-2 gap-3` |

##### زر التفاعلات الدوائية:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-warning/10` |
| **الحدود** | `border border-warning/20` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |
| **Hover** | `hover:bg-warning/20` |
| **الأيقونة Container** | `w-10 h-10 rounded-xl bg-warning/20` |
| **الأيقونة** | `GitCompare w-5 h-5 text-warning` |
| **العنوان** | `font-semibold text-foreground text-sm` |
| **الوصف** | `text-xs text-muted-foreground` |

##### زر حاسبة الجرعات:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-primary/10` |
| **الحدود** | `border border-primary/20` |
| **الشكل** | `rounded-xl` |
| **الأيقونة Container** | `w-10 h-10 rounded-xl bg-primary/20` |
| **الأيقونة** | `Calculator w-5 h-5 text-primary` |

---

### 3. Categories Section (التخصصات الطبية)

#### Section Header:

**الملف:** `src/components/layout/SectionHeader.tsx`

| الخاصية | القيمة |
|---------|--------|
| **العنوان** | `text-base font-semibold text-foreground` |
| **العنوان الفرعي** | `text-xs text-muted-foreground` |
| **أيقونة Container** | `w-8 h-8 rounded-lg bg-accent` |
| **أيقونة** | `Pill w-4 h-4` |
| **زر "See all"** | `text-sm font-medium text-primary` مع `ChevronRight w-4 h-4` |

#### Categories Container:
```css
margin-top: mt-3
layout: flex gap-3 overflow-x-auto scrollbar-hide
padding-bottom: pb-2
margins: -mx-4 px-4
```

#### CategoryCard:

**الملف:** `src/components/drugs/CategoryCard.tsx`

| الخاصية | القيمة |
|---------|--------|
| **العرض الأدنى** | `min-w-[88px]` |
| **الـ Padding** | `p-4` |
| **الشكل** | `rounded-2xl` |
| **التخطيط** | `flex flex-col items-center gap-2` |
| **الحركة** | `hover:scale-105 active:scale-95` |
| **Animation** | `animate-slide-in-right` مع تأخير `50ms * index` |

##### ألوان التخصصات:
| اللون | الخلفية | الأيقونة | الحدود | التخصص |
|-------|---------|----------|--------|--------|
| `red` | `bg-danger-soft` | `text-danger` | `border-danger/20` | قلب |
| `purple` | `bg-accent` | `text-primary` | `border-primary/20` | أعصاب |
| `teal` | `bg-secondary/10` | `text-secondary` | `border-secondary/20` | أسنان |
| `green` | `bg-success-soft` | `text-success` | `border-success/20` | أطفال |
| `blue` | `bg-info-soft` | `text-info` | `border-info/20` | عيون |
| `orange` | `bg-warning-soft` | `text-warning` | `border-warning/30` | عظام |

##### أيقونات التخصصات:
| التخصص | الأيقونة |
|--------|----------|
| Cardiac | `Heart` |
| Neuro | `Brain` |
| Dental | `Smile` |
| Pediatric | `Baby` |
| Ophthalmic | `Eye` |
| Orthopedic | `Bone` |

##### نصوص CategoryCard:
| العنصر | الخط | اللون |
|--------|------|-------|
| **الاسم** | `text-xs font-semibold` | `text-foreground` |
| **العدد** | `text-[10px]` | `text-muted-foreground` |

---

### 4. Dangerous Drugs Section (الأدوية عالية الخطورة)

#### Section Header:
| الخاصية | القيمة |
|---------|--------|
| **أيقونة Container** | `bg-danger-soft` |
| **أيقونة** | `AlertTriangle w-4 h-4 text-danger` |

#### DangerousDrugCard:

**الملف:** `src/components/drugs/DangerousDrugCard.tsx`

| الخاصية | القيمة |
|---------|--------|
| **العرض الأدنى** | `min-w-[140px]` |
| **الـ Padding** | `p-4` |
| **الشكل** | `rounded-2xl` |
| **التخطيط** | `flex flex-col gap-2` |
| **الحركة** | `hover:scale-[1.02] active:scale-[0.98]` |

##### مستويات الخطورة:
| المستوى | الخلفية | الحدود | أيقونة |
|---------|---------|--------|--------|
| `critical` | `bg-danger/10` | `border-danger/30` | `Skull w-5 h-5 text-danger` |
| `high` | `bg-warning-soft` | `border-warning/30` | `AlertTriangle w-5 h-5 text-warning` |

##### الأيقونة Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-10 h-10` |
| **الشكل** | `rounded-xl` |
| **الخلفية (critical)** | `bg-danger/20` |
| **الخلفية (high)** | `bg-warning/20` |

##### النصوص:
| العنصر | الخط | اللون |
|--------|------|-------|
| **الاسم (critical)** | `font-semibold text-sm` | `text-danger` |
| **الاسم (high)** | `font-semibold text-sm` | `text-warning-foreground` |
| **المادة الفعالة** | `text-xs` | `text-muted-foreground` |

##### بادج التفاعلات:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `px-2 py-1` |
| **الشكل** | `rounded-full` |
| **الخط** | `text-[10px] font-bold` |
| **أيقونة** | `AlertTriangle w-3 h-3` |

---

### 5. Recently Added Section (المضاف حديثاً)

#### Section Header:
| الخاصية | القيمة |
|---------|--------|
| **أيقونة Container** | `bg-success-soft` |
| **أيقونة** | `Sparkles w-4 h-4 text-success` |

#### DrugCard:

**الملف:** `src/components/drugs/DrugCard.tsx`

| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-card` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |
| **الظل** | `card-shadow` |
| **الحركة** | `hover:-translate-y-0.5` مع `shadow-md` |
| **Animation** | `animate-fade-in` مع تأخير `100ms * index` |

##### Header Row:
| العنصر | الخط | اللون |
|--------|------|-------|
| **الاسم التجاري** | `font-semibold` | `text-foreground` |
| **الاسم العربي/الإنجليزي** | `text-sm` | `text-muted-foreground` |

##### البادجات:
| النوع | Variant | Size |
|-------|---------|------|
| NEW | `new` | `sm` |
| POPULAR | `popular` | `sm` |

##### زر المفضلة:
| الحالة | الخلفية | اللون |
|--------|---------|-------|
| غير مفضل | `bg-muted` | `text-muted-foreground` |
| مفضل | `bg-danger-soft` | `text-danger` |
| Hover (غير مفضل) | `hover:bg-danger-soft` | `hover:text-danger` |

##### Form & Active Ingredient:
| العنصر | التفاصيل |
|--------|----------|
| **Container** | `flex items-center gap-1.5 px-2 py-1 bg-accent rounded-md` |
| **أيقونة الشكل** | `w-3.5 h-3.5 text-accent-foreground` |
| **نص الشكل** | `text-xs font-medium text-accent-foreground` |

##### السعر:
| العنصر | الخط | اللون |
|--------|------|-------|
| **السعر الحالي** | `text-xl font-bold` | `text-foreground` |
| **السعر القديم** | `text-sm line-through` | `text-muted-foreground` |

##### بادج تغير السعر:
| النوع | Variant | أيقونة |
|-------|---------|--------|
| انخفاض | `priceDown` | `TrendingDown w-3 h-3` |
| ارتفاع | `priceUp` | `TrendingUp w-3 h-3` |

##### تحذير التفاعل:
| الخاصية | القيمة |
|---------|--------|
| **Container** | `mt-3 flex items-center gap-2 px-3 py-2 bg-danger-soft rounded-lg` |
| **أيقونة** | `AlertTriangle w-4 h-4 text-danger` |
| **النص** | `text-xs font-medium text-danger` |

---

## 📐 التخطيط والمسافات

### الـ Padding الأساسي:
- الصفحة: `px-4`
- أسفل الصفحة: `pb-24` (لـ Bottom Navigation)

### الفواصل بين الأقسام:
- `mb-6` بين كل قسم

### فواصل العناصر:
- بين البطاقات في القوائم الأفقية: `gap-3`
- بين البطاقات في القوائم العمودية: `space-y-3`
- بين Section Header والمحتوى: `mt-3`

---

## 🎭 الحركات (Animations)

| العنصر | الحركة | التأخير |
|--------|--------|---------|
| CategoryCard | `animate-slide-in-right` | `50ms * index` |
| DangerousDrugCard | `animate-slide-in-right` | `50ms * index` |
| DrugCard | `animate-fade-in` | `100ms * index` |

---

## 🌐 دعم RTL (العربية)

### الاختلافات في النسخة العربية:
- `dir="rtl"` على الـ Container الرئيسي
- `flex-row-reverse` على القوائم الأفقية
- `font-arabic` على النصوص العربية
- البادجات تظهر في الاتجاه المعاكس
