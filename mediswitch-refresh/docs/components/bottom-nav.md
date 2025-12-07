# Bottom Navigation Documentation
# توثيق شريط التنقل السفلي

---

## 📱 نظرة عامة (Overview)

شريط التنقل السفلي هو عنصر ثابت في أسفل الشاشة يسمح بالتنقل بين الصفحات الرئيسية للتطبيق.

**الملف:** `src/components/layout/BottomNav.tsx`

---

## 🏗️ الهيكل العام (Structure)

```
BottomNav
└── Nav Container (Fixed)
    └── Nav Items
        └── Nav Button
            ├── Icon
            └── Label
```

---

## 🎨 التصميم التفصيلي

### Container (الحاوية الرئيسية)

| الخاصية | القيمة |
|---------|--------|
| **الموضع** | `fixed bottom-0` |
| **المحاذاة** | `left-1/2 -translate-x-1/2` |
| **العرض** | `w-full max-w-[430px]` |
| **الخلفية** | `bg-surface/95 backdrop-blur-lg` |
| **الحدود** | `border-t border-border` |
| **Safe Area** | `safe-area-bottom` |

---

### Nav Container

| الخاصية | القيمة |
|---------|--------|
| **التخطيط** | `flex items-center justify-around` |
| **الـ Padding** | `py-2 px-2` |

---

### Nav Button

| الخاصية | القيمة (غير نشط) | القيمة (نشط) |
|---------|------------------|--------------|
| **التخطيط** | `flex flex-col items-center gap-1` | نفسه |
| **الـ Padding** | `px-4 py-2` | `px-4 py-2` |
| **الشكل** | `rounded-xl` | `rounded-xl` |
| **الخلفية** | transparent | `bg-primary/10` |
| **Hover** | `hover:bg-accent` | - |
| **Transition** | `transition-all duration-200` | - |

---

### Icon

| الخاصية | القيمة (غير نشط) | القيمة (نشط) |
|---------|------------------|--------------|
| **الحجم** | `w-5 h-5` | `w-5 h-5` |
| **اللون** | `text-muted-foreground` | `text-primary` |
| **Transition** | `transition-colors` | - |

---

### Label

| الخاصية | القيمة (غير نشط) | القيمة (نشط) |
|---------|------------------|--------------|
| **الخط** | `text-[10px] font-medium` | `text-[10px] font-medium` |
| **اللون** | `text-muted-foreground` | `text-primary` |
| **Transition** | `transition-colors` | - |

---

## 📋 Nav Items

| ID | الأيقونة | Label EN | Label AR |
|----|----------|----------|----------|
| `home` | `Home` | Home | الرئيسية |
| `search` | `Search` | Search | بحث |
| `history` | `History` | History | السجل |
| `favorites` | `Heart` | Favorites | المفضلة |
| `profile` | `User` | Profile | الحساب |

---

## 🌐 دعم RTL (العربية)

### العناصر المتأثرة:
- النصوص تتغير حسب اللغة من خلال `useTheme`

---

## 💡 ملاحظات التنفيذ

### Safe Area:
```css
.safe-area-bottom {
  padding-bottom: env(safe-area-inset-bottom);
}
```

### الموضع الثابت:
- الـ Bottom Nav ثابت في أسفل الشاشة
- يجب إضافة `pb-24` على محتوى الصفحات لتجنب التداخل
