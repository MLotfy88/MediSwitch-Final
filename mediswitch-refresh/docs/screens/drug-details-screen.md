# Drug Details Screen Documentation
# توثيق شاشة تفاصيل الدواء

---

## 📱 نظرة عامة (Overview)

شاشة تفاصيل الدواء تعرض جميع المعلومات المتعلقة بدواء معين بما في ذلك المعلومات الأساسية، الجرعات، البدائل، التفاعلات، وسجل الأسعار.

**الملف:** `src/components/screens/DrugDetailsScreen.tsx`

---

## 🏗️ الهيكل العام (Structure)

```
DrugDetailsScreen
├── Hero Header (الهيدر البارز)
│   ├── Navigation & Actions
│   ├── Drug Icon & Name
│   └── Price Display
├── Tabs Navigation (التنقل بين التابات)
└── Tab Content
    ├── Info Tab (المعلومات)
    ├── Dosage Tab (الجرعات)
    ├── Alternatives Tab (البدائل)
    ├── Interactions Tab (التفاعلات)
    └── Price History Tab (سجل الأسعار)
```

---

## 🎨 المكونات التفصيلية

### 1. Hero Header (الهيدر البارز)

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-gradient-to-br from-primary via-primary to-primary-dark` |
| **لون النص** | `text-primary-foreground` |

#### Navigation Row:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex items-center justify-between` |
| **الـ Padding** | `px-4 py-3` |

##### زر الرجوع:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `p-2` |
| **الشكل** | `rounded-xl` |
| **الخلفية** | `bg-primary-foreground/10` |
| **Hover** | `hover:bg-primary-foreground/20` |
| **الأيقونة** | `ArrowLeft w-5 h-5` |

##### أزرار الإجراءات:
| الزر | الخلفية | الخلفية (نشط) | الأيقونة |
|------|---------|---------------|----------|
| **المشاركة** | `bg-primary-foreground/10` | - | `Share2 w-5 h-5` |
| **المفضلة** | `bg-primary-foreground/10` | `bg-danger` | `Heart w-5 h-5` |

---

#### Drug Info Section:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `px-4 pb-6 pt-2` |

##### Drug Icon Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-14 h-14` |
| **الشكل** | `rounded-2xl` |
| **الخلفية** | `bg-primary-foreground/10` |
| **الأيقونة** | `Pill w-7 h-7` |

##### Drug Name:
| العنصر | الخط | اللون |
|--------|------|-------|
| **الاسم الإنجليزي** | `text-2xl font-bold` | `text-primary-foreground` |
| **الاسم العربي** | `font-arabic` | `text-primary-foreground/80` |
| **الشركة** | `text-sm` | `text-primary-foreground/70` |

##### البادج:
| النوع | Variant | Size |
|-------|---------|------|
| POPULAR | `popular` | `sm` |

---

#### Price Display:
| العنصر | الخط | اللون |
|--------|------|-------|
| **السعر الحالي** | `text-3xl font-bold` | `text-primary-foreground` |
| **السعر القديم** | `text-lg line-through` | `text-primary-foreground/60` |

##### بادج الخصم:
| الخاصية | القيمة |
|---------|--------|
| **Variant** | `priceDown` |
| **الخلفية** | `bg-success/20` |
| **اللون** | `text-success-foreground` |
| **الأيقونة** | `TrendingDown w-3 h-3` |

---

### 2. Tabs Navigation (التنقل بين التابات)

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الموضع** | `sticky top-0 z-40` |
| **الخلفية** | `bg-surface` |
| **الحدود** | `border-b border-border` |
| **التخطيط** | `flex overflow-x-auto scrollbar-hide` |

#### Tab Button:
| الخاصية | القيمة (غير نشط) | القيمة (نشط) |
|---------|------------------|--------------|
| **الـ Padding** | `px-4 py-3` | `px-4 py-3` |
| **الخط** | `text-sm font-medium` | `text-sm font-medium` |
| **لون النص** | `text-muted-foreground` | `text-primary` |
| **الحدود السفلية** | `border-transparent` | `border-primary` |
| **Hover** | `hover:text-foreground` | - |

#### التابات المتاحة:
| Tab | الأيقونة | النص |
|-----|----------|------|
| Info | `Info` | Info |
| Dosage | `Droplets` | Dosage |
| Similarities | `GitCompare` | Similarities (المثائل) |
| Alternatives | `Repeat` | Alternatives (البدائل) |
| Interactions | `AlertTriangle` | Interactions |

---

### 3. Tab Content

#### Container:
```css
padding: px-4 py-4
```

---

### 3.1 Info Tab (تاب المعلومات)

#### Description Card:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-card` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |
| **الظل** | `card-shadow` |
| **Animation** | `animate-fade-in` |

| العنصر | الخط | اللون |
|--------|------|-------|
| **العنوان** | `font-semibold` | `text-foreground` |
| **الوصف** | `text-sm leading-relaxed` | `text-muted-foreground` |

---

#### Details Card:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-card` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |
| **التخطيط الداخلي** | `space-y-3` |

##### Detail Row:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex items-center gap-3` |

##### Icon Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-10 h-10` |
| **الشكل** | `rounded-xl` |
| **الخلفية** | `bg-accent` |
| **الأيقونة** | `w-5 h-5 text-primary` |

##### Detail Text:
| العنصر | الخط | اللون |
|--------|------|-------|
| **التسمية** | `text-xs` | `text-muted-foreground` |
| **القيمة** | `text-sm font-medium` | `text-foreground` |

##### التفاصيل المعروضة:
| التفصيل | الأيقونة |
|---------|----------|
| Active Ingredient | `Pill` |
| Manufacturer | `Building2` |
| Registration Number | `Hash` |

---

### 3.2 Dosage Tab (تاب الجرعات)

#### Strength Card:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-card` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |

##### Icon Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-12 h-12` |
| **الشكل** | `rounded-xl` |
| **الخلفية** | `bg-primary/10` |
| **الأيقونة** | `Droplets w-6 h-6 text-primary` |

##### Strength Text:
| العنصر | الخط | اللون |
|--------|------|-------|
| **التسمية** | `text-xs` | `text-muted-foreground` |
| **القيمة** | `text-lg font-bold` | `text-foreground` |

---

#### Dosage Details:
| العنصر | الأيقونة |
|--------|----------|
| Standard Dose | `Clock w-5 h-5` |
| Maximum Daily | `Info w-5 h-5` |

---

#### Instructions Warning:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-warning-soft` |
| **الحدود** | `border border-warning/20` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |

| العنصر | الخط | اللون |
|--------|------|-------|
| **العنوان** | `font-semibold` | `text-warning-foreground` |
| **النص** | `text-sm` | `text-warning-foreground/80` |
| **الأيقونة** | `AlertTriangle w-4 h-4` | `text-warning` |

---

### 3.3 Similarities Tab (تاب المثائل)
*(المثائل: أدوية تحتوي على نفس المادة الفعالة)*

#### Count Badge:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-accent/50` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-3` |
| **النص** | `text-sm` |

#### Similar Cards:
يستخدم نفس `DrugCard` المستخدم في الشاشة الرئيسية.

---

### 3.4 Alternatives Tab (تاب البدائل)
*(البدائل: أدوية لها نفس الاستخدام العلاجي ولكن مادة فعالة قد تكون مختلفة)*

#### Count Badge:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-accent/50` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-3` |
| **النص** | `text-sm` |

#### Alternative Cards:
يستخدم نفس `DrugCard` المستخدم في الشاشة الرئيسية.

---

### 3.5 Interactions Tab (تاب التفاعلات)

#### Warning Banner:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-danger-soft` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-3` |
| **النص** | `text-sm text-danger` |

---

#### Interaction Card:

##### ألوان الخطورة:
| المستوى | الخلفية | الحدود | لون النص |
|---------|---------|--------|----------|
| `major` | `bg-danger-soft` | `border-danger/20` | `text-danger` |
| `moderate` | `bg-warning-soft` | `border-warning/30` | `text-warning-foreground` |
| `minor` | `bg-info-soft` | `border-info/20` | `text-info` |

##### Card Structure:
| الخاصية | القيمة |
|---------|--------|
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |

| العنصر | الخط | اللون |
|--------|------|-------|
| **اسم الدواء** | `font-semibold` | `text-foreground` |
| **الوصف** | `text-sm` | `text-muted-foreground` |

##### Severity Badge:
| المستوى | Variant |
|---------|---------|
| major | `danger` |
| moderate | `warning` |
| minor | `info` |

---

### 3.5 Price History Tab (تاب سجل الأسعار)

#### History Card:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-card` |
| **الشكل** | `rounded-xl` |
| **الـ Padding** | `p-4` |
| **الظل** | `card-shadow` |

---

#### History Row:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex items-center justify-between` |
| **الـ Padding** | `py-2` |
| **الحدود** | `border-b border-border last:border-0` |

| العنصر | الخط | اللون |
|--------|------|-------|
| **التاريخ** | `text-sm` | `text-muted-foreground` |
| **السعر** | `font-semibold` | `text-foreground` |

##### Change Badge:
| التغير | Variant |
|--------|---------|
| موجب | `priceUp` |
| سالب | `priceDown` |

---

## 📐 التخطيط والمسافات

### الـ Padding الأساسي:
- محتوى التابات: `px-4 py-4`
- أسفل الصفحة: `pb-24`

### الفواصل:
- بين العناصر في التابات: `space-y-4` أو `space-y-3`
- بين أقسام البطاقة: `mb-3` أو `mb-4`

---

## 🎭 الحركات (Animations)

| العنصر | الحركة |
|--------|--------|
| Tab Content | `animate-fade-in` |
| Transition | `transition-colors` |

---

## 🔄 States (الحالات)

### Tab States:
| الحالة | التغييرات |
|--------|----------|
| Active | `border-primary text-primary` |
| Inactive | `border-transparent text-muted-foreground` |
| Hover | `hover:text-foreground` |

### Favorite Button States:
| الحالة | الخلفية | الأيقونة |
|--------|---------|----------|
| Not Favorite | `bg-primary-foreground/10` | `Heart (outline)` |
| Favorite | `bg-danger` | `Heart (filled)` |
