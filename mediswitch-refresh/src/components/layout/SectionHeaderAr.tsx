import React from 'react';
import { ChevronLeft } from 'lucide-react';
import { cn } from '@/lib/utils';

interface SectionHeaderArProps {
  title: string;
  subtitle?: string;
  icon?: React.ReactNode;
  iconColor?: string;
  showSeeAll?: boolean;
  onSeeAllClick?: () => void;
  className?: string;
}

const SectionHeaderAr: React.FC<SectionHeaderArProps> = ({
  title,
  subtitle,
  icon,
  iconColor = "text-primary",
  showSeeAll = true,
  onSeeAllClick,
  className,
}) => {
  return (
    <div className={cn("flex items-center justify-between", className)}>
      {showSeeAll && (
        <button
          onClick={onSeeAllClick}
          className="flex items-center gap-0.5 text-sm font-medium text-primary hover:text-primary-dark transition-colors"
        >
          <ChevronLeft className="w-4 h-4" />
          <span className="font-arabic">عرض الكل</span>
        </button>
      )}
      
      <div className="flex items-center gap-2">
        <div>
          <h2 className="text-base font-semibold text-foreground font-arabic text-right">{title}</h2>
          {subtitle && (
            <p className="text-xs text-muted-foreground font-arabic text-right">{subtitle}</p>
          )}
        </div>
        {icon && (
          <div className={cn("w-8 h-8 rounded-lg flex items-center justify-center bg-accent", iconColor)}>
            {icon}
          </div>
        )}
      </div>
    </div>
  );
};

export default SectionHeaderAr;
