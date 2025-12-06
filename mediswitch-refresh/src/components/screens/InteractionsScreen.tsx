import React, { useState } from 'react';
import { 
  AlertTriangle, 
  Search, 
  Plus, 
  X, 
  Pill,
  ArrowLeft,
  Info,
  ShieldAlert,
  ShieldCheck,
  AlertCircle
} from 'lucide-react';
import { useTheme } from '@/hooks/useTheme';
import { cn } from '@/lib/utils';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';

interface Drug {
  id: string;
  nameEn: string;
  nameAr: string;
}

interface Interaction {
  drug1: string;
  drug2: string;
  severity: 'major' | 'moderate' | 'minor';
  descriptionEn: string;
  descriptionAr: string;
  recommendationEn: string;
  recommendationAr: string;
}

const availableDrugs: Drug[] = [
  { id: '1', nameEn: 'Warfarin', nameAr: 'وارفارين' },
  { id: '2', nameEn: 'Aspirin', nameAr: 'أسبرين' },
  { id: '3', nameEn: 'Ibuprofen', nameAr: 'إيبوبروفين' },
  { id: '4', nameEn: 'Omeprazole', nameAr: 'أوميبرازول' },
  { id: '5', nameEn: 'Metformin', nameAr: 'ميتفورمين' },
  { id: '6', nameEn: 'Atorvastatin', nameAr: 'أتورفاستاتين' },
  { id: '7', nameEn: 'Lisinopril', nameAr: 'ليزينوبريل' },
  { id: '8', nameEn: 'Amlodipine', nameAr: 'أملوديبين' },
  { id: '9', nameEn: 'Metoprolol', nameAr: 'ميتوبرولول' },
  { id: '10', nameEn: 'Clopidogrel', nameAr: 'كلوبيدوجريل' },
];

const mockInteractions: Interaction[] = [
  {
    drug1: 'Warfarin',
    drug2: 'Aspirin',
    severity: 'major',
    descriptionEn: 'Increased risk of bleeding when used together. Both drugs affect blood clotting.',
    descriptionAr: 'زيادة خطر النزيف عند الاستخدام معًا. كلا الدواءين يؤثران على تخثر الدم.',
    recommendationEn: 'Avoid combination unless specifically prescribed. Monitor for signs of bleeding.',
    recommendationAr: 'تجنب الجمع إلا إذا وصفه الطبيب. راقب علامات النزيف.',
  },
  {
    drug1: 'Warfarin',
    drug2: 'Ibuprofen',
    severity: 'major',
    descriptionEn: 'NSAIDs increase anticoagulant effect and risk of GI bleeding.',
    descriptionAr: 'مضادات الالتهاب غير الستيرويدية تزيد من تأثير مضادات التخثر وخطر نزيف الجهاز الهضمي.',
    recommendationEn: 'Use alternative pain relief. If necessary, use lowest effective dose for shortest duration.',
    recommendationAr: 'استخدم مسكنات بديلة. إذا لزم الأمر، استخدم أقل جرعة فعالة لأقصر مدة.',
  },
  {
    drug1: 'Omeprazole',
    drug2: 'Clopidogrel',
    severity: 'moderate',
    descriptionEn: 'Omeprazole may reduce the antiplatelet effect of clopidogrel.',
    descriptionAr: 'أوميبرازول قد يقلل من تأثير كلوبيدوجريل المضاد للصفيحات.',
    recommendationEn: 'Consider using pantoprazole as an alternative PPI.',
    recommendationAr: 'فكر في استخدام بانتوبرازول كبديل.',
  },
  {
    drug1: 'Lisinopril',
    drug2: 'Ibuprofen',
    severity: 'moderate',
    descriptionEn: 'NSAIDs may reduce antihypertensive effect and increase risk of kidney problems.',
    descriptionAr: 'مضادات الالتهاب قد تقلل من تأثير خفض ضغط الدم وتزيد من خطر مشاكل الكلى.',
    recommendationEn: 'Monitor blood pressure and kidney function. Use lowest NSAID dose.',
    recommendationAr: 'راقب ضغط الدم ووظائف الكلى. استخدم أقل جرعة من مضادات الالتهاب.',
  },
  {
    drug1: 'Metformin',
    drug2: 'Atorvastatin',
    severity: 'minor',
    descriptionEn: 'Generally safe combination. Minor interaction with minimal clinical significance.',
    descriptionAr: 'مزيج آمن بشكل عام. تفاعل طفيف مع أهمية سريرية ضئيلة.',
    recommendationEn: 'No action needed. Safe to use together.',
    recommendationAr: 'لا حاجة لإجراء. آمن للاستخدام معًا.',
  },
];

interface InteractionsScreenProps {
  onBack?: () => void;
}

const InteractionsScreen: React.FC<InteractionsScreenProps> = ({ onBack }) => {
  const { language, isRTL } = useTheme();
  const [selectedDrugs, setSelectedDrugs] = useState<Drug[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  const [foundInteractions, setFoundInteractions] = useState<Interaction[]>([]);

  const severityConfig = {
    major: {
      icon: ShieldAlert,
      bgColor: 'bg-danger/10',
      borderColor: 'border-danger/30',
      textColor: 'text-danger',
      labelEn: 'Major',
      labelAr: 'خطير',
    },
    moderate: {
      icon: AlertCircle,
      bgColor: 'bg-warning/10',
      borderColor: 'border-warning/30',
      textColor: 'text-warning',
      labelEn: 'Moderate',
      labelAr: 'متوسط',
    },
    minor: {
      icon: Info,
      bgColor: 'bg-info/10',
      borderColor: 'border-info/30',
      textColor: 'text-info',
      labelEn: 'Minor',
      labelAr: 'طفيف',
    },
  };

  const filteredDrugs = availableDrugs.filter(drug => {
    const query = searchQuery.toLowerCase();
    const isNotSelected = !selectedDrugs.find(d => d.id === drug.id);
    const matchesSearch = drug.nameEn.toLowerCase().includes(query) || drug.nameAr.includes(query);
    return isNotSelected && matchesSearch;
  });

  const addDrug = (drug: Drug) => {
    const newSelectedDrugs = [...selectedDrugs, drug];
    setSelectedDrugs(newSelectedDrugs);
    setSearchQuery('');
    setShowSearch(false);
    checkInteractions(newSelectedDrugs);
  };

  const removeDrug = (drugId: string) => {
    const newSelectedDrugs = selectedDrugs.filter(d => d.id !== drugId);
    setSelectedDrugs(newSelectedDrugs);
    checkInteractions(newSelectedDrugs);
  };

  const checkInteractions = (drugs: Drug[]) => {
    if (drugs.length < 2) {
      setFoundInteractions([]);
      return;
    }

    const drugNames = drugs.map(d => d.nameEn);
    const interactions = mockInteractions.filter(interaction => 
      drugNames.includes(interaction.drug1) && drugNames.includes(interaction.drug2)
    );
    setFoundInteractions(interactions);
  };

  return (
    <div className="pb-24 bg-background min-h-screen">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-gradient-to-br from-warning/90 to-warning text-warning-foreground px-4 py-4">
        <div className="flex items-center gap-3 mb-4">
          {onBack && (
            <button 
              onClick={onBack}
              className="p-2 rounded-xl bg-white/10 hover:bg-white/20 transition-colors"
            >
              <ArrowLeft className={cn("w-5 h-5", isRTL && "rotate-180")} />
            </button>
          )}
          <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
            <AlertTriangle className="w-5 h-5" />
          </div>
          <div>
            <h1 className="text-lg font-bold">
              {language === 'ar' ? 'فاحص التفاعلات الدوائية' : 'Drug Interaction Checker'}
            </h1>
            <p className="text-xs opacity-80">
              {language === 'ar' ? 'أضف الأدوية للتحقق من التفاعلات' : 'Add drugs to check for interactions'}
            </p>
          </div>
        </div>
      </div>

      <div className="px-4 py-4 space-y-4">
        {/* Selected Drugs */}
        <div className="bg-card rounded-xl p-4 card-shadow">
          <h3 className="font-semibold text-foreground mb-3 flex items-center gap-2" dir={isRTL ? 'rtl' : 'ltr'}>
            <Pill className="w-4 h-4 text-primary" />
            {language === 'ar' ? 'الأدوية المحددة' : 'Selected Drugs'}
            <Badge variant="secondary" size="sm">{selectedDrugs.length}</Badge>
          </h3>
          
          <div className="flex flex-wrap gap-2 mb-3">
            {selectedDrugs.map((drug) => (
              <div 
                key={drug.id}
                className="flex items-center gap-2 bg-primary/10 text-primary px-3 py-2 rounded-full"
              >
                <Pill className="w-4 h-4" />
                <span className="text-sm font-medium">
                  {language === 'ar' ? drug.nameAr : drug.nameEn}
                </span>
                <button 
                  onClick={() => removeDrug(drug.id)}
                  className="w-5 h-5 rounded-full bg-primary/20 hover:bg-primary/30 flex items-center justify-center transition-colors"
                >
                  <X className="w-3 h-3" />
                </button>
              </div>
            ))}
            
            {selectedDrugs.length === 0 && (
              <p className="text-sm text-muted-foreground">
                {language === 'ar' ? 'لم يتم تحديد أي أدوية بعد' : 'No drugs selected yet'}
              </p>
            )}
          </div>

          {/* Add Drug Button / Search */}
          {showSearch ? (
            <div className="space-y-2">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                <Input
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder={language === 'ar' ? 'ابحث عن دواء...' : 'Search for a drug...'}
                  className="pl-10"
                  autoFocus
                />
              </div>
              <div className="max-h-48 overflow-y-auto space-y-1">
                {filteredDrugs.map((drug) => (
                  <button
                    key={drug.id}
                    onClick={() => addDrug(drug)}
                    className="w-full flex items-center gap-2 p-3 rounded-lg hover:bg-muted transition-colors text-start"
                    dir={isRTL ? 'rtl' : 'ltr'}
                  >
                    <Pill className="w-4 h-4 text-primary" />
                    <span className="font-medium text-foreground">
                      {language === 'ar' ? drug.nameAr : drug.nameEn}
                    </span>
                  </button>
                ))}
              </div>
              <button 
                onClick={() => setShowSearch(false)}
                className="w-full py-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
              >
                {language === 'ar' ? 'إلغاء' : 'Cancel'}
              </button>
            </div>
          ) : (
            <button
              onClick={() => setShowSearch(true)}
              className="w-full flex items-center justify-center gap-2 py-3 border-2 border-dashed border-muted-foreground/30 rounded-xl text-muted-foreground hover:border-primary hover:text-primary transition-colors"
            >
              <Plus className="w-5 h-5" />
              {language === 'ar' ? 'إضافة دواء' : 'Add Drug'}
            </button>
          )}
        </div>

        {/* Interactions Results */}
        {selectedDrugs.length >= 2 && (
          <div className="space-y-3">
            <h3 className="font-semibold text-foreground flex items-center gap-2" dir={isRTL ? 'rtl' : 'ltr'}>
              <AlertTriangle className="w-4 h-4 text-warning" />
              {language === 'ar' ? 'نتائج التفاعلات' : 'Interaction Results'}
            </h3>

            {foundInteractions.length === 0 ? (
              <div className="bg-success/10 border border-success/30 rounded-xl p-4 flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-success/20 flex items-center justify-center">
                  <ShieldCheck className="w-5 h-5 text-success" />
                </div>
                <div>
                  <p className="font-semibold text-success">
                    {language === 'ar' ? 'لا توجد تفاعلات معروفة' : 'No Known Interactions'}
                  </p>
                  <p className="text-sm text-success/80">
                    {language === 'ar' ? 'الأدوية المحددة آمنة للاستخدام معًا' : 'Selected drugs are safe to use together'}
                  </p>
                </div>
              </div>
            ) : (
              foundInteractions.map((interaction, index) => {
                const config = severityConfig[interaction.severity];
                const Icon = config.icon;
                return (
                  <div 
                    key={index}
                    className={cn("rounded-xl p-4 border", config.bgColor, config.borderColor)}
                  >
                    <div className="flex items-start gap-3">
                      <div className={cn("w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0", config.bgColor)}>
                        <Icon className={cn("w-5 h-5", config.textColor)} />
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <span className="font-semibold text-foreground">
                            {interaction.drug1} + {interaction.drug2}
                          </span>
                          <Badge 
                            variant={interaction.severity === 'major' ? 'danger' : interaction.severity === 'moderate' ? 'warning' : 'info'}
                            size="sm"
                          >
                            {language === 'ar' ? config.labelAr : config.labelEn}
                          </Badge>
                        </div>
                        <p className="text-sm text-muted-foreground mb-3" dir={isRTL ? 'rtl' : 'ltr'}>
                          {language === 'ar' ? interaction.descriptionAr : interaction.descriptionEn}
                        </p>
                        <div className="bg-background/50 rounded-lg p-3">
                          <p className="text-xs font-semibold text-foreground mb-1">
                            {language === 'ar' ? 'التوصية:' : 'Recommendation:'}
                          </p>
                          <p className="text-sm text-muted-foreground" dir={isRTL ? 'rtl' : 'ltr'}>
                            {language === 'ar' ? interaction.recommendationAr : interaction.recommendationEn}
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        )}

        {/* Info Note */}
        <div className="bg-muted/50 rounded-xl p-4 flex items-start gap-3" dir={isRTL ? 'rtl' : 'ltr'}>
          <Info className="w-5 h-5 text-muted-foreground flex-shrink-0 mt-0.5" />
          <p className="text-xs text-muted-foreground">
            {language === 'ar' 
              ? 'هذه المعلومات للإرشاد فقط. استشر طبيبك أو الصيدلي قبل إجراء أي تغييرات على أدويتك.'
              : 'This information is for guidance only. Consult your doctor or pharmacist before making any changes to your medications.'}
          </p>
        </div>
      </div>
    </div>
  );
};

export default InteractionsScreen;
