# Home Screen - Complete Pixel-Perfect Documentation
# توثيق الشاشة الرئيسية - تفاصيل بكسل مثالية

---

## 📐 قياسات الشاشة الكاملة

### Container الرئيسي
```css
padding-bottom: pb-24     /* 96px - مساحة لـ BottomNav */
```

---

## 1️⃣ App Header (الهيدر)

### Container
```css
position: sticky top-0 z-50
background: bg-surface/95          /* rgba(255,255,255,0.95) */
backdrop-filter: backdrop-blur-lg   /* blur(16px) */
border-bottom: border-b border-border  /* 1px solid hsl(210,20%,90%) */
padding: px-4 py-3                 /* 16px horizontal, 12px vertical */
```

### Layout
```css
display: flex items-center justify-between
```

---

### Logo Container
```css
display: flex items-center gap-3   /* 12px gap */
```

#### Logo Icon Box
```css
width: w-10                        /* 40px */
height: h-10                       /* 40px */
border-radius: rounded-xl          /* 18px */
background: bg-gradient-to-br from-primary to-primary-dark
box-shadow: shadow-md
display: flex items-center justify-center
```

#### Logo SVG
```xml
<svg 
  class="w-6 h-6 text-primary-foreground"   /* 24px, white */
  viewBox="0 0 24 24" 
  fill="none" 
  stroke="currentColor" 
  stroke-width="2.5" 
  stroke-linecap="round" 
  stroke-linejoin="round"
>
  <!-- Heart Path -->
  <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z" />
  <!-- Vertical Line -->
  <path d="M12 5v14" />
  <!-- Horizontal Line -->
  <path d="M5 12h14" />
</svg>
```

#### Title Text
```css
/* العنوان */
font-size: text-lg                 /* 18px */
font-weight: font-bold             /* 700 */
color: text-foreground             /* hsl(215,25%,15%) */
content: "MediSwitch"
```

#### Last Updated Row
```css
display: flex items-center gap-1   /* 4px gap */
font-size: text-xs                 /* 12px */
color: text-muted-foreground       /* hsl(215,15%,50%) */
```

##### RefreshCw Icon
```css
width: w-3 h-3                     /* 12px */
```

##### Update Text
```
content: "Updated Dec 5, 2024"
```

---

### Notification Button
```css
position: relative
padding: p-2.5                     /* 10px */
border-radius: rounded-xl          /* 18px */
background: bg-accent              /* hsl(210,30%,95%) */
transition: transition-colors
hover:background: hover:bg-accent/80
```

#### Bell Icon
```css
width: w-5 h-5                     /* 20px */
color: text-foreground
```

#### Notification Badge
```css
position: absolute -top-1 -right-1 /* -4px من الأعلى واليمين */
min-width: min-w-[18px]            /* 18px */
height: h-[18px]                   /* 18px */
border-radius: rounded-full
background: bg-danger              /* hsl(0,75%,55%) */
color: text-danger-foreground      /* white */
font-size: text-[10px]             /* 10px */
font-weight: font-bold             /* 700 */
display: flex items-center justify-center
padding: px-1                      /* 4px horizontal */
content: "3" (أو "+9" إذا > 9)
```

---

## 2️⃣ Search Section

### Container
```css
padding: px-4 py-4                 /* 16px */
```

---

### SearchBar Component

#### Container
```css
position: relative
```

#### Input Container
```css
display: flex items-center gap-3   /* 12px gap */
padding: px-4 py-3.5               /* 16px horizontal, 14px vertical */
border-radius: rounded-2xl         /* 22px */
background: bg-card                /* white */
border: border-2 border-transparent
box-shadow: card-shadow
transition: transition-all duration-200
```

##### Focus State
```css
border-color: border-primary       /* hsl(210,90%,45%) */
ring: ring-4 ring-primary/10       /* 4px ring with 10% opacity */
```

#### Search Icon (Lucide)
```css
width: w-5 h-5                     /* 20px */
flex-shrink: flex-shrink-0
color: text-muted-foreground       /* Default */
color: text-primary                /* On Focus */
transition: transition-colors
```

#### Input Field
```css
flex: flex-1
background: bg-transparent
font-size: text-sm                 /* 14px */
color: text-foreground
placeholder-color: placeholder:text-muted-foreground
outline: focus:outline-none
```

##### Placeholder Text (EN)
```
"Search by Trade Name or Active Ingredient..."
```

##### Placeholder Text (AR)
```
"ابحث بالاسم التجاري أو المادة الفعالة..."
```

#### Right Actions Container
```css
display: flex items-center gap-2   /* 8px gap */
```

#### Microphone Button
```css
padding: p-2                       /* 8px */
border-radius: rounded-xl          /* 18px */
transition: transition-colors
hover:background: hover:bg-accent
```

##### Mic Icon
```css
width: w-4 h-4                     /* 16px */
color: text-muted-foreground
```

#### Separator
```css
width: w-px                        /* 1px */
height: h-6                        /* 24px */
background: bg-border
```

#### Filter Button
```css
padding: p-2                       /* 8px */
border-radius: rounded-xl          /* 18px */
background: bg-primary/10          /* 10% opacity */
transition: transition-colors
hover:background: hover:bg-primary/20
```

##### SlidersHorizontal Icon
```css
width: w-4 h-4                     /* 16px */
color: text-primary
```

---

### Quick Stats Card
```css
margin-top: mt-4                   /* 16px */
display: flex items-center justify-between
padding: px-4 py-3                 /* 16px horizontal, 12px vertical */
background: bg-success-soft        /* hsl(150,55%,94%) */
border-radius: rounded-xl          /* 18px */
```

#### Left Side
```css
display: flex items-center gap-2   /* 8px gap */
```

##### TrendingUp Icon
```css
width: w-5 h-5                     /* 20px */
color: text-success                /* hsl(150,60%,42%) */
```

##### Text
```css
font-size: text-sm                 /* 14px */
font-weight: font-medium           /* 500 */
color: text-success
content: "Today's Updates"
```

#### Badge
```css
variant: "new"
size: "lg"
content: "+30 Drugs"
```

---

### Quick Tools Grid
```css
margin-top: mt-4                   /* 16px */
display: grid grid-cols-2          /* 2 columns */
gap: gap-3                         /* 12px */
```

#### Tool Button (Interactions)
```css
display: flex items-center gap-3   /* 12px gap */
padding: p-4                       /* 16px */
background: bg-warning/10          /* 10% opacity */
border: border border-warning/20   /* 20% opacity border */
border-radius: rounded-xl          /* 18px */
transition: transition-colors
hover:background: hover:bg-warning/20
```

##### Icon Container
```css
width: w-10 h-10                   /* 40px */
border-radius: rounded-xl          /* 18px */
background: bg-warning/20
display: flex items-center justify-center
```

##### GitCompare Icon
```css
width: w-5 h-5                     /* 20px */
color: text-warning                /* hsl(38,95%,50%) */
```

##### Text Container
```css
text-align: text-start
```

##### Title
```css
font-size: text-sm                 /* 14px */
font-weight: font-semibold         /* 600 */
color: text-foreground
content: "Interactions"
```

##### Subtitle
```css
font-size: text-xs                 /* 12px */
color: text-muted-foreground
content: "Check conflicts"
```

---

#### Tool Button (Dose Calculator)
```css
background: bg-primary/10
border: border border-primary/20
hover:background: hover:bg-primary/20
```

##### Icon Container
```css
background: bg-primary/20
```

##### Calculator Icon
```css
color: text-primary
```

##### Text
```
Title: "Dose Calc"
Subtitle: "Calculate dosage"
```

---

## 3️⃣ Categories Section

### Section Container
```css
padding: px-4                      /* 16px horizontal */
margin-bottom: mb-6                /* 24px */
```

---

### Section Header
```css
display: flex items-center justify-between
```

#### Left Side
```css
display: flex items-center gap-2   /* 8px gap */
```

##### Icon Container
```css
width: w-8 h-8                     /* 32px */
border-radius: rounded-lg          /* 14px */
background: bg-accent              /* hsl(210,30%,95%) */
display: flex items-center justify-center
```

##### Pill Icon
```css
width: w-4 h-4                     /* 16px */
/* color is passed via prop */
```

##### Title Text
```css
font-size: text-base               /* 16px */
font-weight: font-semibold         /* 600 */
color: text-foreground
content: "Medical Specialties"
```

##### Subtitle Text
```css
font-size: text-xs                 /* 12px */
color: text-muted-foreground
content: "Browse by category"
```

#### See All Button
```css
display: flex items-center gap-0.5 /* 2px gap */
font-size: text-sm                 /* 14px */
font-weight: font-medium           /* 500 */
color: text-primary
transition: transition-colors
hover:color: hover:text-primary-dark
content: "See all"
```

##### ChevronRight Icon
```css
width: w-4 h-4                     /* 16px */
```

---

### Categories Scroll Container
```css
margin-top: mt-3                   /* 12px */
display: flex gap-3                /* 12px gap */
overflow-x: auto
scrollbar: scrollbar-hide
padding-bottom: pb-2               /* 8px - للظل */
margin: -mx-4 px-4                 /* تمديد للحواف */
```

---

### CategoryCard

#### Container
```css
display: flex flex-col items-center gap-2   /* 8px gap */
padding: p-4                               /* 16px */
border-radius: rounded-2xl                 /* 22px */
border: border                             /* 1px */
transition: transition-all duration-200
min-width: min-w-[88px]                    /* 88px */

/* Hover Effects */
hover:transform: hover:scale-105
active:transform: active:scale-95
```

#### Color Variants
| Color | Background | Icon Color | Border |
|-------|------------|------------|--------|
| `red` | `bg-danger-soft` | `text-danger` | `border-danger/20` |
| `purple` | `bg-accent` | `text-primary` | `border-primary/20` |
| `teal` | `bg-secondary/10` | `text-secondary` | `border-secondary/20` |
| `green` | `bg-success-soft` | `text-success` | `border-success/20` |
| `blue` | `bg-info-soft` | `text-info` | `border-info/20` |
| `orange` | `bg-warning-soft` | `text-warning` | `border-warning/30` |

#### Icon Container
```css
padding: p-2.5                     /* 10px */
border-radius: rounded-xl          /* 18px */
background: /* same as card bg */
```

#### Icon
```css
width: w-6 h-6                     /* 24px */
color: /* from color variant */
```

#### Category Name
```css
font-size: text-xs                 /* 12px */
font-weight: font-semibold         /* 600 */
color: text-foreground
text-overflow: truncate
max-width: max-w-[72px]            /* 72px */
```

#### Drug Count
```css
font-size: text-[10px]             /* 10px */
color: text-muted-foreground
content: "{count} drugs"
```

#### Animation
```css
animation: animate-slide-in-right
animation-delay: style={{ animationDelay: `${index * 50}ms` }}
```

---

## 4️⃣ Dangerous Drugs Section

### Section Header
```css
icon: <AlertTriangle className="w-4 h-4 text-danger" />
iconColor: "bg-danger-soft"
title: "High-Risk Drugs"
subtitle: "Drugs with severe interactions"
```

---

### DangerousDrugCard

#### Container
```css
display: flex flex-col gap-2       /* 8px gap */
padding: p-4                       /* 16px */
border-radius: rounded-2xl         /* 22px */
min-width: min-w-[140px]           /* 140px */
border: border
transition: transition-all duration-200
hover:transform: hover:scale-[1.02]
active:transform: active:scale-[0.98]
```

#### Critical Level
```css
background: bg-danger/10           /* 10% opacity */
border-color: border-danger/30     /* 30% opacity */
```

#### High Level
```css
background: bg-warning-soft        /* hsl(38,90%,95%) */
border-color: border-warning/30
```

---

#### Icon Container
```css
width: w-10 h-10                   /* 40px */
border-radius: rounded-xl          /* 18px */
display: flex items-center justify-center
```

##### Critical
```css
background: bg-danger/20
icon: Skull w-5 h-5 text-danger
```

##### High
```css
background: bg-warning/20
icon: AlertTriangle w-5 h-5 text-warning
```

---

#### Drug Name
```css
font-size: text-sm                 /* 14px */
font-weight: font-semibold         /* 600 */
text-overflow: truncate
max-width: max-w-[120px]
```

##### Critical Color
```css
color: text-danger
```

##### High Color
```css
color: text-warning-foreground
```

---

#### Active Ingredient
```css
font-size: text-xs                 /* 12px */
color: text-muted-foreground
text-overflow: truncate
max-width: max-w-[120px]
```

---

#### Interaction Badge
```css
display: flex items-center gap-1   /* 4px gap */
padding: px-2 py-1                 /* 8px horizontal, 4px vertical */
border-radius: rounded-full
font-size: text-[10px]             /* 10px */
font-weight: font-bold             /* 700 */
align-self: self-start
```

##### Critical
```css
background: bg-danger/20
color: text-danger
```

##### High
```css
background: bg-warning/20
color: text-warning-foreground
```

##### AlertTriangle Icon
```css
width: w-3 h-3                     /* 12px */
```

##### Text
```
"{count} interactions"
```

---

## 5️⃣ Recently Added Section

### Section Header
```css
icon: <Sparkles className="w-4 h-4 text-success" />
iconColor: "bg-success-soft"
title: "Recently Added"
subtitle: "New drugs this week"
```

---

### DrugCard Container
```css
margin-top: mt-3                   /* 12px */
layout: space-y-3                  /* 12px between cards */
```

---

### DrugCard

#### Container
```css
background: bg-card                /* white */
border-radius: rounded-xl          /* 18px */
padding: p-4                       /* 16px */
box-shadow: card-shadow
cursor: cursor-pointer
transition: transition-all duration-200

/* Hover Effect */
hover:transform: hover:-translate-y-0.5  /* -2px */
hover:box-shadow: shadow-md
```

#### Animation
```css
animation: animate-fade-in
animation-delay: style={{ animationDelay: `${index * 100}ms` }}
```

---

#### Header Row
```css
display: flex items-start justify-between gap-3  /* 12px gap */
margin-bottom: mb-3                              /* 12px */
```

##### Left Content
```css
flex: flex-1
min-width: min-w-0                 /* للـ truncate */
```

##### Trade Name Row
```css
display: flex items-center gap-2   /* 8px gap */
margin-bottom: mb-1                /* 4px */
```

##### Trade Name (Primary)
```css
font-weight: font-semibold         /* 600 */
color: text-foreground
text-overflow: truncate
```

##### Badges Container
```css
display: flex gap-1                /* 4px gap */
flex-shrink: flex-shrink-0
```

##### NEW Badge
```css
variant: "new"
size: "sm"
content: "NEW"
```

##### POPULAR Badge
```css
variant: "popular"
size: "sm"
content: "POPULAR"
```

---

##### Trade Name (Secondary)
```css
font-size: text-sm                 /* 14px */
color: text-muted-foreground
text-overflow: truncate
direction: /* opposite to primary */
```

---

#### Favorite Button
```css
padding: p-2                       /* 8px */
border-radius: rounded-full
transition: transition-all duration-200
```

##### Not Favorite State
```css
background: bg-muted
color: text-muted-foreground
hover:background: hover:bg-danger-soft
hover:color: hover:text-danger
```

##### Favorite State
```css
background: bg-danger-soft
color: text-danger
```

##### Heart Icon
```css
width: w-4 h-4                     /* 16px */
/* If favorite: fill-current */
```

---

#### Form & Active Ingredient Row
```css
display: flex items-center gap-2   /* 8px gap */
margin-bottom: mb-3                /* 12px */
```

##### Form Badge Container
```css
display: flex items-center gap-1.5 /* 6px gap */
padding: px-2 py-1                 /* 8px horizontal, 4px vertical */
background: bg-accent
border-radius: rounded-md          /* 12px */
```

##### Form Icon
```css
width: w-3.5 h-3.5                 /* 14px */
color: text-accent-foreground
```

##### Form Icons Map
| Form | Icon |
|------|------|
| `tablet` | `Pill` |
| `syrup` | `Droplets` |
| `injection` | `Syringe` |
| `cream` | Custom SVG |
| `drops` | `Droplets` |

##### Form Text
```css
font-size: text-xs                 /* 12px */
font-weight: font-medium           /* 500 */
color: text-accent-foreground
```

##### Form Labels
| Form | EN | AR |
|------|----|----|
| `tablet` | "Tablet" | "أقراص" |
| `syrup` | "Syrup" | "شراب" |
| `injection` | "Injection" | "حقن" |
| `cream` | "Cream" | "كريم" |
| `drops` | "Drops" | "قطرة" |

##### Separator
```css
font-size: text-xs
color: text-muted-foreground
content: "•"
```

##### Active Ingredient
```css
font-size: text-xs                 /* 12px */
color: text-muted-foreground
text-overflow: truncate
```

---

#### Price Row
```css
display: flex items-end justify-between
```

##### Price Container
```css
display: flex items-baseline gap-2 /* 8px gap */
```

##### Current Price
```css
font-size: text-xl                 /* 20px */
font-weight: font-bold             /* 700 */
color: text-foreground
content: "{price} EGP"
```

##### Old Price (if exists)
```css
font-size: text-sm                 /* 14px */
color: text-muted-foreground
text-decoration: line-through
content: "{oldPrice}"
```

##### Price Change Badge
| Type | Variant | Icon |
|------|---------|------|
| Down | `priceDown` | `TrendingDown w-3 h-3` |
| Up | `priceUp` | `TrendingUp w-3 h-3` |

```css
size: "sm"
content: "{percentage}%"
```

---

#### Interaction Warning (if hasInteraction)
```css
margin-top: mt-3                   /* 12px */
display: flex items-center gap-2   /* 8px gap */
padding: px-3 py-2                 /* 12px horizontal, 8px vertical */
background: bg-danger-soft
border-radius: rounded-lg          /* 14px */
```

##### AlertTriangle Icon
```css
width: w-4 h-4                     /* 16px */
color: text-danger
flex-shrink: flex-shrink-0
```

##### Warning Text
```css
font-size: text-xs                 /* 12px */
font-weight: font-medium           /* 500 */
color: text-danger
content: "Interaction Warning" / "تحذير: تفاعل دوائي"
```

---

## 📊 البيانات (Data)

### Categories
```typescript
const categories: Category[] = [
  { id: '1', name: 'Cardiac', nameAr: 'قلب', icon: 'heart', drugCount: 245, color: 'red' },
  { id: '2', name: 'Neuro', nameAr: 'أعصاب', icon: 'brain', drugCount: 189, color: 'purple' },
  { id: '3', name: 'Dental', nameAr: 'أسنان', icon: 'dental', drugCount: 78, color: 'teal' },
  { id: '4', name: 'Pediatric', nameAr: 'أطفال', icon: 'baby', drugCount: 156, color: 'green' },
  { id: '5', name: 'Ophthalmic', nameAr: 'عيون', icon: 'eye', drugCount: 92, color: 'blue' },
  { id: '6', name: 'Orthopedic', nameAr: 'عظام', icon: 'bone', drugCount: 134, color: 'orange' },
];
```

### Dangerous Drugs
```typescript
const dangerousDrugs: DangerousDrug[] = [
  { id: '1', name: 'Warfarin', activeIngredient: 'Warfarin Sodium', riskLevel: 'critical', interactionCount: 47 },
  { id: '2', name: 'Methotrexate', activeIngredient: 'Methotrexate', riskLevel: 'critical', interactionCount: 38 },
  { id: '3', name: 'Digoxin', activeIngredient: 'Digoxin', riskLevel: 'high', interactionCount: 29 },
  { id: '4', name: 'Lithium', activeIngredient: 'Lithium Carbonate', riskLevel: 'high', interactionCount: 24 },
];
```

### Recent Drugs
```typescript
const recentDrugs: Drug[] = [
  {
    id: '1',
    tradeNameEn: 'Panadol Extra',
    tradeNameAr: 'بانادول اكسترا',
    activeIngredient: 'Paracetamol + Caffeine',
    form: 'tablet',
    currentPrice: 45.50,
    oldPrice: 52.00,
    company: 'GSK',
    isNew: true,
    isFavorite: false,
  },
  {
    id: '2',
    tradeNameEn: 'Augmentin 1g',
    tradeNameAr: 'اوجمنتين ١ جرام',
    activeIngredient: 'Amoxicillin + Clavulanic Acid',
    form: 'tablet',
    currentPrice: 185.00,
    company: 'GSK',
    isPopular: true,
    hasInteraction: true,
    isFavorite: true,
  },
  {
    id: '3',
    tradeNameEn: 'Cataflam 50mg',
    tradeNameAr: 'كتافلام ٥٠ مجم',
    activeIngredient: 'Diclofenac Potassium',
    form: 'tablet',
    currentPrice: 67.25,
    oldPrice: 60.00,
    company: 'Novartis',
    isFavorite: false,
  },
];
```
