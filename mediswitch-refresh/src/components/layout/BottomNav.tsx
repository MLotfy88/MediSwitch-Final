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
