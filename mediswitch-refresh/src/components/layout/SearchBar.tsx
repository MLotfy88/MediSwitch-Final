import React, { useState } from 'react';
import { Search, Mic, SlidersHorizontal } from 'lucide-react';
import { cn } from '@/lib/utils';

interface SearchBarProps {
  placeholder?: string;
  value?: string;
  onChange?: (value: string) => void;
  onFilterClick?: () => void;
  className?: string;
  isRTL?: boolean;
}

const SearchBar: React.FC<SearchBarProps> = ({
  placeholder = "Search by Trade Name or Active Ingredient...",
  value = "",
  onChange,
  onFilterClick,
  className,
  isRTL = false,
}) => {
  const [isFocused, setIsFocused] = useState(false);

  return (
    <div className={cn("relative", className)}>
      <div
        className={cn(
          "flex items-center gap-3 px-4 py-3.5 rounded-2xl bg-card border-2 transition-all duration-200",
          "card-shadow",
          isFocused ? "border-primary ring-4 ring-primary/10" : "border-transparent"
        )}
      >
        <Search className={cn(
          "w-5 h-5 flex-shrink-0 transition-colors",
          isFocused ? "text-primary" : "text-muted-foreground"
        )} />
        
        <input
          type="text"
          value={value}
          onChange={(e) => onChange?.(e.target.value)}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
          placeholder={placeholder}
          dir={isRTL ? 'rtl' : 'ltr'}
          className={cn(
            "flex-1 bg-transparent text-sm text-foreground placeholder:text-muted-foreground focus:outline-none",
            isRTL && "font-arabic text-right"
          )}
        />

        <div className="flex items-center gap-2">
          <button className="p-2 rounded-xl hover:bg-accent transition-colors">
            <Mic className="w-4 h-4 text-muted-foreground" />
          </button>
          
          <div className="w-px h-6 bg-border" />
          
          <button 
            onClick={onFilterClick}
            className="p-2 rounded-xl bg-primary/10 hover:bg-primary/20 transition-colors"
          >
            <SlidersHorizontal className="w-4 h-4 text-primary" />
          </button>
        </div>
      </div>
    </div>
  );
};

export default SearchBar;
