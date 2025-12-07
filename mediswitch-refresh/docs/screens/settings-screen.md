# Settings Screen Documentation
# توثيق شاشة الإعدادات

---

## 📱 نظرة عامة (Overview)

شاشة الإعدادات تعرض جميع خيارات التخصيص للتطبيق مقسمة إلى أقسام منطقية.

**الملف:** `src/components/screens/SettingsScreen.tsx`

---

## 🏗️ الهيكل العام (Structure)

```
SettingsScreen
├── Header (Sticky)
│   ├── Back Button
│   ├── Settings Icon
│   └── Title
├── Settings Sections
│   ├── Notifications
│   ├── Appearance
│   ├── Sound & Haptics
│   ├── Data & Storage
│   ├── Location
│   └── About
└── Danger Zone
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
| **التخطيط** | `flex items-center gap-3` |

---

#### Back Button:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `p-2` |
| **الشكل** | `rounded-xl` |
| **الخلفية** | `bg-muted` |
| **Hover** | `hover:bg-muted/80` |
| **الأيقونة** | `ArrowLeft w-5 h-5 text-foreground` |
| **RTL** | `rotate-180` |

---

#### Icon Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-10 h-10` |
| **الشكل** | `rounded-xl` |
| **الخلفية** | `bg-primary/10` |
| **الأيقونة** | `Settings w-5 h-5 text-primary` |

---

#### Title Section:
| العنصر | الخط | اللون |
|--------|------|-------|
| **العنوان** | `text-lg font-bold` | `text-foreground` |
| **الوصف** | `text-xs` | `text-muted-foreground` |

#### النصوص:
| اللغة | العنوان | الوصف |
|-------|---------|-------|
| English | "Settings" | "Customize your experience" |
| العربية | "الإعدادات" | "تخصيص تجربتك" |

---

### 2. Settings Sections

#### Section Container:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `px-4 py-4` |
| **التخطيط** | `space-y-6` |

---

#### Section Title:
| الخاصية | القيمة |
|---------|--------|
| **الخط** | `text-sm font-semibold` |
| **اللون** | `text-muted-foreground` |
| **الهامش السفلي** | `mb-3` |
| **الـ Padding** | `px-1` |

---

#### Section Card:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-card` |
| **الشكل** | `rounded-xl` |
| **الظل** | `card-shadow` |

---

### 3. Setting Item

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الـ Padding** | `px-4 py-4` |
| **الحدود** | `border-b border-border` (ما عدا الأخير) |
| **Hover (link)** | `hover:bg-muted/50` |

---

#### Icon Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-9 h-9` |
| **الشكل** | `rounded-lg` |
| **الخلفية** | `bg-muted` |
| **الأيقونة** | `w-4 h-4 text-foreground` |

---

#### Text Content:
| العنصر | الخط | اللون |
|--------|------|-------|
| **التسمية** | `font-medium` | `text-foreground` |
| **الوصف** | `text-xs` | `text-muted-foreground` |

---

### 4. أقسام الإعدادات التفصيلية

#### Notifications (الإشعارات):
| ID | الأيقونة | النوع | Default |
|----|----------|------|---------|
| `pushNotifications` | `Bell` | Toggle | ✓ |
| `priceAlerts` | `CreditCard` | Toggle | ✓ |
| `newDrugAlerts` | `Star` | Toggle | ✗ |
| `interactionAlerts` | `Shield` | Toggle | ✓ |

#### Appearance (المظهر):
| ID | الأيقونة | النوع | Default |
|----|----------|------|---------|
| `darkMode` | `Moon` | Toggle | System |
| `language` | `Globe` | Select | English |
| `fontSize` | `FileText` | Slider | 16px |

#### Sound & Haptics (الصوت والاهتزاز):
| ID | الأيقونة | النوع | Default |
|----|----------|------|---------|
| `sounds` | `Volume2` | Toggle | ✓ |
| `haptics` | `Vibrate` | Toggle | ✓ |

#### Data & Storage (البيانات والتخزين):
| ID | الأيقونة | النوع |
|----|----------|------|
| `offlineMode` | `Download` | Toggle |
| `autoSync` | `Upload` | Toggle |
| `cacheSize` | `Database` | Link |
| `clearHistory` | `Trash2` | Link |

#### Location (الموقع):
| ID | الأيقونة | النوع | Value |
|----|----------|------|-------|
| `location` | `MapPin` | Link | Egypt / مصر |
| `currency` | `CreditCard` | Link | EGP / جنيه مصري |

#### About (حول التطبيق):
| ID | الأيقونة | النوع | Value |
|----|----------|------|-------|
| `version` | `Info` | Link | 1.0.0 |
| `terms` | `FileText` | Link | - |
| `privacy` | `Shield` | Link | - |
| `feedback` | `MessageSquare` | Link | - |
| `rate` | `Star` | Link | - |

---

### 5. Font Size Slider

#### Slider Component:
| الخاصية | القيمة |
|---------|--------|
| **الهامش العلوي** | `mt-3` |
| **الـ Padding** | `px-1` |
| **Min** | 12 |
| **Max** | 24 |
| **Step** | 1 |

#### Labels:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex justify-between` |
| **الهامش العلوي** | `mt-1` |
| **الخط** | `text-xs` |
| **اللون** | `text-muted-foreground` |

---

### 6. Danger Zone (منطقة الخطر)

#### Section Title:
| الخاصية | القيمة |
|---------|--------|
| **الخط** | `text-sm font-semibold` |
| **اللون** | `text-danger` |

#### Container:
| الخاصية | القيمة |
|---------|--------|
| **الخلفية** | `bg-danger/5` |
| **الحدود** | `border border-danger/20` |
| **الشكل** | `rounded-xl` |

---

#### Delete Button:
| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex items-center gap-3` |
| **الـ Padding** | `px-4 py-4` |
| **لون النص** | `text-danger` |
| **Hover** | `hover:bg-danger/10` |

#### Icon Container:
| الخاصية | القيمة |
|---------|--------|
| **الحجم** | `w-9 h-9` |
| **الشكل** | `rounded-lg` |
| **الخلفية** | `bg-danger/10` |
| **الأيقونة** | `Trash2 w-4 h-4` |

---

## 📐 التخطيط والمسافات

### الـ Padding الأساسي:
- الصفحة: `pb-24` (لـ Bottom Navigation)
- المحتوى: `px-4 py-4`

### الفواصل:
- بين الأقسام: `space-y-6`
- بين عناصر القسم: `border-b`

---

## 🌐 دعم RTL (العربية)

### العناصر المتأثرة:
- `dir="rtl"` على Setting Items
- `rotate-180` على ChevronRight و ArrowLeft
- النصوص تتغير حسب اللغة
