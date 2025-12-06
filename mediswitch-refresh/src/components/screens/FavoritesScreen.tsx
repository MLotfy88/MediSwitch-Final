import React from 'react';
import { Heart, Trash2 } from 'lucide-react';
import DrugCard, { Drug } from '@/components/drugs/DrugCard';
import { useTheme } from '@/hooks/useTheme';

const mockFavorites: Drug[] = [
  {
    id: '1',
    tradeNameEn: 'Augmentin 1g',
    tradeNameAr: 'اوجمنتين ١ جرام',
    activeIngredient: 'Amoxicillin + Clavulanic Acid',
    form: 'tablet',
    currentPrice: 185.00,
    oldPrice: 195.00,
    company: 'GSK',
    isPopular: true,
  },
  {
    id: '2',
    tradeNameEn: 'Concor 5mg',
    tradeNameAr: 'كونكور ٥ مجم',
    activeIngredient: 'Bisoprolol',
    form: 'tablet',
    currentPrice: 75.00,
    company: 'Merck',
  },
  {
    id: '3',
    tradeNameEn: 'Nexium 40mg',
    tradeNameAr: 'نيكسيوم ٤٠ مجم',
    activeIngredient: 'Esomeprazole',
    form: 'tablet',
    currentPrice: 220.00,
    oldPrice: 250.00,
    company: 'AstraZeneca',
    isNew: true,
  },
];

interface FavoritesScreenProps {
  onDrugClick?: (id: string) => void;
}

const FavoritesScreen: React.FC<FavoritesScreenProps> = ({ onDrugClick }) => {
  const { language, isRTL } = useTheme();

  return (
    <div className="pb-24 bg-background min-h-screen">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-surface/95 backdrop-blur-lg border-b border-border px-4 py-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-danger/10 flex items-center justify-center">
            <Heart className="w-5 h-5 text-danger fill-danger" />
          </div>
          <div>
            <h1 className="text-lg font-bold text-foreground">
              {language === 'ar' ? 'المفضلة' : 'Favorites'}
            </h1>
            <p className="text-xs text-muted-foreground">
              {language === 'ar' ? `${mockFavorites.length} أدوية محفوظة` : `${mockFavorites.length} saved drugs`}
            </p>
          </div>
        </div>
      </div>

      {/* Favorites List */}
      <div className="px-4 py-4 space-y-3">
        {mockFavorites.length > 0 ? (
          mockFavorites.map((drug) => (
            <div key={drug.id} className="relative">
              <DrugCard 
                drug={drug} 
                onClick={() => onDrugClick?.(drug.id)}
                isRTL={isRTL}
              />
            </div>
          ))
        ) : (
          <div className="flex flex-col items-center justify-center py-16 text-center">
            <div className="w-20 h-20 rounded-full bg-muted flex items-center justify-center mb-4">
              <Heart className="w-10 h-10 text-muted-foreground" />
            </div>
            <h3 className="text-lg font-semibold text-foreground mb-2">
              {language === 'ar' ? 'لا توجد أدوية محفوظة' : 'No favorites yet'}
            </h3>
            <p className="text-sm text-muted-foreground max-w-[250px]">
              {language === 'ar' 
                ? 'اضغط على أيقونة القلب لحفظ الأدوية هنا'
                : 'Tap the heart icon on any drug to save it here'}
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default FavoritesScreen;
