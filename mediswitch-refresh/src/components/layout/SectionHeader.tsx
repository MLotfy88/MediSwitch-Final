import React from 'react';
import { ChevronRight } from 'lucide-react';
import { cn } from '@/lib/utils';

interface SectionHeaderProps {
  title: string;
  subtitle?: string;
  icon?: React.ReactNode;
  iconColor?: string;
  showSeeAll?: boolean;
  onSeeAllClick?: () => void;
  className?: string;
}

const SectionHeader: React.FC<SectionHeaderProps> = ({
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
      <div className="flex items-center gap-2">
        {icon && (
          <div className={cn("w-8 h-8 rounded-lg flex items-center justify-center bg-accent", iconColor)}>
            {icon}
          </div>
        )}
        <div>
          <h2 className="text-base font-semibold text-foreground">{title}</h2>
          {subtitle && (
            <p className="text-xs text-muted-foreground">{subtitle}</p>
          )}
        </div>
      </div>
      
      {showSeeAll && (
        <button
          onClick={onSeeAllClick}
          className="flex items-center gap-0.5 text-sm font-medium text-primary hover:text-primary-dark transition-colors"
        >
          See all
          <ChevronRight className="w-4 h-4" />
        </button>
      )}
    </div>
  );
};

export default SectionHeader;
