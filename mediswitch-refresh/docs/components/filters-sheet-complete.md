# Search Filters Sheet - Complete Documentation
# توثيق صفحة الفلاتر - تفاصيل كاملة

---

## 📐 Backdrop (الخلفية المعتمة)

```css
position: fixed inset-0
background: bg-foreground/40       /* 40% opacity of foreground color */
z-index: z-[60]
transition: transition-opacity
```

---

## 📐 Sheet Container

```css
position: fixed
bottom: bottom-0
left: left-0
right: right-0
z-index: z-[70]
background: bg-surface             /* white في Light */
border-radius: rounded-t-3xl       /* 24px top corners */
max-height: max-h-[85vh]           /* 85% of viewport height */
overflow: overflow-hidden
animation: animate-slide-up
```

---

## 📐 Handle (المقبض)

```css
display: flex justify-center
padding: pt-3 pb-2                 /* 12px top, 8px bottom */
```

### Handle Bar
```css
width: w-10                        /* 40px */
height: h-1                        /* 4px */
background: bg-muted-foreground/30 /* 30% opacity */
border-radius: rounded-full
```

---

## 📐 Header

```css
display: flex items-center justify-between
padding: px-4 pb-3                 /* 16px horizontal, 12px bottom */
border-bottom: border-b border-border
```

### Reset Button
```css
font-size: text-sm                 /* 14px */
font-weight: font-medium           /* 500 */
color: text-primary
content: "Reset"
```

### Title
```css
font-size: text-lg                 /* 18px */
font-weight: font-semibold         /* 600 */
color: text-foreground
content: "Filters"
```

### Close Button
```css
padding: p-1.5                     /* 6px */
border-radius: rounded-lg          /* 14px */
transition: transition-colors
hover:background: hover:bg-accent
```

#### X Icon
```css
width: w-5 h-5                     /* 20px */
color: text-foreground
```

---

## 📐 Content Area

```css
overflow-y: overflow-y-auto
max-height: max-h-[calc(85vh-140px)]  /* 85vh - header - footer */
padding: p-4                       /* 16px */
layout: space-y-6                  /* 24px between sections */
```

---

## 📐 Section

### Section Title
```css
font-size: text-sm                 /* 14px */
font-weight: font-semibold         /* 600 */
color: text-foreground
margin-bottom: mb-3                /* 12px */
```

---

## 1️⃣ Price Range Section

### Slider Container
```css
padding: px-2                      /* 8px horizontal */
```

### Slider Component
```css
margin-bottom: mb-2                /* 8px */

/* Track */
height: h-2                        /* 8px */
background: bg-secondary           /* teal color */
border-radius: rounded-full

/* Range */
background: bg-primary             /* blue */

/* Thumb */
width: w-5 h-5                     /* 20px */
border: border-2 border-primary
background: bg-background
border-radius: rounded-full
```

### Price Labels
```css
display: flex justify-between
font-size: text-sm                 /* 14px */
color: text-muted-foreground
```

---

## 2️⃣ Sort By Section

### Options Container
```css
layout: space-y-2                  /* 8px between options */
```

### Sort Option Button

#### Container
```css
width: w-full
display: flex items-center justify-between
padding: px-4 py-3                 /* 16px horizontal, 12px vertical */
border-radius: rounded-xl          /* 18px */
transition: transition-all
```

#### Inactive State
```css
background: bg-accent              /* hsl(210,30%,95%) */
hover:background: hover:bg-accent/80
```

#### Active State
```css
background: bg-primary/10          /* 10% opacity */
border: border border-primary
```

#### Text
```css
font-size: text-sm                 /* 14px */
font-weight: font-medium           /* 500 */
```

##### Inactive
```css
color: text-foreground
```

##### Active
```css
color: text-primary
```

#### Check Icon (Active only)
```css
width: w-4 h-4                     /* 16px */
color: text-primary
```

### Sort Options Data
```typescript
const sortOptions = [
  { id: 'relevance', label: 'Relevance' },
  { id: 'price-low', label: 'Price: Low to High' },
  { id: 'price-high', label: 'Price: High to Low' },
  { id: 'name-az', label: 'Name: A-Z' },
  { id: 'newest', label: 'Newest First' },
];
```

---

## 3️⃣ Drug Form Section

### Chips Container
```css
display: flex flex-wrap
gap: gap-2                         /* 8px */
```

### Form Chip Button

```css
padding: px-4 py-2                 /* 16px horizontal, 8px vertical */
border-radius: rounded-full
font-size: text-sm                 /* 14px */
font-weight: font-medium           /* 500 */
transition: transition-all
```

#### Inactive State
```css
background: bg-accent
color: text-foreground
hover:background: hover:bg-accent/80
```

#### Active State
```css
background: bg-primary
color: text-primary-foreground     /* white */
```

### Form Options Data
```typescript
const forms = [
  { id: 'tablet', label: 'Tablets' },
  { id: 'capsule', label: 'Capsules' },
  { id: 'syrup', label: 'Syrups' },
  { id: 'injection', label: 'Injections' },
  { id: 'cream', label: 'Creams' },
  { id: 'drops', label: 'Drops' },
];
```

---

## 4️⃣ Company Section

### Chips Container
```css
display: flex flex-wrap
gap: gap-2                         /* 8px */
```

### Company Chip Button

```css
padding: px-4 py-2                 /* 16px horizontal, 8px vertical */
border-radius: rounded-full
font-size: text-sm                 /* 14px */
font-weight: font-medium           /* 500 */
transition: transition-all
```

#### Inactive State
```css
background: bg-accent
color: text-foreground
hover:background: hover:bg-accent/80
```

#### Active State
```css
background: bg-secondary           /* teal */
color: text-secondary-foreground   /* white */
```

### Companies Data
```typescript
const companies = [
  'GSK', 
  'Novartis', 
  'Pfizer', 
  'Sanofi', 
  'AstraZeneca', 
  'Bayer', 
  'EVA Pharma', 
  'Amoun'
];
```

---

## 📐 Footer

```css
padding: p-4                       /* 16px */
border-top: border-t border-border
background: bg-surface
```

### Apply Button
```css
width: w-full
padding: py-3.5                    /* 14px vertical */
background: bg-primary
color: text-primary-foreground     /* white */
font-weight: font-semibold         /* 600 */
border-radius: rounded-xl          /* 18px */
transition: transition-colors
hover:background: hover:bg-primary-dark
content: "Apply Filters"
```

---

## 📊 Filter State Interface

```typescript
export interface FilterState {
  priceRange: [number, number];    // Default: [0, 500]
  companies: string[];             // Default: []
  forms: string[];                 // Default: []
  sortBy: string;                  // Default: 'relevance'
}
```

---

## 🎬 Animation

### slide-up keyframe
```css
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

.animate-slide-up {
  animation: slide-up 0.3s ease-out forwards;
}
```

---

## 📐 Complete Visual Layout

```
┌─────────────────────────────────────────┐
│              ━━━━━━━━━━                 │  ← Handle (40px × 4px)
├─────────────────────────────────────────┤
│  Reset          Filters            ✕   │  ← Header
├─────────────────────────────────────────┤
│                                         │
│  Price Range (EGP)                      │
│  ─────────●────────────●─────           │  ← Slider
│  0 EGP                     500 EGP      │
│                                         │
│  Sort By                                │
│  ┌─────────────────────────────────┐    │
│  │ Relevance                    ✓  │    │  ← Active option
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ Price: Low to High              │    │
│  └─────────────────────────────────┘    │
│  ...                                    │
│                                         │
│  Drug Form                              │
│  ┌──────┐ ┌────────┐ ┌──────┐          │
│  │Tablets│ │Capsules│ │Syrups│          │  ← Chips
│  └──────┘ └────────┘ └──────┘          │
│  ...                                    │
│                                         │
│  Company                                │
│  ┌───┐ ┌────────┐ ┌──────┐             │
│  │GSK│ │Novartis│ │Pfizer│              │  ← Chips
│  └───┘ └────────┘ └──────┘             │
│  ...                                    │
│                                         │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │         Apply Filters           │    │  ← Primary Button
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```
