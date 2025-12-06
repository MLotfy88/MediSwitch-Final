import React from 'react';
import { Moon, Sun, Globe } from 'lucide-react';
import { useTheme } from '@/hooks/useTheme';
import { cn } from '@/lib/utils';

const ThemeToggle: React.FC = () => {
  const { theme, toggleTheme, language, toggleLanguage } = useTheme();

  return (
    <div className="fixed top-4 right-4 z-[100] flex gap-2">
      {/* Language Toggle */}
      <button
        onClick={toggleLanguage}
        className={cn(
          "p-2.5 rounded-xl transition-all shadow-lg",
          "bg-surface border border-border hover:bg-accent"
        )}
        aria-label="Toggle language"
      >
        <div className="flex items-center gap-1.5">
          <Globe className="w-4 h-4 text-foreground" />
          <span className="text-xs font-semibold text-foreground">
            {language === 'en' ? 'عربي' : 'EN'}
          </span>
        </div>
      </button>

      {/* Theme Toggle */}
      <button
        onClick={toggleTheme}
        className={cn(
          "p-2.5 rounded-xl transition-all shadow-lg",
          "bg-surface border border-border hover:bg-accent"
        )}
        aria-label="Toggle theme"
      >
        {theme === 'light' ? (
          <Moon className="w-5 h-5 text-foreground" />
        ) : (
          <Sun className="w-5 h-5 text-foreground" />
        )}
      </button>
    </div>
  );
};

export default ThemeToggle;
