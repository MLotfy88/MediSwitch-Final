import React from 'react';
import { cn } from '@/lib/utils';
import { 
  Heart, 
  Brain, 
  Eye, 
  Bone, 
  Baby, 
  Pill,
  Stethoscope,
  Smile,
  LucideIcon
} from 'lucide-react';

export interface Category {
  id: string;
  name: string;
  nameAr: string;
  icon: string;
  drugCount: number;
  color: string;
}

interface CategoryCardProps {
  category: Category;
  onClick?: () => void;
  isRTL?: boolean;
}

const iconMap: Record<string, LucideIcon> = {
  heart: Heart,
  brain: Brain,
  eye: Eye,
  bone: Bone,
  baby: Baby,
  pill: Pill,
  stethoscope: Stethoscope,
  dental: Smile,
};

const colorMap: Record<string, { bg: string; icon: string; border: string }> = {
  red: { bg: 'bg-danger-soft', icon: 'text-danger', border: 'border-danger/20' },
  blue: { bg: 'bg-info-soft', icon: 'text-info', border: 'border-info/20' },
  purple: { bg: 'bg-accent', icon: 'text-primary', border: 'border-primary/20' },
  green: { bg: 'bg-success-soft', icon: 'text-success', border: 'border-success/20' },
  orange: { bg: 'bg-warning-soft', icon: 'text-warning', border: 'border-warning/30' },
  teal: { bg: 'bg-secondary/10', icon: 'text-secondary', border: 'border-secondary/20' },
};

const CategoryCard: React.FC<CategoryCardProps> = ({ category, onClick, isRTL = false }) => {
  const Icon = iconMap[category.icon] || Pill;
  const colors = colorMap[category.color] || colorMap.blue;

  return (
    <button
      onClick={onClick}
      className={cn(
        "flex flex-col items-center gap-2 p-4 rounded-2xl border transition-all duration-200",
        "hover:scale-105 active:scale-95 min-w-[88px]",
        colors.bg,
        colors.border
      )}
    >
      <div className={cn("p-2.5 rounded-xl", colors.bg)}>
        <Icon className={cn("w-6 h-6", colors.icon)} />
      </div>
      <div className="text-center">
        <p className={cn(
          "text-xs font-semibold text-foreground truncate max-w-[72px]",
          isRTL && "font-arabic"
        )}>
          {isRTL ? category.nameAr : category.name}
        </p>
        <p className={cn(
          "text-[10px] text-muted-foreground",
          isRTL && "font-arabic"
        )}>
          {isRTL ? `${category.drugCount} دواء` : `${category.drugCount} drugs`}
        </p>
      </div>
    </button>
  );
};

export default CategoryCard;
