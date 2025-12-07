# Notifications Screen Documentation
# توثيق شاشة الإشعارات

---

## 📱 نظرة عامة (Overview)

شاشة الإشعارات تعرض جميع التنبيهات والإشعارات للمستخدم مع تصنيفها حسب النوع.

**الملف:** `src/components/screens/NotificationsScreen.tsx`

---

## 🏗️ الهيكل العام (Structure)

```
NotificationsScreen
├── Header (Sticky)
│   ├── Bell Icon & Title
│   ├── Unread Count
│   └── Mark All Read Button
└── Notifications List
    └── Notification Item
        ├── Type Icon
        ├── Title
        ├── Description
        └── Time
```

---

## 🎨 المكونات التفصيلية

### 1. Header (الهيدر)

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الموضع** | `sticky top-0 z-40` |
| **الخلفية** | `bg-surface/95 backdrop-blur-lg` |
| **الحدود** | `border-b border-border` |
| **الـ Padding** | `px-4 py-4` |
| **التخطيط** | `flex items-center justify-between` |

---

#### Icon Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-10 h-10` |
| **الشكل** | `rounded-xl` |
| **الخلفية** | `bg-primary/10` |
| **الأيقونة** | `Bell w-5 h-5 text-primary` |

---

#### Title Section:
| العنصر | الخط | اللون |
|--------|------|-------|
| **العنوان** | `text-lg font-bold` | `text-foreground` |
| **العدد غير المقروء** | `text-xs` | `text-muted-foreground` |

#### النصوص:
| اللغة | العنوان | العدد |
|-------|---------|-------|
| English | "Notifications" | "{count} unread notifications" |
| العربية | "الإشعارات" | "{count} إشعارات غير مقروءة" |

---

#### Mark All Read Button:
| الخاصية | القيمة |
|---------|--------|
| **الخط** | `text-sm font-medium` |
| **اللون** | `text-primary` |
| **الظهور** | فقط عند وجود إشعارات غير مقروءة |

#### النصوص:
| اللغة | النص |
|-------|------|
| English | "Mark all read" |
| العربية | "تحديد الكل كمقروء" |

---

### 2. Notifications List

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **التقسيم** | `divide-y divide-border` |

---

### 3. Notification Item

#### Container:
| الخاصية | القيمة (غير مقروء) | القيمة (مقروء) |
|---------|---------------------|----------------|
| **الـ Padding** | `px-4 py-4` | `px-4 py-4` |
| **التخطيط** | `flex gap-3` | `flex gap-3` |
| **الخلفية** | `bg-primary/5` | transparent |

---

#### Notification Types & Icons:
| النوع | الأيقونة | لون الخلفية | لون الأيقونة |
|-------|----------|-------------|--------------|
| `price_drop` | `TrendingDown` | `bg-success/10` | `text-success` |
| `price_up` | `TrendingUp` | `bg-danger/10` | `text-danger` |
| `new_drug` | `Pill` | `bg-primary/10` | `text-primary` |
| `interaction_alert` | `AlertTriangle` | `bg-warning/10` | `text-warning` |

---

#### Icon Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-10 h-10` |
| **الشكل** | `rounded-xl` |
| **الأيقونة** | `w-5 h-5` |

---

#### Content Section:
| العنصر | الخط | اللون |
|--------|------|-------|
| **العنوان** | `font-semibold text-sm` | `text-foreground` |
| **الوصف** | `text-sm` | `text-muted-foreground` |
| **الوقت** | `text-xs` | `text-muted-foreground` |

---

#### Unread Indicator:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-2 h-2` |
| **الشكل** | `rounded-full` |
| **الخلفية** | `bg-primary` |

---

## 📋 Notification Data Structure

```typescript
interface Notification {
  id: string;
  type: 'price_drop' | 'price_up' | 'new_drug' | 'interaction_alert';
  titleEn: string;
  titleAr: string;
  descriptionEn: string;
  descriptionAr: string;
  time: string;
  isRead: boolean;
}
```

---

## 📐 التخطيط والمسافات

### الـ Padding الأساسي:
- الصفحة: `pb-24` (لـ Bottom Navigation)
- الهيدر: `px-4 py-4`
- عنصر الإشعار: `px-4 py-4`

### الفواصل:
- بين الإشعارات: `divide-y divide-border`
- بين الأيقونة والمحتوى: `gap-3`

---

## 🌐 دعم RTL (العربية)

### العناصر المتأثرة:
- `dir="rtl"` على Notification Item
- النصوص تتغير حسب اللغة
