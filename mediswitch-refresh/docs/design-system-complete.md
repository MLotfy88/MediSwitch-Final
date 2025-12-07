# MediSwitch - Complete Design System Documentation
# توثيق نظام التصميم الكامل - MediSwitch

---

## 📱 معلومات التطبيق الأساسية

### App Info
| الخاصية | القيمة |
|---------|--------|
| **اسم التطبيق (EN)** | MediSwitch |
| **اسم التطبيق (AR)** | ميدي سويتش |
| **الوصف** | Pharmaceutical Directory App |
| **Theme Color** | `#1a6eb5` |
| **عرض الجهاز الأقصى** | `430px` |
| **ارتفاع الجهاز الأدنى** | `800px` |

---

## 🎨 الألوان الكاملة (Complete Color System)

### Light Mode Colors

```css
/* ======================== */
/* PRIMARY - الأزرق الطبي */
/* ======================== */
--primary: 210 90% 45%;              /* hsl(210, 90%, 45%) = #0d6ebc */
--primary-light: 210 85% 55%;        /* hsl(210, 85%, 55%) = #2d8fdb */
--primary-dark: 210 95% 35%;         /* hsl(210, 95%, 35%) = #0456a0 */
--primary-foreground: 0 0% 100%;     /* hsl(0, 0%, 100%) = #ffffff */

/* ======================== */
/* BACKGROUND & SURFACE */
/* ======================== */
--background: 210 20% 98%;           /* hsl(210, 20%, 98%) = #f7f9fa */
--foreground: 215 25% 15%;           /* hsl(215, 25%, 15%) = #1c2530 */
--surface: 0 0% 100%;                /* hsl(0, 0%, 100%) = #ffffff */
--surface-elevated: 0 0% 100%;       /* hsl(0, 0%, 100%) = #ffffff */

/* ======================== */
/* CARD */
/* ======================== */
--card: 0 0% 100%;                   /* hsl(0, 0%, 100%) = #ffffff */
--card-foreground: 215 25% 15%;      /* hsl(215, 25%, 15%) = #1c2530 */

/* ======================== */
/* POPOVER */
/* ======================== */
--popover: 0 0% 100%;                /* hsl(0, 0%, 100%) = #ffffff */
--popover-foreground: 215 25% 15%;   /* hsl(215, 25%, 15%) = #1c2530 */

/* ======================== */
/* SECONDARY - تيل/أخضر مزرق */
/* ======================== */
--secondary: 185 60% 45%;            /* hsl(185, 60%, 45%) = #2eb3b8 */
--secondary-foreground: 0 0% 100%;   /* hsl(0, 0%, 100%) = #ffffff */

/* ======================== */
/* MUTED */
/* ======================== */
--muted: 210 15% 93%;                /* hsl(210, 15%, 93%) = #ebeef1 */
--muted-foreground: 215 15% 50%;     /* hsl(215, 15%, 50%) = #6e7a89 */

/* ======================== */
/* ACCENT */
/* ======================== */
--accent: 210 30% 95%;               /* hsl(210, 30%, 95%) = #eef3f8 */
--accent-foreground: 210 90% 40%;    /* hsl(210, 90%, 40%) = #0963ab */

/* ======================== */
/* DANGER - أحمر */
/* ======================== */
--danger: 0 75% 55%;                 /* hsl(0, 75%, 55%) = #df4545 */
--danger-soft: 0 70% 95%;            /* hsl(0, 70%, 95%) = #fcebeb */
--danger-foreground: 0 0% 100%;      /* hsl(0, 0%, 100%) = #ffffff */

/* ======================== */
/* WARNING - برتقالي */
/* ======================== */
--warning: 38 95% 50%;               /* hsl(38, 95%, 50%) = #f79e0e */
--warning-soft: 38 90% 95%;          /* hsl(38, 90%, 95%) = #fef6e6 */
--warning-foreground: 38 95% 20%;    /* hsl(38, 95%, 20%) = #4f3103 */

/* ======================== */
/* SUCCESS - أخضر */
/* ======================== */
--success: 150 60% 42%;              /* hsl(150, 60%, 42%) = #2ba36f */
--success-soft: 150 55% 94%;         /* hsl(150, 55%, 94%) = #e8f7ef */
--success-foreground: 0 0% 100%;     /* hsl(0, 0%, 100%) = #ffffff */

/* ======================== */
/* INFO - أزرق فاتح */
/* ======================== */
--info: 200 80% 50%;                 /* hsl(200, 80%, 50%) = #1aa3e6 */
--info-soft: 200 80% 95%;            /* hsl(200, 80%, 95%) = #e6f6fd */

/* ======================== */
/* DESTRUCTIVE */
/* ======================== */
--destructive: 0 75% 55%;            /* hsl(0, 75%, 55%) = #df4545 */
--destructive-foreground: 0 0% 100%; /* hsl(0, 0%, 100%) = #ffffff */

/* ======================== */
/* BORDER & INPUT */
/* ======================== */
--border: 210 20% 90%;               /* hsl(210, 20%, 90%) = #e3e8ec */
--input: 210 20% 90%;                /* hsl(210, 20%, 90%) = #e3e8ec */
--ring: 210 90% 45%;                 /* hsl(210, 90%, 45%) = #0d6ebc */
```

---

### Dark Mode Colors

```css
/* ======================== */
/* PRIMARY */
/* ======================== */
--primary: 210 80% 55%;              /* hsl(210, 80%, 55%) = #3a8fde */
--primary-light: 210 75% 65%;        /* hsl(210, 75%, 65%) = #66a8e8 */
--primary-dark: 210 85% 45%;         /* hsl(210, 85%, 45%) = #1171c2 */
--primary-foreground: 0 0% 100%;     /* hsl(0, 0%, 100%) = #ffffff */

/* ======================== */
/* BACKGROUND & SURFACE */
/* ======================== */
--background: 220 25% 10%;           /* hsl(220, 25%, 10%) = #141820 */
--foreground: 210 20% 95%;           /* hsl(210, 20%, 95%) = #eef1f4 */
--surface: 220 20% 14%;              /* hsl(220, 20%, 14%) = #1c222d */
--surface-elevated: 220 18% 18%;     /* hsl(220, 18%, 18%) = #262c38 */

/* ======================== */
/* CARD */
/* ======================== */
--card: 220 20% 14%;                 /* hsl(220, 20%, 14%) = #1c222d */
--card-foreground: 210 20% 95%;      /* hsl(210, 20%, 95%) = #eef1f4 */

/* ======================== */
/* POPOVER */
/* ======================== */
--popover: 220 20% 14%;              /* hsl(220, 20%, 14%) = #1c222d */
--popover-foreground: 210 20% 95%;   /* hsl(210, 20%, 95%) = #eef1f4 */

/* ======================== */
/* SECONDARY */
/* ======================== */
--secondary: 185 55% 45%;            /* hsl(185, 55%, 45%) = #33a8ad */
--secondary-foreground: 0 0% 100%;   /* hsl(0, 0%, 100%) = #ffffff */

/* ======================== */
/* MUTED */
/* ======================== */
--muted: 220 15% 20%;                /* hsl(220, 15%, 20%) = #2b303a */
--muted-foreground: 215 15% 60%;     /* hsl(215, 15%, 60%) = #8c95a3 */

/* ======================== */
/* ACCENT */
/* ======================== */
--accent: 220 20% 20%;               /* hsl(220, 20%, 20%) = #29303d */
--accent-foreground: 210 80% 60%;    /* hsl(210, 80%, 60%) = #4a9ae5 */

/* ======================== */
/* DANGER */
/* ======================== */
--danger: 0 70% 55%;                 /* hsl(0, 70%, 55%) = #d94d4d */
--danger-soft: 0 60% 18%;            /* hsl(0, 60%, 18%) = #491a1a */
--danger-foreground: 0 0% 100%;      /* hsl(0, 0%, 100%) = #ffffff */

/* ======================== */
/* WARNING */
/* ======================== */
--warning: 38 90% 50%;               /* hsl(38, 90%, 50%) = #f5a00d */
--warning-soft: 38 80% 18%;          /* hsl(38, 80%, 18%) = #533a09 */
--warning-foreground: 38 90% 90%;    /* hsl(38, 90%, 90%) = #fce7c0 */

/* ======================== */
/* SUCCESS */
/* ======================== */
--success: 150 55% 45%;              /* hsl(150, 55%, 45%) = #33a774 */
--success-soft: 150 50% 18%;         /* hsl(150, 50%, 18%) = #173625 */
--success-foreground: 0 0% 100%;     /* hsl(0, 0%, 100%) = #ffffff */

/* ======================== */
/* INFO */
/* ======================== */
--info: 200 75% 55%;                 /* hsl(200, 75%, 55%) = #3aa8de */
--info-soft: 200 70% 18%;            /* hsl(200, 70%, 18%) = #0d3347 */

/* ======================== */
/* DESTRUCTIVE */
/* ======================== */
--destructive: 0 70% 55%;            /* hsl(0, 70%, 55%) = #d94d4d */
--destructive-foreground: 0 0% 100%; /* hsl(0, 0%, 100%) = #ffffff */

/* ======================== */
/* BORDER & INPUT */
/* ======================== */
--border: 220 15% 22%;               /* hsl(220, 15%, 22%) = #303642 */
--input: 220 15% 22%;                /* hsl(220, 15%, 22%) = #303642 */
--ring: 210 80% 55%;                 /* hsl(210, 80%, 55%) = #3a8fde */
```

---

## 🔤 الخطوط (Typography)

### عائلات الخطوط (Font Families)

```css
/* Google Fonts Import */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Cairo:wght@400;500;600;700&display=swap');

/* English Text */
font-family: 'Inter', 'Cairo', system-ui, sans-serif;

/* Arabic Text */
font-family: 'Cairo', 'Inter', sans-serif;
```

### Tailwind Config:
```javascript
fontFamily: {
  sans: ['Inter', 'Cairo', 'system-ui', 'sans-serif'],
  arabic: ['Cairo', 'Inter', 'sans-serif'],
}
```

### أوزان الخطوط (Font Weights)

| الوزن | Tailwind Class | الاستخدام |
|-------|----------------|-----------|
| `400` | `font-normal` | النص العادي، الأوصاف |
| `500` | `font-medium` | العناصر التفاعلية، الروابط |
| `600` | `font-semibold` | العناوين الفرعية، التسميات |
| `700` | `font-bold` | العناوين الرئيسية، الأرقام المهمة |
| `800` | `font-extrabold` | نادر الاستخدام |

### أحجام الخطوط (Font Sizes)

| Tailwind Class | الحجم | Line Height | الاستخدام |
|----------------|-------|-------------|-----------|
| `text-[10px]` | 10px | 1 | بادجات صغيرة، أرقام البادجات |
| `text-xs` | 12px (0.75rem) | 1rem | تسميات، وقت، وصف ثانوي |
| `text-sm` | 14px (0.875rem) | 1.25rem | نص البطاقات، الأزرار الصغيرة |
| `text-base` | 16px (1rem) | 1.5rem | عناوين الأقسام |
| `text-lg` | 18px (1.125rem) | 1.75rem | عناوين الهيدر، العناوين الفرعية |
| `text-xl` | 20px (1.25rem) | 1.75rem | أسعار كبيرة، عناوين |
| `text-2xl` | 24px (1.5rem) | 2rem | اسم الدواء الرئيسي |
| `text-3xl` | 30px (1.875rem) | 2.25rem | السعر في تفاصيل الدواء |
| `text-4xl` | 36px (2.25rem) | 2.5rem | نتيجة الجرعة المحسوبة |

---

## 📏 المسافات والأحجام (Spacing & Sizing)

### نظام المسافات (Spacing System)

| Tailwind | القيمة | البكسل | الاستخدام |
|----------|--------|--------|-----------|
| `0.5` | 0.125rem | 2px | فواصل دقيقة جداً |
| `1` | 0.25rem | 4px | gap صغير، padding دقيق |
| `1.5` | 0.375rem | 6px | gap بين أيقونة ونص صغير |
| `2` | 0.5rem | 8px | padding للبادجات، فواصل صغيرة |
| `2.5` | 0.625rem | 10px | padding للأزرار الصغيرة |
| `3` | 0.75rem | 12px | gap متوسط، margin بين عناصر |
| `3.5` | 0.875rem | 14px | padding للـ Input |
| `4` | 1rem | 16px | padding الأساسي للصفحات والبطاقات |
| `5` | 1.25rem | 20px | - |
| `6` | 1.5rem | 24px | margin كبير بين الأقسام |
| `8` | 2rem | 32px | - |
| `12` | 3rem | 48px | - |
| `24` | 6rem | 96px | padding-bottom للصفحات (BottomNav) |

### نصف القطر (Border Radius)

| المتغير | القيمة | البكسل | الاستخدام |
|---------|--------|--------|-----------|
| `--radius` | 0.875rem | 14px | القيمة الأساسية |
| `rounded-sm` | calc(0.875rem - 4px) | 10px | عناصر صغيرة |
| `rounded-md` | calc(0.875rem - 2px) | 12px | عناصر متوسطة |
| `rounded-lg` | 0.875rem | 14px | البطاقات الأساسية |
| `rounded-xl` | calc(0.875rem + 4px) | 18px | البطاقات الكبيرة، الأزرار |
| `rounded-2xl` | calc(0.875rem + 8px) | 22px | البطاقات المميزة، CategoryCard |
| `rounded-3xl` | 1.5rem | 24px | - |
| `rounded-[2.5rem]` | 2.5rem | 40px | إطار الموبايل |
| `rounded-full` | 9999px | دائري | البادجات، الأزرار الدائرية |

### أحجام الأيقونات (Icon Sizes)

| Tailwind Class | البكسل | الاستخدام |
|----------------|--------|-----------|
| `w-3 h-3` | 12px | أيقونات البادجات الصغيرة جداً |
| `w-3.5 h-3.5` | 14px | أيقونات الشكل الدوائي |
| `w-4 h-4` | 16px | أيقونات القوائم، البادجات، التابات |
| `w-5 h-5` | 20px | أيقونات الأزرار، الهيدر، Bottom Nav |
| `w-6 h-6` | 24px | أيقونة اللوجو، الأيقونات الكبيرة |
| `w-7 h-7` | 28px | أيقونة الدواء في Hero |
| `w-8 h-8` | 32px | - |
| `w-10 h-10` | 40px | أيقونات الشاشات، الإشعارات |

### أحجام الحاويات (Container Sizes)

| Tailwind Class | القيمة | الاستخدام |
|----------------|--------|-----------|
| `w-9 h-9` | 36px | Menu Item Icon Container |
| `w-10 h-10` | 40px | Header Icons، Section Icons |
| `w-12 h-12` | 48px | Dosage Icon Container |
| `w-14 h-14` | 56px | Drug Icon في Hero |
| `w-16 h-16` | 64px | Avatar في Profile |
| `w-20 h-20` | 80px | Empty State Icon |
| `min-w-[88px]` | 88px | CategoryCard العرض الأدنى |
| `min-w-[140px]` | 140px | DangerousDrugCard العرض الأدنى |
| `max-w-[430px]` | 430px | عرض الجهاز الأقصى |

---

## 🌑 الظلال (Shadows)

### Light Mode Shadows

```css
/* ظل صغير - للعناصر الصغيرة */
--shadow-sm: 0 1px 2px 0 hsl(215 25% 15% / 0.04);
/* 
  offset-x: 0
  offset-y: 1px
  blur: 2px
  spread: 0
  color: rgba(28, 37, 48, 0.04)
*/

/* ظل متوسط - للـ Hover */
--shadow-md: 0 4px 12px -2px hsl(215 25% 15% / 0.08);
/*
  offset-x: 0
  offset-y: 4px
  blur: 12px
  spread: -2px
  color: rgba(28, 37, 48, 0.08)
*/

/* ظل كبير - للعناصر المرتفعة */
--shadow-lg: 0 12px 32px -4px hsl(215 25% 15% / 0.12);
/*
  offset-x: 0
  offset-y: 12px
  blur: 32px
  spread: -4px
  color: rgba(28, 37, 48, 0.12)
*/

/* ظل البطاقة - للبطاقات العادية */
--shadow-card: 0 2px 8px -2px hsl(215 25% 15% / 0.06), 
               0 0 0 1px hsl(210 20% 90% / 0.8);
/*
  Shadow 1:
    offset-x: 0
    offset-y: 2px
    blur: 8px
    spread: -2px
    color: rgba(28, 37, 48, 0.06)
  Shadow 2 (Border Effect):
    offset-x: 0
    offset-y: 0
    blur: 0
    spread: 1px
    color: rgba(227, 232, 236, 0.8)
*/
```

### Dark Mode Shadows

```css
--shadow-sm: 0 1px 2px 0 hsl(0 0% 0% / 0.2);
--shadow-md: 0 4px 12px -2px hsl(0 0% 0% / 0.3);
--shadow-lg: 0 12px 32px -4px hsl(0 0% 0% / 0.4);
--shadow-card: 0 2px 8px -2px hsl(0 0% 0% / 0.2), 
               0 0 0 1px hsl(220 15% 22%);
```

---

## 🎬 الحركات (Animations)

### Keyframes

```css
/* ======================== */
/* ACCORDION */
/* ======================== */
@keyframes accordion-down {
  from { 
    height: 0; 
  }
  to { 
    height: var(--radix-accordion-content-height); 
  }
}

@keyframes accordion-up {
  from { 
    height: var(--radix-accordion-content-height); 
  }
  to { 
    height: 0; 
  }
}

/* ======================== */
/* FADE IN */
/* ======================== */
@keyframes fade-in {
  from { 
    opacity: 0; 
    transform: translateY(8px); 
  }
  to { 
    opacity: 1; 
    transform: translateY(0); 
  }
}

/* ======================== */
/* SLIDE IN RIGHT */
/* ======================== */
@keyframes slide-in-right {
  from { 
    opacity: 0; 
    transform: translateX(20px); 
  }
  to { 
    opacity: 1; 
    transform: translateX(0); 
  }
}

/* ======================== */
/* SCALE IN */
/* ======================== */
@keyframes scale-in {
  from { 
    opacity: 0; 
    transform: scale(0.95); 
  }
  to { 
    opacity: 1; 
    transform: scale(1); 
  }
}

/* ======================== */
/* PULSE SOFT */
/* ======================== */
@keyframes pulse-soft {
  0%, 100% { 
    opacity: 1; 
  }
  50% { 
    opacity: 0.7; 
  }
}

/* ======================== */
/* SLIDE UP (للـ Bottom Sheet) */
/* ======================== */
@keyframes slide-up {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* ======================== */
/* PRICE PULSE */
/* ======================== */
@keyframes price-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}
```

### Animation Classes

```css
animation: {
  "accordion-down": "accordion-down 0.2s ease-out",
  "accordion-up": "accordion-up 0.2s ease-out",
  "fade-in": "fade-in 0.3s ease-out forwards",
  "slide-in-right": "slide-in-right 0.3s ease-out forwards",
  "scale-in": "scale-in 0.2s ease-out forwards",
  "pulse-soft": "pulse-soft 2s ease-in-out infinite",
  "slide-up": "slide-up 0.3s ease-out forwards",
  "price-pulse": "price-pulse 2s ease-in-out infinite",
}
```

### Animation Delays

```css
.delay-75 { animation-delay: 75ms; }
.delay-150 { animation-delay: 150ms; }
.delay-225 { animation-delay: 225ms; }
.delay-300 { animation-delay: 300ms; }
```

### Transition Defaults

```css
transition-all: all 0.2s ease-out;
transition-colors: color, background-color, border-color 0.2s ease;
transition-transform: transform 0.2s ease;
```

---

## 🖼️ الأيقونات (Icons)

### مكتبة الأيقونات
**Lucide React** - v0.462.0

### قائمة الأيقونات المستخدمة

#### التنقل (Navigation)
| الأيقونة | الاسم | الملف |
|----------|-------|-------|
| 🏠 | `Home` | Bottom Nav |
| 🔍 | `Search` | Bottom Nav, SearchBar |
| ⏰ | `History` | Bottom Nav |
| ❤️ | `Heart` | Bottom Nav, Favorites |
| 👤 | `User` | Bottom Nav, Profile |

#### الهيدر والأزرار
| الأيقونة | الاسم | الاستخدام |
|----------|-------|-----------|
| 🔔 | `Bell` | Notifications |
| 🔄 | `RefreshCw` | Last Updated |
| ⬅️ | `ArrowLeft` | Back Button |
| ➡️ | `ChevronRight` | See All, Menu Items |
| ⬅️ | `ChevronLeft` | See All (RTL) |
| ⬇️ | `ChevronDown` | Dropdowns |
| ❌ | `X` | Close, Remove |
| ✓ | `Check` | Selected State |
| ➕ | `Plus` | Add |

#### الأدوية
| الأيقونة | الاسم | الاستخدام |
|----------|-------|-----------|
| 💊 | `Pill` | Drug Form, Categories |
| 💧 | `Droplets` | Syrup Form, Dosage |
| 💉 | `Syringe` | Injection Form |

#### التخصصات الطبية
| الأيقونة | الاسم | التخصص |
|----------|-------|--------|
| ❤️ | `Heart` | Cardiac |
| 🧠 | `Brain` | Neuro |
| 👁️ | `Eye` | Ophthalmic |
| 🦴 | `Bone` | Orthopedic |
| 👶 | `Baby` | Pediatric |
| 😊 | `Smile` | Dental |

#### التحذيرات والحالات
| الأيقونة | الاسم | الاستخدام |
|----------|-------|-----------|
| ⚠️ | `AlertTriangle` | Warning, Interactions |
| 💀 | `Skull` | Critical Risk |
| 🛡️ | `ShieldAlert` | Major Interaction |
| ✓🛡️ | `ShieldCheck` | No Interactions |
| ℹ️ | `Info` | Info, Minor |
| ⚡ | `AlertCircle` | Moderate |

#### الأسعار والإحصائيات
| الأيقونة | الاسم | الاستخدام |
|----------|-------|-----------|
| 📈 | `TrendingUp` | Price Increase |
| 📉 | `TrendingDown` | Price Decrease |
| ✨ | `Sparkles` | New Items |

#### الأدوات
| الأيقونة | الاسم | الاستخدام |
|----------|-------|-----------|
| 🔀 | `GitCompare` | Interactions |
| 🧮 | `Calculator` | Dose Calculator |
| ⚖️ | `Weight` | Weight Input |
| ⏱️ | `Clock` | Time, Frequency |

#### الإعدادات
| الأيقونة | الاسم | الاستخدام |
|----------|-------|-----------|
| ⚙️ | `Settings` | Settings |
| 🌙 | `Moon` | Dark Mode |
| 🌍 | `Globe` | Language |
| 🛡️ | `Shield` | Privacy |
| ❓ | `HelpCircle` | Help |
| 🚪 | `LogOut` | Logout |
| 🔊 | `Volume2` | Sounds |
| 📳 | `Vibrate` | Haptics |
| 📥 | `Download` | Offline Mode |
| 📤 | `Upload` | Auto Sync |
| 💾 | `Database` | Cache |
| 🗑️ | `Trash2` | Delete, Clear |
| 📍 | `MapPin` | Location |
| 💳 | `CreditCard` | Currency, Price |
| 📄 | `FileText` | Terms, Font |
| 💬 | `MessageSquare` | Feedback |
| ⭐ | `Star` | Rate, New Alerts |
| 🏢 | `Building2` | Manufacturer |
| # | `Hash` | Registration |
| 📱 | `Smartphone` | - |
| 🎨 | `Palette` | - |
| 🔇 | `Mic` | Voice Search |
| ⚙️ | `SlidersHorizontal` | Filters |

---

## 📱 إطار الموبايل (Mobile Frame)

### Container الخارجي
```css
min-h-screen
bg-muted
flex items-center justify-center
p-4
```

### Device Frame
```css
w-full
max-w-[430px]
min-h-[800px]
bg-background
rounded-[2.5rem]        /* 40px */
shadow-elevated
overflow-hidden
relative
border-8 border-foreground/10
```

### Status Bar
```css
height: h-12            /* 48px */
background: bg-surface
display: flex items-center justify-between
padding: px-6 pt-2
```

#### Status Bar Elements:
| العنصر | الخصائص |
|--------|---------|
| **الوقت** | `text-xs font-medium text-foreground` - "9:41" |
| **إشارة الشبكة** | 4 أعمدة `w-1` بارتفاعات `h-2.5, h-3, h-3.5, h-4` |
| **WiFi** | SVG icon `w-4 h-4` |
| **البطارية** | `w-6 h-3 border-2 rounded-sm` مع شريط داخلي `bg-success` بنسبة 70% |

### Home Indicator
```css
position: absolute bottom-2
left-1/2 -translate-x-1/2
w-32 h-1
bg-foreground/30
rounded-full
```

---

## 🧩 المكونات العامة (Shared Components)

### Input Component
```css
flex
h-10                    /* 40px */
w-full
rounded-md              /* 12px */
border border-input
bg-background
px-3 py-2
text-base               /* 16px mobile, 14px desktop */
ring-offset-background
placeholder:text-muted-foreground

/* Focus State */
focus-visible:outline-none
focus-visible:ring-2
focus-visible:ring-ring
focus-visible:ring-offset-2

/* Disabled State */
disabled:cursor-not-allowed
disabled:opacity-50
```

### Switch Component
```css
/* Root */
inline-flex
h-6 w-11                /* 24px × 44px */
shrink-0
cursor-pointer
items-center
rounded-full
border-2 border-transparent
transition-colors

/* States */
data-[state=checked]:bg-primary
data-[state=unchecked]:bg-input

/* Focus */
focus-visible:ring-2
focus-visible:ring-ring
focus-visible:ring-offset-2

/* Disabled */
disabled:cursor-not-allowed
disabled:opacity-50

/* Thumb */
pointer-events-none
block
h-5 w-5                 /* 20px */
rounded-full
bg-background
shadow-lg
ring-0
transition-transform
data-[state=checked]:translate-x-5
data-[state=unchecked]:translate-x-0
```

### Slider Component
```css
/* Root */
relative
flex w-full
touch-none select-none
items-center

/* Track */
relative
h-2                     /* 8px */
w-full grow
overflow-hidden
rounded-full
bg-secondary

/* Range */
absolute
h-full
bg-primary

/* Thumb */
block
h-5 w-5                 /* 20px */
rounded-full
border-2 border-primary
bg-background
ring-offset-background
transition-colors

/* Thumb Focus */
focus-visible:ring-2
focus-visible:ring-ring
focus-visible:ring-offset-2
```

---

## 🌐 دعم RTL (RTL Support)

### HTML Attributes
```html
<!-- English -->
<html lang="en" dir="ltr">

<!-- Arabic -->
<html lang="ar" dir="rtl">
```

### RTL-Specific Classes

```css
/* تدوير الأسهم */
[dir="rtl"] .arrow-icon {
  transform: rotate(180deg);
}

/* عكس ترتيب Flex */
.flex-row-reverse  /* للقوائم الأفقية في RTL */

/* عكس النص */
text-right         /* للعربية */
text-start         /* يتكيف تلقائياً */

/* الخط العربي */
.font-arabic {
  font-family: 'Cairo', 'Inter', sans-serif;
}
```

### RTL في الكود
```tsx
// isRTL من useTheme
const { isRTL } = useTheme();

// تطبيق RTL
<div dir={isRTL ? 'rtl' : 'ltr'}>

// تدوير الأيقونات
<ChevronRight className={cn("w-4 h-4", isRTL && "rotate-180")} />
<ArrowLeft className={cn("w-5 h-5", isRTL && "rotate-180")} />

// عكس الترتيب
<div className={cn("flex", isRTL && "flex-row-reverse")}>
```
