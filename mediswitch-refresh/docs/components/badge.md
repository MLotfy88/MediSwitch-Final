# Badge Component Documentation
# توثيق مكون البادج

---

اقراء هذا الملف جيدا وقارنه مع الكود الفعلى وقولى منفذ كام% منه؟ مع مراعاه ان التطبيق له وضع ليلى ووضع نهارى
وتاكد من الربط بالبيانات الحقيقية وليس الوهمية
وتاكد ايضا من ال Functionality
والتاكد من دعم اللغة العربية والانجليزية بتنسيقهما (RTL & LTR)
وتاكد من عدم وجود ملف مكرر
وكلمنى عربى

## 📱 نظرة عامة (Overview)

مكون البادج يستخدم لإظهار حالات مختلفة مثل الجديد، الشائع، التحذيرات، وتغيرات الأسعار.

**الملف:** `src/components/ui/badge.tsx`

---

## 🎨 الـ Variants (الأنواع)

### Default Variants

| Variant | الخلفية | لون النص | الحدود |
|---------|---------|----------|--------|
| `default` | `bg-primary` | `text-primary-foreground` | transparent |
| `secondary` | `bg-secondary` | `text-secondary-foreground` | transparent |
| `destructive` | `bg-destructive` | `text-destructive-foreground` | transparent |
| `outline` | transparent | `text-foreground` | visible |

---

### Custom MediSwitch Variants

| Variant | الخلفية | لون النص | الاستخدام |
|---------|---------|----------|-----------|
| `new` | `bg-success` | `text-success-foreground` | الأدوية الجديدة |
| `popular` | `bg-primary` | `text-primary-foreground` | الأدوية الشائعة |
| `danger` | `bg-danger` | `text-danger-foreground` | تحذيرات خطيرة |
| `warning` | `bg-warning` | `text-warning-foreground` | تحذيرات متوسطة |
| `info` | `bg-info` | `text-info-soft` | معلومات |
| `priceDown` | `bg-success-soft` | `text-success` | انخفاض السعر |
| `priceUp` | `bg-danger-soft` | `text-danger` | ارتفاع السعر |
| `interaction` | `bg-danger-soft` | `text-danger` | تفاعل دوائي |

---

## 📏 الـ Sizes (الأحجام)

| Size | الـ Padding | حجم الخط |
|------|------------|----------|
| `default` | `px-2.5 py-0.5` | `text-xs` |
| `sm` | `px-2 py-0.5` | `text-[10px]` |
| `lg` | `px-3 py-1` | `text-sm` |

---

## 🎯 Base Styles (الأنماط الأساسية)

```css
inline-flex items-center
rounded-full
border
font-semibold
transition-colors
focus:outline-none
focus:ring-2
focus:ring-ring
focus:ring-offset-2
```

---

## 💡 أمثلة الاستخدام

### بادج جديد:
```tsx
<Badge variant="new" size="sm">NEW</Badge>
<Badge variant="new" size="sm">جديد</Badge>
```

### بادج شائع:
```tsx
<Badge variant="popular" size="sm">POPULAR</Badge>
<Badge variant="popular" size="sm">رائج</Badge>
```

### بادج انخفاض السعر:
```tsx
<Badge variant="priceDown" size="sm">
  <TrendingDown className="w-3 h-3 mr-1" />
  10%
</Badge>
```

### بادج ارتفاع السعر:
```tsx
<Badge variant="priceUp" size="sm">
  <TrendingUp className="w-3 h-3 mr-1" />
  5%
</Badge>
```

### بادج مستوى الخطورة:
```tsx
<Badge variant="danger" size="sm">MAJOR</Badge>
<Badge variant="warning" size="sm">MODERATE</Badge>
<Badge variant="info" size="sm">MINOR</Badge>
```

### بادج العدد:
```tsx
<Badge variant="secondary" size="sm">{count}</Badge>
```

---

## 🔧 Props

```typescript
interface BadgeProps extends HTMLDivElement {
  variant?: 'default' | 'secondary' | 'destructive' | 'outline' | 
            'new' | 'popular' | 'danger' | 'warning' | 'info' | 
            'priceDown' | 'priceUp' | 'interaction';
  size?: 'default' | 'sm' | 'lg';
  className?: string;
}
```

---

## 📐 Shadow

جميع البادجات المخصصة لـ MediSwitch تحتوي على `shadow-sm` لإضافة عمق بصري.
