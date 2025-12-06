import React from 'react';
import { Sparkles, AlertTriangle, TrendingUp, Pill, Calculator, GitCompare } from 'lucide-react';
import AppHeader from '@/components/layout/AppHeader';
import SearchBar from '@/components/layout/SearchBar';
import SectionHeader from '@/components/layout/SectionHeader';
import CategoryCard, { Category } from '@/components/drugs/CategoryCard';
import DangerousDrugCard, { DangerousDrug } from '@/components/drugs/DangerousDrugCard';
import DrugCard, { Drug } from '@/components/drugs/DrugCard';
import { Badge } from '@/components/ui/badge';

const categories: Category[] = [
  { id: '1', name: 'Cardiac', nameAr: 'قلب', icon: 'heart', drugCount: 245, color: 'red' },
  { id: '2', name: 'Neuro', nameAr: 'أعصاب', icon: 'brain', drugCount: 189, color: 'purple' },
  { id: '3', name: 'Dental', nameAr: 'أسنان', icon: 'dental', drugCount: 78, color: 'teal' },
  { id: '4', name: 'Pediatric', nameAr: 'أطفال', icon: 'baby', drugCount: 156, color: 'green' },
  { id: '5', name: 'Ophthalmic', nameAr: 'عيون', icon: 'eye', drugCount: 92, color: 'blue' },
  { id: '6', name: 'Orthopedic', nameAr: 'عظام', icon: 'bone', drugCount: 134, color: 'orange' },
];

const dangerousDrugs: DangerousDrug[] = [
  { id: '1', name: 'Warfarin', activeIngredient: 'Warfarin Sodium', riskLevel: 'critical', interactionCount: 47 },
  { id: '2', name: 'Methotrexate', activeIngredient: 'Methotrexate', riskLevel: 'critical', interactionCount: 38 },
  { id: '3', name: 'Digoxin', activeIngredient: 'Digoxin', riskLevel: 'high', interactionCount: 29 },
  { id: '4', name: 'Lithium', activeIngredient: 'Lithium Carbonate', riskLevel: 'high', interactionCount: 24 },
];

const recentDrugs: Drug[] = [
  {
    id: '1',
    tradeNameEn: 'Panadol Extra',
    tradeNameAr: 'بانادول اكسترا',
    activeIngredient: 'Paracetamol + Caffeine',
    form: 'tablet',
    currentPrice: 45.50,
    oldPrice: 52.00,
    company: 'GSK',
    isNew: true,
    isFavorite: false,
  },
  {
    id: '2',
    tradeNameEn: 'Augmentin 1g',
    tradeNameAr: 'اوجمنتين ١ جرام',
    activeIngredient: 'Amoxicillin + Clavulanic Acid',
    form: 'tablet',
    currentPrice: 185.00,
    company: 'GSK',
    isPopular: true,
    hasInteraction: true,
    isFavorite: true,
  },
  {
    id: '3',
    tradeNameEn: 'Cataflam 50mg',
    tradeNameAr: 'كتافلام ٥٠ مجم',
    activeIngredient: 'Diclofenac Potassium',
    form: 'tablet',
    currentPrice: 67.25,
    oldPrice: 60.00,
    company: 'Novartis',
    isFavorite: false,
  },
];

interface HomeScreenProps {
  onDrugClick?: (id: string) => void;
  onSearch?: (query: string) => void;
  onInteractionsClick?: () => void;
  onDoseCalculatorClick?: () => void;
}

const HomeScreen: React.FC<HomeScreenProps> = ({ onDrugClick, onSearch, onInteractionsClick, onDoseCalculatorClick }) => {
  const [searchValue, setSearchValue] = React.useState('');
  const [favorites, setFavorites] = React.useState<Set<string>>(new Set(['2']));

  const toggleFavorite = (id: string) => {
    setFavorites((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  return (
    <div className="pb-24">
      <AppHeader />
      
      {/* Search Section */}
      <div className="px-4 py-4">
        <SearchBar
          value={searchValue}
          onChange={(v) => {
            setSearchValue(v);
            onSearch?.(v);
          }}
        />
        
        {/* Quick Stats */}
        <div className="mt-4 flex items-center justify-between px-4 py-3 bg-success-soft rounded-xl">
          <div className="flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-success" />
            <span className="text-sm font-medium text-success">Today's Updates</span>
          </div>
          <Badge variant="new" size="lg">+30 Drugs</Badge>
        </div>

        {/* Quick Tools */}
        <div className="mt-4 grid grid-cols-2 gap-3">
          <button
            onClick={onInteractionsClick}
            className="flex items-center gap-3 p-4 bg-warning/10 border border-warning/20 rounded-xl hover:bg-warning/20 transition-colors"
          >
            <div className="w-10 h-10 rounded-xl bg-warning/20 flex items-center justify-center">
              <GitCompare className="w-5 h-5 text-warning" />
            </div>
            <div className="text-start">
              <p className="font-semibold text-foreground text-sm">Interactions</p>
              <p className="text-xs text-muted-foreground">Check conflicts</p>
            </div>
          </button>
          <button
            onClick={onDoseCalculatorClick}
            className="flex items-center gap-3 p-4 bg-primary/10 border border-primary/20 rounded-xl hover:bg-primary/20 transition-colors"
          >
            <div className="w-10 h-10 rounded-xl bg-primary/20 flex items-center justify-center">
              <Calculator className="w-5 h-5 text-primary" />
            </div>
            <div className="text-start">
              <p className="font-semibold text-foreground text-sm">Dose Calc</p>
              <p className="text-xs text-muted-foreground">Calculate dosage</p>
            </div>
          </button>
        </div>
      </div>

      {/* Categories Section */}
      <section className="px-4 mb-6">
        <SectionHeader
          title="Medical Specialties"
          subtitle="Browse by category"
          icon={<Pill className="w-4 h-4" />}
        />
        <div className="mt-3 flex gap-3 overflow-x-auto scrollbar-hide pb-2 -mx-4 px-4">
          {categories.map((category, index) => (
            <div
              key={category.id}
              className="animate-slide-in-right"
              style={{ animationDelay: `${index * 50}ms` }}
            >
              <CategoryCard category={category} />
            </div>
          ))}
        </div>
      </section>

      {/* Dangerous Drugs Section */}
      <section className="px-4 mb-6">
        <SectionHeader
          title="High-Risk Drugs"
          subtitle="Drugs with severe interactions"
          icon={<AlertTriangle className="w-4 h-4 text-danger" />}
          iconColor="bg-danger-soft"
        />
        <div className="mt-3 flex gap-3 overflow-x-auto scrollbar-hide pb-2 -mx-4 px-4">
          {dangerousDrugs.map((drug, index) => (
            <div
              key={drug.id}
              className="animate-slide-in-right"
              style={{ animationDelay: `${index * 50}ms` }}
            >
              <DangerousDrugCard drug={drug} onClick={() => onDrugClick?.(drug.id)} />
            </div>
          ))}
        </div>
      </section>

      {/* Recently Added Section */}
      <section className="px-4 mb-6">
        <SectionHeader
          title="Recently Added"
          subtitle="New drugs this week"
          icon={<Sparkles className="w-4 h-4 text-success" />}
          iconColor="bg-success-soft"
        />
        <div className="mt-3 space-y-3">
          {recentDrugs.map((drug, index) => (
            <div
              key={drug.id}
              className="animate-fade-in"
              style={{ animationDelay: `${index * 100}ms` }}
            >
              <DrugCard
                drug={{ ...drug, isFavorite: favorites.has(drug.id) }}
                onFavoriteToggle={toggleFavorite}
                onClick={() => onDrugClick?.(drug.id)}
              />
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};

export default HomeScreen;
