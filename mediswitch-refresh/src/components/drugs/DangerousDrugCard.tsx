import React from 'react';
import { AlertTriangle, Skull } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface DangerousDrug {
  id: string;
  name: string;
  activeIngredient: string;
  riskLevel: 'high' | 'critical';
  interactionCount: number;
}

interface DangerousDrugCardProps {
  drug: DangerousDrug;
  onClick?: () => void;
  isRTL?: boolean;
}

const DangerousDrugCard: React.FC<DangerousDrugCardProps> = ({ drug, onClick, isRTL = false }) => {
  const isCritical = drug.riskLevel === 'critical';

  return (
    <button
      onClick={onClick}
      className={cn(
        "flex flex-col gap-2 p-4 rounded-2xl min-w-[140px] border transition-all duration-200",
        "hover:scale-[1.02] active:scale-[0.98]",
        isCritical 
          ? "bg-danger/10 border-danger/30" 
          : "bg-warning-soft border-warning/30"
      )}
    >
      <div className={cn(
        "w-10 h-10 rounded-xl flex items-center justify-center",
        isCritical ? "bg-danger/20" : "bg-warning/20",
        isRTL && "self-end"
      )}>
        {isCritical ? (
          <Skull className="w-5 h-5 text-danger" />
        ) : (
          <AlertTriangle className="w-5 h-5 text-warning" />
        )}
      </div>
      
      <div className={cn(isRTL ? "text-right" : "text-left")}>
        <p className={cn(
          "font-semibold text-sm truncate max-w-[120px]",
          isCritical ? "text-danger" : "text-warning-foreground",
          isRTL && "font-arabic"
        )}>
          {drug.name}
        </p>
        <p className="text-xs text-muted-foreground truncate max-w-[120px]">
          {drug.activeIngredient}
        </p>
      </div>

      <div className={cn(
        "flex items-center gap-1 px-2 py-1 rounded-full text-[10px] font-bold",
        isCritical ? "bg-danger/20 text-danger" : "bg-warning/20 text-warning-foreground",
        isRTL ? "self-end flex-row-reverse font-arabic" : "self-start"
      )}>
        <AlertTriangle className="w-3 h-3" />
        {isRTL ? `${drug.interactionCount} تفاعلات` : `${drug.interactionCount} interactions`}
      </div>
    </button>
  );
};

export default DangerousDrugCard;
