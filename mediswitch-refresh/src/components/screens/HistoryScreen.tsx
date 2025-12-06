import React from 'react';
import { History, Clock, Trash2 } from 'lucide-react';
import DrugCard, { Drug } from '@/components/drugs/DrugCard';
import { useTheme } from '@/hooks/useTheme';

interface HistoryItem {
  drug: Drug;
  viewedAt: string;
}

const mockHistory: HistoryItem[] = [
  {
    drug: {
      id: '1',
      tradeNameEn: 'Augmentin 1g',
      tradeNameAr: 'اوجمنتين ١ جرام',
      activeIngredient: 'Amoxicillin + Clavulanic Acid',
      form: 'tablet',
      currentPrice: 185.00,
      oldPrice: 195.00,
      company: 'GSK',
    },
    viewedAt: 'Today, 10:30 AM',
  },
  {
    drug: {
      id: '2',
      tradeNameEn: 'Concor 5mg',
      tradeNameAr: 'كونكور ٥ مجم',
      activeIngredient: 'Bisoprolol',
      form: 'tablet',
      currentPrice: 75.00,
      company: 'Merck',
    },
    viewedAt: 'Today, 9:15 AM',
  },
  {
    drug: {
      id: '3',
      tradeNameEn: 'Nexium 40mg',
      tradeNameAr: 'نيكسيوم ٤٠ مجم',
      activeIngredient: 'Esomeprazole',
      form: 'tablet',
      currentPrice: 220.00,
      company: 'AstraZeneca',
    },
    viewedAt: 'Yesterday, 4:00 PM',
  },
  {
    drug: {
      id: '4',
      tradeNameEn: 'Lipitor 20mg',
      tradeNameAr: 'ليبيتور ٢٠ مجم',
      activeIngredient: 'Atorvastatin',
      form: 'tablet',
      currentPrice: 145.00,
      oldPrice: 160.00,
      company: 'Pfizer',
    },
    viewedAt: 'Yesterday, 2:30 PM',
  },
];

interface HistoryScreenProps {
  onDrugClick?: (id: string) => void;
}

const HistoryScreen: React.FC<HistoryScreenProps> = ({ onDrugClick }) => {
  const { language, isRTL } = useTheme();

  return (
    <div className="pb-24 bg-background min-h-screen">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-surface/95 backdrop-blur-lg border-b border-border px-4 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
              <History className="w-5 h-5 text-primary" />
            </div>
            <div>
              <h1 className="text-lg font-bold text-foreground">
                {language === 'ar' ? 'السجل' : 'History'}
              </h1>
              <p className="text-xs text-muted-foreground">
                {language === 'ar' ? 'الأدوية التي تم عرضها مؤخراً' : 'Recently viewed drugs'}
              </p>
            </div>
          </div>
          <button className="p-2 rounded-xl bg-muted hover:bg-muted/80 transition-colors">
            <Trash2 className="w-4 h-4 text-muted-foreground" />
          </button>
        </div>
      </div>

      {/* History List */}
      <div className="px-4 py-4 space-y-4">
        {mockHistory.map((item) => (
          <div key={item.drug.id}>
            <div className="flex items-center gap-2 mb-2 text-xs text-muted-foreground" dir={isRTL ? 'rtl' : 'ltr'}>
              <Clock className="w-3 h-3" />
              <span>{item.viewedAt}</span>
            </div>
            <DrugCard 
              drug={item.drug} 
              onClick={() => onDrugClick?.(item.drug.id)}
              isRTL={isRTL}
            />
          </div>
        ))}
      </div>
    </div>
  );
};

export default HistoryScreen;
