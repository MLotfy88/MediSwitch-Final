import React from 'react';
import { 
  User, 
  Settings, 
  Bell, 
  Shield, 
  HelpCircle, 
  LogOut,
  ChevronRight,
  Moon,
  Globe,
  Mail,
  Phone
} from 'lucide-react';
import { useTheme } from '@/hooks/useTheme';
import { cn } from '@/lib/utils';
import { Switch } from '@/components/ui/switch';

interface MenuItem {
  id: string;
  labelEn: string;
  labelAr: string;
  icon: React.ElementType;
  type: 'link' | 'toggle';
  value?: boolean;
}

const menuItems: MenuItem[] = [
  { id: 'notifications', labelEn: 'Notifications', labelAr: 'الإشعارات', icon: Bell, type: 'toggle', value: true },
  { id: 'darkMode', labelEn: 'Dark Mode', labelAr: 'الوضع الداكن', icon: Moon, type: 'toggle' },
  { id: 'language', labelEn: 'Language', labelAr: 'اللغة', icon: Globe, type: 'link' },
  { id: 'privacy', labelEn: 'Privacy & Security', labelAr: 'الخصوصية والأمان', icon: Shield, type: 'link' },
  { id: 'help', labelEn: 'Help & Support', labelAr: 'المساعدة والدعم', icon: HelpCircle, type: 'link' },
  { id: 'settings', labelEn: 'Settings', labelAr: 'الإعدادات', icon: Settings, type: 'link' },
];

interface ProfileScreenProps {
  onSettingsClick?: () => void;
}

const ProfileScreen: React.FC<ProfileScreenProps> = ({ onSettingsClick }) => {
  const { language, isRTL, theme, toggleTheme, toggleLanguage } = useTheme();

  return (
    <div className="pb-24 bg-background min-h-screen">
      {/* Header */}
      <div className="bg-gradient-to-br from-primary via-primary to-primary-dark text-primary-foreground px-4 py-6">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-primary-foreground/20 flex items-center justify-center">
            <User className="w-8 h-8" />
          </div>
          <div>
            <h1 className="text-xl font-bold">
              {language === 'ar' ? 'مستخدم MediSwitch' : 'MediSwitch User'}
            </h1>
            <p className="text-primary-foreground/70 text-sm">
              {language === 'ar' ? 'صيدلي' : 'Pharmacist'}
            </p>
          </div>
        </div>

        {/* Stats */}
        <div className="flex gap-4 mt-6">
          <div className="flex-1 bg-primary-foreground/10 rounded-xl p-3 text-center">
            <p className="text-2xl font-bold">24</p>
            <p className="text-xs text-primary-foreground/70">
              {language === 'ar' ? 'المفضلة' : 'Favorites'}
            </p>
          </div>
          <div className="flex-1 bg-primary-foreground/10 rounded-xl p-3 text-center">
            <p className="text-2xl font-bold">156</p>
            <p className="text-xs text-primary-foreground/70">
              {language === 'ar' ? 'عمليات البحث' : 'Searches'}
            </p>
          </div>
          <div className="flex-1 bg-primary-foreground/10 rounded-xl p-3 text-center">
            <p className="text-2xl font-bold">89</p>
            <p className="text-xs text-primary-foreground/70">
              {language === 'ar' ? 'الأدوية المعروضة' : 'Viewed'}
            </p>
          </div>
        </div>
      </div>

      {/* Menu */}
      <div className="px-4 py-4">
        <div className="bg-card rounded-xl overflow-hidden card-shadow">
          {menuItems.map((item, index) => {
            const Icon = item.icon;
            const isDarkModeItem = item.id === 'darkMode';
            const isLanguageItem = item.id === 'language';
            
            return (
              <button
                key={item.id}
                onClick={() => {
                  if (isDarkModeItem) toggleTheme();
                  if (isLanguageItem) toggleLanguage();
                  if (item.id === 'settings') onSettingsClick?.();
                }}
                className={cn(
                  "w-full flex items-center justify-between px-4 py-4 transition-colors hover:bg-muted/50",
                  index !== menuItems.length - 1 && "border-b border-border"
                )}
                dir={isRTL ? 'rtl' : 'ltr'}
              >
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-lg bg-muted flex items-center justify-center">
                    <Icon className="w-4 h-4 text-foreground" />
                  </div>
                  <span className="font-medium text-foreground">
                    {language === 'ar' ? item.labelAr : item.labelEn}
                  </span>
                </div>
                
                {item.type === 'toggle' ? (
                  <Switch 
                    checked={isDarkModeItem ? theme === 'dark' : item.value} 
                    onCheckedChange={() => {
                      if (isDarkModeItem) toggleTheme();
                    }}
                  />
                ) : (
                  <div className="flex items-center gap-2">
                    {isLanguageItem && (
                      <span className="text-sm text-muted-foreground">
                        {language === 'ar' ? 'العربية' : 'English'}
                      </span>
                    )}
                    <ChevronRight className={cn("w-4 h-4 text-muted-foreground", isRTL && "rotate-180")} />
                  </div>
                )}
              </button>
            );
          })}
        </div>

        {/* Logout */}
        <button className="w-full mt-4 flex items-center justify-center gap-2 px-4 py-4 bg-danger/10 text-danger rounded-xl font-medium hover:bg-danger/20 transition-colors">
          <LogOut className="w-5 h-5" />
          {language === 'ar' ? 'تسجيل الخروج' : 'Sign Out'}
        </button>

        {/* Version */}
        <p className="text-center text-xs text-muted-foreground mt-6">
          MediSwitch v1.0.0
        </p>
      </div>
    </div>
  );
};

export default ProfileScreen;
