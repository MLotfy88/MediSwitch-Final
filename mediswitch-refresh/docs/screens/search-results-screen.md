# Search Results Screen Documentation
# توثيق شاشة نتائج البحث

---

## 📱 نظرة عامة (Overview)

شاشة نتائج البحث تعرض الأدوية المطابقة لاستعلام البحث مع إمكانية الفلترة والترتيب.

**الملف:** `src/components/screens/SearchResultsScreen.tsx`

---

## 🏗️ الهيكل العام (Structure)

```
SearchResultsScreen
├── Header (Sticky)
│   ├── Back Button
│   ├── SearchBar
│   └── Filter Pills
├── Results Count & Active Filters
├── Results List (DrugCards)
├── No Results State
└── Filters Sheet (Bottom Sheet)
```

---

## 🎨 المكونات التفصيلية

### 1. Header (الهيدر)

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الموضع** | `sticky top-0 z-50` |
| **الخلفية** | `bg-surface/95 backdrop-blur-lg` |
| **الحدود** | `border-b border-border` |

---

#### Navigation Row:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex items-center gap-3` |
| **الـ Padding** | `px-4 py-3` |

##### زر الرجوع:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `p-2` |
| **الشكل** | `rounded-xl` |
| **الخلفية** | `bg-accent` |
| **Hover** | `hover:bg-accent/80` |
| **الأيقونة** | `ArrowLeft w-5 h-5 text-foreground` |

##### SearchBar:
نفس مواصفات SearchBar في الشاشة الرئيسية مع `flex-1`

---

### 2. Filter Pills (فلاتر سريعة)

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `px-4 pb-3` |
| **التخطيط** | `flex gap-2 overflow-x-auto scrollbar-hide` |

#### Filter Pill Button:
| الخاصية | القيمة (غير نشط) | القيمة (نشط) |
|---------|------------------|--------------|
| **الـ Padding** | `px-4 py-2` | `px-4 py-2` |
| **الشكل** | `rounded-full` | `rounded-full` |
| **الخلفية** | `bg-accent` | `bg-primary` |
| **لون النص** | `text-foreground` | `text-primary-foreground` |
| **الخط** | `text-sm font-medium` | `text-sm font-medium` |
| **Hover** | `hover:bg-accent/80` | - |

#### الفلاتر المتاحة:
| ID | Label |
|----|-------|
| `all` | All |
| `tablet` | Tablets |
| `syrup` | Syrups |
| `injection` | Injections |
| `cream` | Creams |

---

### 3. Results Count & Active Filters

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `px-4 py-3` |
| **التخطيط** | `flex items-center justify-between` |

#### Results Count:
| العنصر | الخط | اللون |
|--------|------|-------|
| **العدد** | `font-semibold` | `text-foreground` |
| **"results"** | `text-sm` | `text-muted-foreground` |

#### Active Filters Badge:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `px-2 py-0.5` |
| **الشكل** | `rounded-full` |
| **الخلفية** | `bg-primary/10` |
| **لون النص** | `text-primary` |
| **الخط** | `text-xs font-medium` |

#### Filters Button:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex items-center gap-1` |
| **الخط** | `text-sm font-medium` |
| **اللون** | `text-primary` |
| **الأيقونة** | `SlidersHorizontal w-4 h-4` |

---

### 4. Results List

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `px-4` |
| **التخطيط** | `space-y-3` |

#### DrugCard Animation:
| الخاصية | القيمة |
|---------|--------|
| **Animation** | `animate-fade-in` |
| **التأخير** | `50ms * index` |

---

### 5. No Results State

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex flex-col items-center justify-center` |
| **الـ Padding** | `py-16 px-4` |

#### Icon Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-20 h-20` |
| **الشكل** | `rounded-full` |
| **الخلفية** | `bg-muted` |
| **الأيقونة** | `X w-10 h-10 text-muted-foreground` |

#### Text:
| العنصر | الخط | اللون |
|--------|------|-------|
| **العنوان** | `text-lg font-semibold` | `text-foreground` |
| **الوصف** | `text-sm text-center` | `text-muted-foreground` |

---

### 6. Filters Sheet (Bottom Sheet)

**الملف:** `src/components/layout/SearchFiltersSheet.tsx`

#### Filter State Structure:
```typescript
interface FilterState {
  priceRange: [number, number];  // [0, 500]
  companies: string[];
  forms: string[];
  sortBy: 'relevance' | 'price-low' | 'price-high' | 'name-az' | 'newest';
}
```

#### Sort Options:
| Value | Label |
|-------|-------|
| `relevance` | Relevance |
| `price-low` | Price: Low to High |
| `price-high` | Price: High to Low |
| `name-az` | Name: A-Z |
| `newest` | Newest First |

---

## 📐 التخطيط والمسافات

### الـ Padding الأساسي:
- الصفحة: `pb-24` (لـ Bottom Navigation)
- المحتوى: `px-4`

### الفواصل:
- بين نتائج البحث: `space-y-3`
- بين العناصر في الهيدر: `gap-3`

---

## 🎭 الحركات (Animations)

| العنصر | الحركة | التأخير |
|--------|--------|---------|
| DrugCard | `animate-fade-in` | `50ms * index` |
| Filter Transition | `transition-all` | - |

---

## 🔄 Filter Logic (منطق الفلترة)

### ترتيب تطبيق الفلاتر:
1. Form Filter (من Filter Pills)
2. Price Range Filter
3. Company Filter
4. Form Filter (من Sheet)
5. Search Query

### ترتيب النتائج:
```typescript
switch (filters.sortBy) {
  case 'price-low': // السعر من الأقل
  case 'price-high': // السعر من الأعلى
  case 'name-az': // الاسم أبجدياً
  case 'newest': // الأحدث أولاً
  default: // حسب الصلة (relevance)
}
```

---

## 🌐 دعم RTL (العربية)

### العناصر المتأثرة:
- اتجاه النصوص
- ترتيب الأزرار
- اتجاه السهم في زر الرجوع
