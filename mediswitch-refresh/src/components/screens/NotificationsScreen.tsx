import React from 'react';
import { Bell, TrendingDown, TrendingUp, AlertTriangle, Pill, Check } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { useTheme } from '@/hooks/useTheme';
import { cn } from '@/lib/utils';

interface Notification {
  id: string;
  type: 'price_drop' | 'price_up' | 'new_drug' | 'interaction_alert';
  titleEn: string;
  titleAr: string;
  descriptionEn: string;
  descriptionAr: string;
  time: string;
  isRead: boolean;
}

const mockNotifications: Notification[] = [
  {
    id: '1',
    type: 'price_drop',
    titleEn: 'Price Drop Alert',
    titleAr: 'تنبيه انخفاض السعر',
    descriptionEn: 'Augmentin 1g price dropped by 5%',
    descriptionAr: 'انخفض سعر اوجمنتين ١ جرام بنسبة ٥٪',
    time: '2h ago',
    isRead: false,
  },
  {
    id: '2',
    type: 'new_drug',
    titleEn: 'New Drug Added',
    titleAr: 'دواء جديد',
    descriptionEn: 'Nexium 40mg is now available in the database',
    descriptionAr: 'نيكسيوم ٤٠ مجم متاح الآن في قاعدة البيانات',
    time: '5h ago',
    isRead: false,
  },
  {
    id: '3',
    type: 'interaction_alert',
    titleEn: 'Interaction Warning',
    titleAr: 'تحذير تفاعل دوائي',
    descriptionEn: 'New interaction found for Warfarin',
    descriptionAr: 'تم اكتشاف تفاعل جديد للوارفارين',
    time: '1d ago',
    isRead: true,
  },
  {
    id: '4',
    type: 'price_up',
    titleEn: 'Price Increase',
    titleAr: 'ارتفاع السعر',
    descriptionEn: 'Concor 5mg price increased by 8%',
    descriptionAr: 'ارتفع سعر كونكور ٥ مجم بنسبة ٨٪',
    time: '2d ago',
    isRead: true,
  },
];

const NotificationsScreen: React.FC = () => {
  const { language, isRTL } = useTheme();

  const getNotificationIcon = (type: Notification['type']) => {
    switch (type) {
      case 'price_drop':
        return { icon: TrendingDown, color: 'bg-success/10 text-success' };
      case 'price_up':
        return { icon: TrendingUp, color: 'bg-danger/10 text-danger' };
      case 'new_drug':
        return { icon: Pill, color: 'bg-primary/10 text-primary' };
      case 'interaction_alert':
        return { icon: AlertTriangle, color: 'bg-warning/10 text-warning' };
    }
  };

  const unreadCount = mockNotifications.filter(n => !n.isRead).length;

  return (
    <div className="pb-24 bg-background min-h-screen">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-surface/95 backdrop-blur-lg border-b border-border px-4 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
              <Bell className="w-5 h-5 text-primary" />
            </div>
            <div>
              <h1 className="text-lg font-bold text-foreground">
                {language === 'ar' ? 'الإشعارات' : 'Notifications'}
              </h1>
              <p className="text-xs text-muted-foreground">
                {language === 'ar' 
                  ? `${unreadCount} إشعارات غير مقروءة`
                  : `${unreadCount} unread notifications`}
              </p>
            </div>
          </div>
          {unreadCount > 0 && (
            <button className="text-sm text-primary font-medium">
              {language === 'ar' ? 'تحديد الكل كمقروء' : 'Mark all read'}
            </button>
          )}
        </div>
      </div>

      {/* Notifications List */}
      <div className="divide-y divide-border">
        {mockNotifications.map((notification) => {
          const { icon: Icon, color } = getNotificationIcon(notification.type);
          return (
            <div 
              key={notification.id}
              className={cn(
                "px-4 py-4 flex gap-3 transition-colors",
                !notification.isRead && "bg-primary/5"
              )}
              dir={isRTL ? 'rtl' : 'ltr'}
            >
              <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0", color)}>
                <Icon className="w-5 h-5" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <h3 className="font-semibold text-foreground text-sm">
                    {language === 'ar' ? notification.titleAr : notification.titleEn}
                  </h3>
                  {!notification.isRead && (
                    <div className="w-2 h-2 rounded-full bg-primary" />
                  )}
                </div>
                <p className="text-sm text-muted-foreground mb-1">
                  {language === 'ar' ? notification.descriptionAr : notification.descriptionEn}
                </p>
                <span className="text-xs text-muted-foreground">{notification.time}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default NotificationsScreen;
