# Complete Documentation Index
# فهرس التوثيق الكامل

---

## 📚 ملفات التوثيق

### 🎨 نظام التصميم (Design System)

| الملف | الوصف |
|-------|-------|
| [design-system-complete.md](./design-system-complete.md) | **التوثيق الكامل لنظام التصميم** |
| ├── الألوان (Light & Dark) | جميع قيم HSL والـ HEX |
| ├── الخطوط | Inter & Cairo مع جميع الأوزان |
| ├── المسافات | جميع قيم الـ Spacing |
| ├── نصف القطر | جميع قيم Border Radius |
| ├── الظلال | جميع الـ Shadows بالتفصيل |
| ├── الحركات | Keyframes و Animations |
| └── الأيقونات | قائمة كاملة من Lucide React |

---

### 📱 الشاشات (Screens)

| الملف | الشاشة | المحتويات |
|-------|--------|-----------|
| [home-screen-complete.md](./screens/home-screen-complete.md) | الرئيسية | Header, Search, Categories, Drugs |
| [home-screen.md](./screens/home-screen.md) | الرئيسية (ملخص) | نظرة عامة |
| [drug-details-screen.md](./screens/drug-details-screen.md) | تفاصيل الدواء | Tabs, Info, Dosage, Alternatives |
| [search-results-screen.md](./screens/search-results-screen.md) | نتائج البحث | Filters, Results List |
| [favorites-screen.md](./screens/favorites-screen.md) | المفضلة | Favorites List |
| [history-screen.md](./screens/history-screen.md) | السجل | History Items |
| [profile-screen.md](./screens/profile-screen.md) | الملف الشخصي | Stats, Menu Items |
| [settings-screen.md](./screens/settings-screen.md) | الإعدادات | All Settings Sections |
| [interactions-screen.md](./screens/interactions-screen.md) | فاحص التفاعلات | Drug Selection, Results |
| [dose-calculator-screen.md](./screens/dose-calculator-screen.md) | حاسبة الجرعات | Inputs, Calculation |
| [notifications-screen.md](./screens/notifications-screen.md) | الإشعارات | Notification Types |

---

### 🧩 المكونات (Components)

| الملف | المكون | المحتويات |
|-------|--------|-----------|
| [badge-complete.md](./components/badge-complete.md) | البادج | All Variants & Sizes |
| [badge.md](./components/badge.md) | البادج (ملخص) | Quick Reference |
| [bottom-nav-complete.md](./components/bottom-nav-complete.md) | شريط التنقل | Complete Implementation |
| [bottom-nav.md](./components/bottom-nav.md) | شريط التنقل (ملخص) | Quick Reference |
| [filters-sheet-complete.md](./components/filters-sheet-complete.md) | صفحة الفلاتر | Complete Sheet Design |

---

## 📊 ملخص القياسات الأساسية

### الألوان الرئيسية (Light Mode)
| اللون | HSL | الاستخدام |
|-------|-----|-----------|
| Primary | `hsl(210, 90%, 45%)` | الأزرار، الروابط |
| Secondary | `hsl(185, 60%, 45%)` | عناصر ثانوية |
| Success | `hsl(150, 60%, 42%)` | نجاح، جديد |
| Warning | `hsl(38, 95%, 50%)` | تحذيرات |
| Danger | `hsl(0, 75%, 55%)` | أخطاء، خطورة |

### الخطوط
| اللغة | الخط | الأوزان |
|-------|------|---------|
| English | Inter | 400, 500, 600, 700 |
| العربية | Cairo | 400, 500, 600, 700 |

### الأحجام الأساسية
| العنصر | القيمة |
|--------|--------|
| عرض الجهاز | 430px |
| ارتفاع الجهاز | 800px |
| Padding الصفحة | 16px |
| Gap أساسي | 12px |
| Border Radius أساسي | 14px |

---

## 🔧 ملفات المشروع

### ملفات التكوين
| الملف | الوصف |
|-------|-------|
| `tailwind.config.ts` | تكوين Tailwind مع الألوان والخطوط |
| `src/index.css` | متغيرات CSS ونظام الألوان |
| `index.html` | Meta tags والـ Theme Color |

### ملفات المكونات الرئيسية
| الملف | الوظيفة |
|-------|---------|
| `src/components/ui/badge.tsx` | مكون البادج |
| `src/components/layout/BottomNav.tsx` | شريط التنقل |
| `src/components/layout/AppHeader.tsx` | الهيدر |
| `src/components/layout/SearchBar.tsx` | شريط البحث |
| `src/components/drugs/DrugCard.tsx` | بطاقة الدواء |
| `src/components/drugs/CategoryCard.tsx` | بطاقة التخصص |
| `src/components/drugs/DangerousDrugCard.tsx` | بطاقة الدواء الخطر |

---

## 🎯 كيفية استخدام هذا التوثيق

### لمطور Flutter:
1. ابدأ بـ `design-system-complete.md` لفهم نظام الألوان والخطوط
2. راجع `home-screen-complete.md` للقياسات الدقيقة
3. استخدم `badge-complete.md` لتنفيذ البادجات
4. استخدم `bottom-nav-complete.md` لشريط التنقل

### للتحويل إلى Flutter:
```dart
// Colors (من design-system-complete.md)
static const Color primary = Color(0xFF0D6EBC);      // hsl(210, 90%, 45%)
static const Color success = Color(0xFF2BA36F);      // hsl(150, 60%, 42%)
static const Color danger = Color(0xFFDF4545);       // hsl(0, 75%, 55%)
static const Color warning = Color(0xFFF79E0E);      // hsl(38, 95%, 50%)

// Typography
static const String fontEn = 'Inter';
static const String fontAr = 'Cairo';

// Border Radius
static const double radiusSm = 10.0;
static const double radiusMd = 12.0;
static const double radiusLg = 14.0;
static const double radiusXl = 18.0;
static const double radius2Xl = 22.0;
```

---

## ✅ Checklist للتنفيذ

- [ ] إعداد الألوان (Light & Dark)
- [ ] إعداد الخطوط (Inter & Cairo)
- [ ] إنشاء نظام المسافات
- [ ] إنشاء نظام الظلال
- [ ] إنشاء مكون Badge
- [ ] إنشاء مكون Button
- [ ] إنشاء مكون Input
- [ ] إنشاء مكون Card
- [ ] إنشاء BottomNav
- [ ] إنشاء AppHeader
- [ ] إنشاء SearchBar
- [ ] إنشاء DrugCard
- [ ] إنشاء CategoryCard
- [ ] إنشاء DangerousDrugCard
- [ ] إنشاء HomeScreen
- [ ] إنشاء SearchResultsScreen
- [ ] إنشاء DrugDetailsScreen
- [ ] إنشاء باقي الشاشات
