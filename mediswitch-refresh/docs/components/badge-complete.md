# Badge Component - Complete Pixel-Perfect Documentation
# توثيق مكون البادج - تفاصيل بكسل مثالية

---

## 📐 Base Styles (الأنماط الأساسية)

```css
/* Base Classes */
inline-flex
items-center
rounded-full                       /* 9999px */
border
font-semibold                      /* 600 */
transition-colors

/* Focus States */
focus:outline-none
focus:ring-2
focus:ring-ring
focus:ring-offset-2
```

---

## 📏 Sizes (الأحجام)

### Default Size
```css
padding: px-2.5 py-0.5             /* 10px horizontal, 2px vertical */
font-size: text-xs                 /* 12px */
line-height: 1rem                  /* 16px */
```

### Small Size (sm)
```css
padding: px-2 py-0.5               /* 8px horizontal, 2px vertical */
font-size: text-[10px]             /* 10px */
line-height: 1                     /* 10px */
```

### Large Size (lg)
```css
padding: px-3 py-1                 /* 12px horizontal, 4px vertical */
font-size: text-sm                 /* 14px */
line-height: 1.25rem               /* 20px */
```

---

## 🎨 Variants (الأنواع)

### Default Variants

#### default
```css
border: border-transparent
background: bg-primary             /* hsl(210, 90%, 45%) */
color: text-primary-foreground     /* white */
hover:background: hover:bg-primary/80
```

#### secondary
```css
border: border-transparent
background: bg-secondary           /* hsl(185, 60%, 45%) */
color: text-secondary-foreground   /* white */
hover:background: hover:bg-secondary/80
```

#### destructive
```css
border: border-transparent
background: bg-destructive         /* hsl(0, 75%, 55%) */
color: text-destructive-foreground /* white */
hover:background: hover:bg-destructive/80
```

#### outline
```css
border: visible                    /* uses default border color */
background: transparent
color: text-foreground             /* hsl(215, 25%, 15%) */
```

---

### MediSwitch Custom Variants

#### new (جديد)
```css
border: border-transparent
background: bg-success             /* hsl(150, 60%, 42%) */
color: text-success-foreground     /* white */
box-shadow: shadow-sm
```

**الاستخدام:**
```tsx
<Badge variant="new" size="sm">NEW</Badge>
<Badge variant="new" size="sm">جديد</Badge>
```

---

#### popular (شائع)
```css
border: border-transparent
background: bg-primary             /* hsl(210, 90%, 45%) */
color: text-primary-foreground     /* white */
box-shadow: shadow-sm
```

**الاستخدام:**
```tsx
<Badge variant="popular" size="sm">POPULAR</Badge>
<Badge variant="popular" size="sm">رائج</Badge>
```

---

#### danger (خطر)
```css
border: border-transparent
background: bg-danger              /* hsl(0, 75%, 55%) */
color: text-danger-foreground      /* white */
box-shadow: shadow-sm
```

**الاستخدام:**
```tsx
<Badge variant="danger" size="sm">MAJOR</Badge>
<Badge variant="danger" size="sm">خطير</Badge>
```

---

#### warning (تحذير)
```css
border: border-transparent
background: bg-warning             /* hsl(38, 95%, 50%) */
color: text-warning-foreground     /* hsl(38, 95%, 20%) */
box-shadow: shadow-sm
```

**الاستخدام:**
```tsx
<Badge variant="warning" size="sm">MODERATE</Badge>
<Badge variant="warning" size="sm">متوسط</Badge>
```

---

#### info (معلومات)
```css
border: border-transparent
background: bg-info                /* hsl(200, 80%, 50%) */
color: text-info-soft              /* hsl(200, 80%, 95%) */
box-shadow: shadow-sm
```

**الاستخدام:**
```tsx
<Badge variant="info" size="sm">MINOR</Badge>
<Badge variant="info" size="sm">طفيف</Badge>
```

---

#### priceDown (انخفاض السعر)
```css
border: border-transparent
background: bg-success-soft        /* hsl(150, 55%, 94%) */
color: text-success                /* hsl(150, 60%, 42%) */
font-weight: font-bold             /* 700 */
```

**الاستخدام:**
```tsx
<Badge variant="priceDown" size="sm">
  <TrendingDown className="w-3 h-3 mr-1" />
  10%
</Badge>
```

---

#### priceUp (ارتفاع السعر)
```css
border: border-transparent
background: bg-danger-soft         /* hsl(0, 70%, 95%) */
color: text-danger                 /* hsl(0, 75%, 55%) */
font-weight: font-bold             /* 700 */
```

**الاستخدام:**
```tsx
<Badge variant="priceUp" size="sm">
  <TrendingUp className="w-3 h-3 mr-1" />
  +5%
</Badge>
```

---

#### interaction (تفاعل دوائي)
```css
border: border border-danger/30    /* 30% opacity */
background: bg-danger-soft         /* hsl(0, 70%, 95%) */
color: text-danger                 /* hsl(0, 75%, 55%) */
font-weight: font-medium           /* 500 */
```

**الاستخدام:**
```tsx
<Badge variant="interaction">
  Interaction Warning
</Badge>
```

---

## 🔧 Component Code

```tsx
import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    variants: {
      variant: {
        default: "border-transparent bg-primary text-primary-foreground hover:bg-primary/80",
        secondary: "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80",
        destructive: "border-transparent bg-destructive text-destructive-foreground hover:bg-destructive/80",
        outline: "text-foreground",
        new: "border-transparent bg-success text-success-foreground shadow-sm",
        popular: "border-transparent bg-primary text-primary-foreground shadow-sm",
        danger: "border-transparent bg-danger text-danger-foreground shadow-sm",
        warning: "border-transparent bg-warning text-warning-foreground shadow-sm",
        info: "border-transparent bg-info text-info-soft shadow-sm",
        priceDown: "border-transparent bg-success-soft text-success font-bold",
        priceUp: "border-transparent bg-danger-soft text-danger font-bold",
        interaction: "border border-danger/30 bg-danger-soft text-danger font-medium",
      },
      size: {
        default: "px-2.5 py-0.5 text-xs",
        sm: "px-2 py-0.5 text-[10px]",
        lg: "px-3 py-1 text-sm",
      }
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, size, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant, size }), className)} {...props} />;
}

export { Badge, badgeVariants };
```

---

## 📊 Visual Reference

| Variant | Preview (Light) | Preview (Dark) |
|---------|-----------------|----------------|
| `new` | 🟢 أخضر على أبيض | 🟢 أخضر على داكن |
| `popular` | 🔵 أزرق على أبيض | 🔵 أزرق على داكن |
| `danger` | 🔴 أحمر على أبيض | 🔴 أحمر على داكن |
| `warning` | 🟠 برتقالي على أبيض | 🟠 برتقالي على داكن |
| `info` | 🔵 أزرق فاتح | 🔵 أزرق فاتح |
| `priceDown` | أخضر فاتح مع نص أخضر | أخضر داكن مع نص أخضر |
| `priceUp` | أحمر فاتح مع نص أحمر | أحمر داكن مع نص أحمر |

---

## 🎯 Usage Examples

### في DrugCard
```tsx
{drug.isNew && <Badge variant="new" size="sm">NEW</Badge>}
{drug.isPopular && <Badge variant="popular" size="sm">POPULAR</Badge>}
```

### في تغير السعر
```tsx
{priceChange !== 0 && (
  <Badge variant={isPriceDown ? "priceDown" : "priceUp"} size="sm">
    {isPriceDown ? <TrendingDown className="w-3 h-3 mr-1" /> : <TrendingUp className="w-3 h-3 mr-1" />}
    {Math.abs(priceChange).toFixed(0)}%
  </Badge>
)}
```

### في مستوى الخطورة
```tsx
<Badge 
  variant={severity === 'major' ? 'danger' : severity === 'moderate' ? 'warning' : 'info'}
  size="sm"
>
  {severity.toUpperCase()}
</Badge>
```

### في العداد
```tsx
<Badge variant="secondary" size="sm">{count}</Badge>
```
