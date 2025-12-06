import React, { useState } from 'react';
import { 
  Settings,
  Bell,
  Moon,
  Globe,
  Shield,
  Database,
  Trash2,
  Download,
  Upload,
  Info,
  ChevronRight,
  Smartphone,
  Palette,
  Volume2,
  Vibrate,
  Clock,
  MapPin,
  CreditCard,
  FileText,
  MessageSquare,
  Star,
  ArrowLeft
} from 'lucide-react';
import { useTheme } from '@/hooks/useTheme';
import { cn } from '@/lib/utils';
import { Switch } from '@/components/ui/switch';
import { Slider } from '@/components/ui/slider';

interface SettingItem {
  id: string;
  labelEn: string;
  labelAr: string;
  descriptionEn?: string;
  descriptionAr?: string;
  icon: React.ElementType;
  type: 'toggle' | 'link' | 'select' | 'slider';
  value?: boolean | number | string;
}

interface SettingSection {
  titleEn: string;
  titleAr: string;
  items: SettingItem[];
}

const settingSections: SettingSection[] = [
  {
    titleEn: 'Notifications',
    titleAr: 'الإشعارات',
    items: [
      { id: 'pushNotifications', labelEn: 'Push Notifications', labelAr: 'الإشعارات الفورية', icon: Bell, type: 'toggle', value: true },
      { id: 'priceAlerts', labelEn: 'Price Change Alerts', labelAr: 'تنبيهات تغيير الأسعار', descriptionEn: 'Get notified when drug prices change', descriptionAr: 'احصل على إشعار عند تغيير أسعار الأدوية', icon: CreditCard, type: 'toggle', value: true },
      { id: 'newDrugAlerts', labelEn: 'New Drug Alerts', labelAr: 'تنبيهات الأدوية الجديدة', icon: Star, type: 'toggle', value: false },
      { id: 'interactionAlerts', labelEn: 'Interaction Warnings', labelAr: 'تحذيرات التفاعلات', descriptionEn: 'Critical safety alerts', descriptionAr: 'تنبيهات السلامة الحرجة', icon: Shield, type: 'toggle', value: true },
    ]
  },
  {
    titleEn: 'Appearance',
    titleAr: 'المظهر',
    items: [
      { id: 'darkMode', labelEn: 'Dark Mode', labelAr: 'الوضع الداكن', icon: Moon, type: 'toggle' },
      { id: 'language', labelEn: 'Language', labelAr: 'اللغة', icon: Globe, type: 'select', value: 'en' },
      { id: 'fontSize', labelEn: 'Font Size', labelAr: 'حجم الخط', icon: FileText, type: 'slider', value: 16 },
    ]
  },
  {
    titleEn: 'Sound & Haptics',
    titleAr: 'الصوت والاهتزاز',
    items: [
      { id: 'sounds', labelEn: 'Sound Effects', labelAr: 'المؤثرات الصوتية', icon: Volume2, type: 'toggle', value: true },
      { id: 'haptics', labelEn: 'Haptic Feedback', labelAr: 'الاهتزاز', icon: Vibrate, type: 'toggle', value: true },
    ]
  },
  {
    titleEn: 'Data & Storage',
    titleAr: 'البيانات والتخزين',
    items: [
      { id: 'offlineMode', labelEn: 'Offline Mode', labelAr: 'الوضع دون اتصال', descriptionEn: 'Download drug database for offline use', descriptionAr: 'تحميل قاعدة بيانات الأدوية للاستخدام دون اتصال', icon: Download, type: 'toggle', value: false },
      { id: 'autoSync', labelEn: 'Auto Sync', labelAr: 'المزامنة التلقائية', descriptionEn: 'Sync data when connected to WiFi', descriptionAr: 'مزامنة البيانات عند الاتصال بالواي فاي', icon: Upload, type: 'toggle', value: true },
      { id: 'cacheSize', labelEn: 'Cache Size', labelAr: 'حجم الذاكرة المؤقتة', icon: Database, type: 'link' },
      { id: 'clearHistory', labelEn: 'Clear Search History', labelAr: 'مسح سجل البحث', icon: Trash2, type: 'link' },
    ]
  },
  {
    titleEn: 'Location',
    titleAr: 'الموقع',
    items: [
      { id: 'location', labelEn: 'Default Location', labelAr: 'الموقع الافتراضي', descriptionEn: 'Egypt', descriptionAr: 'مصر', icon: MapPin, type: 'link' },
      { id: 'currency', labelEn: 'Currency', labelAr: 'العملة', descriptionEn: 'EGP', descriptionAr: 'جنيه مصري', icon: CreditCard, type: 'link' },
    ]
  },
  {
    titleEn: 'About',
    titleAr: 'حول التطبيق',
    items: [
      { id: 'version', labelEn: 'App Version', labelAr: 'إصدار التطبيق', descriptionEn: '1.0.0', descriptionAr: '١.٠.٠', icon: Info, type: 'link' },
      { id: 'terms', labelEn: 'Terms of Service', labelAr: 'شروط الاستخدام', icon: FileText, type: 'link' },
      { id: 'privacy', labelEn: 'Privacy Policy', labelAr: 'سياسة الخصوصية', icon: Shield, type: 'link' },
      { id: 'feedback', labelEn: 'Send Feedback', labelAr: 'إرسال ملاحظات', icon: MessageSquare, type: 'link' },
      { id: 'rate', labelEn: 'Rate the App', labelAr: 'تقييم التطبيق', icon: Star, type: 'link' },
    ]
  },
];

interface SettingsScreenProps {
  onBack?: () => void;
}

const SettingsScreen: React.FC<SettingsScreenProps> = ({ onBack }) => {
  const { language, isRTL, theme, toggleTheme, toggleLanguage } = useTheme();
  const [settings, setSettings] = useState<Record<string, boolean | number | string>>({
    pushNotifications: true,
    priceAlerts: true,
    newDrugAlerts: false,
    interactionAlerts: true,
    sounds: true,
    haptics: true,
    offlineMode: false,
    autoSync: true,
    fontSize: 16,
  });

  const handleToggle = (id: string) => {
    if (id === 'darkMode') {
      toggleTheme();
    } else if (id === 'language') {
      toggleLanguage();
    } else {
      setSettings(prev => ({ ...prev, [id]: !prev[id] }));
    }
  };

  const handleSliderChange = (id: string, value: number[]) => {
    setSettings(prev => ({ ...prev, [id]: value[0] }));
  };

  return (
    <div className="pb-24 bg-background min-h-screen">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-surface/95 backdrop-blur-lg border-b border-border px-4 py-4">
        <div className="flex items-center gap-3">
          {onBack && (
            <button 
              onClick={onBack}
              className="p-2 rounded-xl bg-muted hover:bg-muted/80 transition-colors"
            >
              <ArrowLeft className={cn("w-5 h-5 text-foreground", isRTL && "rotate-180")} />
            </button>
          )}
          <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
            <Settings className="w-5 h-5 text-primary" />
          </div>
          <div>
            <h1 className="text-lg font-bold text-foreground">
              {language === 'ar' ? 'الإعدادات' : 'Settings'}
            </h1>
            <p className="text-xs text-muted-foreground">
              {language === 'ar' ? 'تخصيص تجربتك' : 'Customize your experience'}
            </p>
          </div>
        </div>
      </div>

      {/* Settings Sections */}
      <div className="px-4 py-4 space-y-6">
        {settingSections.map((section) => (
          <div key={section.titleEn}>
            <h2 className="text-sm font-semibold text-muted-foreground mb-3 px-1" dir={isRTL ? 'rtl' : 'ltr'}>
              {language === 'ar' ? section.titleAr : section.titleEn}
            </h2>
            <div className="bg-card rounded-xl overflow-hidden card-shadow">
              {section.items.map((item, index) => {
                const Icon = item.icon;
                const isDarkModeItem = item.id === 'darkMode';
                const isLanguageItem = item.id === 'language';
                const isSliderItem = item.type === 'slider';
                const currentValue = isDarkModeItem 
                  ? theme === 'dark' 
                  : settings[item.id] ?? item.value;
                
                return (
                  <div
                    key={item.id}
                    className={cn(
                      "px-4 py-4 transition-colors",
                      item.type === 'link' && "hover:bg-muted/50 cursor-pointer",
                      index !== section.items.length - 1 && "border-b border-border"
                    )}
                    dir={isRTL ? 'rtl' : 'ltr'}
                    onClick={() => {
                      if (item.type === 'link') {
                        // Handle link click
                      }
                    }}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3 flex-1">
                        <div className="w-9 h-9 rounded-lg bg-muted flex items-center justify-center flex-shrink-0">
                          <Icon className="w-4 h-4 text-foreground" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <span className="font-medium text-foreground block">
                            {language === 'ar' ? item.labelAr : item.labelEn}
                          </span>
                          {(item.descriptionEn || item.descriptionAr) && (
                            <span className="text-xs text-muted-foreground">
                              {language === 'ar' ? item.descriptionAr : item.descriptionEn}
                            </span>
                          )}
                        </div>
                      </div>
                      
                      {item.type === 'toggle' && (
                        <Switch 
                          checked={currentValue as boolean} 
                          onCheckedChange={() => handleToggle(item.id)}
                        />
                      )}
                      
                      {item.type === 'select' && (
                        <div className="flex items-center gap-2">
                          <span className="text-sm text-muted-foreground">
                            {isLanguageItem && (language === 'ar' ? 'العربية' : 'English')}
                          </span>
                          <ChevronRight className={cn("w-4 h-4 text-muted-foreground", isRTL && "rotate-180")} />
                        </div>
                      )}
                      
                      {item.type === 'link' && (
                        <ChevronRight className={cn("w-4 h-4 text-muted-foreground", isRTL && "rotate-180")} />
                      )}
                    </div>
                    
                    {isSliderItem && (
                      <div className="mt-3 px-1">
                        <Slider
                          value={[settings[item.id] as number || 16]}
                          onValueChange={(value) => handleSliderChange(item.id, value)}
                          min={12}
                          max={24}
                          step={1}
                          className="w-full"
                        />
                        <div className="flex justify-between mt-1 text-xs text-muted-foreground">
                          <span>{language === 'ar' ? 'صغير' : 'Small'}</span>
                          <span>{settings[item.id] || 16}px</span>
                          <span>{language === 'ar' ? 'كبير' : 'Large'}</span>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        ))}

        {/* Danger Zone */}
        <div>
          <h2 className="text-sm font-semibold text-danger mb-3 px-1" dir={isRTL ? 'rtl' : 'ltr'}>
            {language === 'ar' ? 'منطقة الخطر' : 'Danger Zone'}
          </h2>
          <div className="bg-danger/5 border border-danger/20 rounded-xl overflow-hidden">
            <button 
              className="w-full flex items-center gap-3 px-4 py-4 text-danger hover:bg-danger/10 transition-colors"
              dir={isRTL ? 'rtl' : 'ltr'}
            >
              <div className="w-9 h-9 rounded-lg bg-danger/10 flex items-center justify-center">
                <Trash2 className="w-4 h-4" />
              </div>
              <div className="text-start">
                <span className="font-medium block">
                  {language === 'ar' ? 'حذف جميع البيانات' : 'Delete All Data'}
                </span>
                <span className="text-xs opacity-70">
                  {language === 'ar' ? 'سيؤدي هذا إلى حذف جميع بياناتك' : 'This will delete all your data'}
                </span>
              </div>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SettingsScreen;
