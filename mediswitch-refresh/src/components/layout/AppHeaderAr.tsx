import React from 'react';
import { Bell, RefreshCw } from 'lucide-react';
import { cn } from '@/lib/utils';

interface AppHeaderArProps {
  title?: string;
  lastUpdated?: string;
  notificationCount?: number;
  onNotificationClick?: () => void;
}

const AppHeaderAr: React.FC<AppHeaderArProps> = ({
  title = "ميدي سويتش",
  lastUpdated = "٥ ديسمبر ٢٠٢٤",
  notificationCount = 3,
  onNotificationClick,
}) => {
  return (
    <header className="sticky top-0 z-50 bg-surface/95 backdrop-blur-lg border-b border-border px-4 py-3">
      <div className="flex items-center justify-between">
        {/* Notifications - RTL: appears on left */}
        <button
          onClick={onNotificationClick}
          className="relative p-2.5 rounded-xl bg-accent hover:bg-accent/80 transition-colors"
        >
          <Bell className="w-5 h-5 text-foreground" />
          {notificationCount > 0 && (
            <span className={cn(
              "absolute -top-1 -left-1 min-w-[18px] h-[18px] rounded-full",
              "bg-danger text-danger-foreground text-[10px] font-bold",
              "flex items-center justify-center px-1"
            )}>
              {notificationCount > 9 ? '+٩' : notificationCount}
            </span>
          )}
        </button>

        {/* Logo & Title - RTL: appears on right */}
        <div className="flex items-center gap-3">
          <div>
            <h1 className="text-lg font-bold text-foreground font-arabic">{title}</h1>
            <div className="flex items-center gap-1 text-xs text-muted-foreground justify-end">
              <span className="font-arabic">آخر تحديث {lastUpdated}</span>
              <RefreshCw className="w-3 h-3" />
            </div>
          </div>
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary to-primary-dark flex items-center justify-center shadow-md">
            <svg className="w-6 h-6 text-primary-foreground" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z" />
              <path d="M12 5v14" />
              <path d="M5 12h14" />
            </svg>
          </div>
        </div>
      </div>
    </header>
  );
};

export default AppHeaderAr;
