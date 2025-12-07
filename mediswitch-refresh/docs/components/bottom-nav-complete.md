# Bottom Navigation - Complete Pixel-Perfect Documentation
# توثيق شريط التنقل السفلي - تفاصيل بكسل مثالية

---

## 📐 Container (الحاوية الرئيسية)

```css
/* Positioning */
position: fixed
bottom: bottom-0
left: left-1/2
transform: -translate-x-1/2

/* Sizing */
width: w-full
max-width: max-w-[430px]           /* 430px - عرض الجهاز */

/* Background */
background: bg-surface/95          /* rgba(255,255,255,0.95) في Light */
                                   /* rgba(28,34,45,0.95) في Dark */
backdrop-filter: backdrop-blur-lg  /* blur(16px) */

/* Border */
border-top: border-t border-border /* 1px solid hsl(210,20%,90%) */

/* Safe Area */
padding-bottom: safe-area-bottom   /* env(safe-area-inset-bottom) */
```

---

## 📐 Nav Container

```css
display: flex
align-items: items-center
justify-content: justify-around
padding: py-2 px-2                 /* 8px vertical, 8px horizontal */
```

---

## 🔘 Nav Button

### Container
```css
display: flex flex-col
align-items: items-center
gap: gap-1                         /* 4px */
padding: px-4 py-2                 /* 16px horizontal, 8px vertical */
border-radius: rounded-xl          /* 18px */
transition: transition-all duration-200
```

### Inactive State
```css
background: transparent
hover:background: hover:bg-accent  /* hsl(210,30%,95%) */
```

### Active State
```css
background: bg-primary/10          /* 10% opacity of primary */
```

---

## 🎨 Icon Styling

```css
width: w-5 h-5                     /* 20px */
transition: transition-colors
```

### Inactive State
```css
color: text-muted-foreground       /* hsl(215, 15%, 50%) */
```

### Active State
```css
color: text-primary                /* hsl(210, 90%, 45%) */
```

---

## 🔤 Label Styling

```css
font-size: text-[10px]             /* 10px */
font-weight: font-medium           /* 500 */
transition: transition-colors
```

### Inactive State
```css
color: text-muted-foreground       /* hsl(215, 15%, 50%) */
```

### Active State
```css
color: text-primary                /* hsl(210, 90%, 45%) */
```

---

## 📋 Nav Items Data

```typescript
interface NavItem {
  id: string;
  icon: React.ElementType;
  labelEn: string;
  labelAr: string;
}

const navItems: NavItem[] = [
  { 
    id: 'home', 
    icon: Home, 
    labelEn: 'Home', 
    labelAr: 'الرئيسية' 
  },
  { 
    id: 'search', 
    icon: Search, 
    labelEn: 'Search', 
    labelAr: 'بحث' 
  },
  { 
    id: 'history', 
    icon: History, 
    labelEn: 'History', 
    labelAr: 'السجل' 
  },
  { 
    id: 'favorites', 
    icon: Heart, 
    labelEn: 'Favorites', 
    labelAr: 'المفضلة' 
  },
  { 
    id: 'profile', 
    icon: User, 
    labelEn: 'Profile', 
    labelAr: 'الحساب' 
  },
];
```

---

## 📊 Visual Layout

```
┌─────────────────────────────────────────────────────────────┐
│                         BottomNav                            │
│  ┌─────────┬─────────┬─────────┬─────────┬─────────┐        │
│  │  Home   │ Search  │ History │Favorites│ Profile │        │
│  │   🏠    │   🔍    │   ⏰    │   ❤️    │   👤    │        │
│  │  Home   │ Search  │ History │Favorites│ Profile │        │
│  └─────────┴─────────┴─────────┴─────────┴─────────┘        │
│                        safe-area                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📏 Exact Measurements

| Element | Value | Pixels |
|---------|-------|--------|
| **Container Height** | ~56px | py-2 + content |
| **Button Width** | ~20% | justify-around |
| **Button Padding X** | px-4 | 16px |
| **Button Padding Y** | py-2 | 8px |
| **Button Border Radius** | rounded-xl | 18px |
| **Icon Size** | w-5 h-5 | 20px |
| **Gap (icon to label)** | gap-1 | 4px |
| **Label Font Size** | text-[10px] | 10px |

---

## 🔧 Component Code

```tsx
import React from 'react';
import { Home, Search, Heart, User, History } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useTheme } from '@/hooks/useTheme';

interface NavItem {
  id: string;
  icon: React.ElementType;
  labelEn: string;
  labelAr: string;
}

const navItems: NavItem[] = [
  { id: 'home', icon: Home, labelEn: 'Home', labelAr: 'الرئيسية' },
  { id: 'search', icon: Search, labelEn: 'Search', labelAr: 'بحث' },
  { id: 'history', icon: History, labelEn: 'History', labelAr: 'السجل' },
  { id: 'favorites', icon: Heart, labelEn: 'Favorites', labelAr: 'المفضلة' },
  { id: 'profile', icon: User, labelEn: 'Profile', labelAr: 'الحساب' },
];

interface BottomNavProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

const BottomNav: React.FC<BottomNavProps> = ({ activeTab, onTabChange }) => {
  const { language } = useTheme();
  
  return (
    <nav className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[430px] bg-surface/95 backdrop-blur-lg border-t border-border safe-area-bottom">
      <div className="flex items-center justify-around py-2 px-2">
        {navItems.map((item) => {
          const isActive = activeTab === item.id;
          const Icon = item.icon;
          
          return (
            <button
              key={item.id}
              onClick={() => onTabChange(item.id)}
              className={cn(
                "flex flex-col items-center gap-1 px-4 py-2 rounded-xl transition-all duration-200",
                isActive ? "bg-primary/10" : "hover:bg-accent"
              )}
            >
              <Icon
                className={cn(
                  "w-5 h-5 transition-colors",
                  isActive ? "text-primary" : "text-muted-foreground"
                )}
              />
              <span
                className={cn(
                  "text-[10px] font-medium transition-colors",
                  isActive ? "text-primary" : "text-muted-foreground"
                )}
              >
                {language === 'ar' ? item.labelAr : item.labelEn}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};

export default BottomNav;
```

---

## 🌐 RTL Support

- النصوص تتغير تلقائياً حسب اللغة
- لا حاجة لتغيير ترتيب الأيقونات (justify-around يعمل في كلا الاتجاهين)

---

## 📱 Safe Area CSS

```css
.safe-area-bottom {
  padding-bottom: env(safe-area-inset-bottom);
}
```

هذا يضمن عدم تداخل Bottom Nav مع Home Indicator في أجهزة iPhone الحديثة.
