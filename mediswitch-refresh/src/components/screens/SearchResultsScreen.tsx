import React, { useState } from 'react';
import { ArrowLeft, SlidersHorizontal, X, ArrowDownAZ, ArrowUpAZ } from 'lucide-react';
import SearchBar from '@/components/layout/SearchBar';
import DrugCard, { Drug } from '@/components/drugs/DrugCard';
import SearchFiltersSheet, { FilterState } from '@/components/layout/SearchFiltersSheet';
import { cn } from '@/lib/utils';

const mockSearchResults: Drug[] = [
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
  },
  {
    id: '2',
    tradeNameEn: 'Panadol Advance',
    tradeNameAr: 'بانادول ادفانس',
    activeIngredient: 'Paracetamol 500mg',
    form: 'tablet',
    currentPrice: 38.00,
    company: 'GSK',
    isPopular: true,
  },
  {
    id: '3',
    tradeNameEn: 'Panadol Cold & Flu',
    tradeNameAr: 'بانادول كولد اند فلو',
    activeIngredient: 'Paracetamol + Pseudoephedrine',
    form: 'tablet',
    currentPrice: 55.00,
    company: 'GSK',
    hasInteraction: true,
  },
  {
    id: '4',
    tradeNameEn: 'Panadol Night',
    tradeNameAr: 'بانادول نايت',
    activeIngredient: 'Paracetamol + Diphenhydramine',
    form: 'tablet',
    currentPrice: 62.50,
    oldPrice: 68.00,
    company: 'GSK',
  },
  {
    id: '5',
    tradeNameEn: 'Panadol Syrup',
    tradeNameAr: 'بانادول شراب',
    activeIngredient: 'Paracetamol 120mg/5ml',
    form: 'syrup',
    currentPrice: 28.00,
    company: 'GSK',
    isNew: true,
  },
  {
    id: '6',
    tradeNameEn: 'Brufen 400mg',
    tradeNameAr: 'بروفين ٤٠٠ مجم',
    activeIngredient: 'Ibuprofen',
    form: 'tablet',
    currentPrice: 75.00,
    company: 'Pfizer',
    isPopular: true,
  },
  {
    id: '7',
    tradeNameEn: 'Voltaren Gel',
    tradeNameAr: 'فولتارين جل',
    activeIngredient: 'Diclofenac Sodium',
    form: 'cream',
    currentPrice: 120.00,
    oldPrice: 135.00,
    company: 'Novartis',
  },
];

const filterOptions = [
  { id: 'all', label: 'All' },
  { id: 'tablet', label: 'Tablets' },
  { id: 'syrup', label: 'Syrups' },
  { id: 'injection', label: 'Injections' },
  { id: 'cream', label: 'Creams' },
];

interface SearchResultsScreenProps {
  initialQuery?: string;
  onBack?: () => void;
  onDrugClick?: (id: string) => void;
}

const SearchResultsScreen: React.FC<SearchResultsScreenProps> = ({
  initialQuery = 'Panadol',
  onBack,
  onDrugClick,
}) => {
  const [searchValue, setSearchValue] = useState(initialQuery);
  const [activeFilter, setActiveFilter] = useState('all');
  const [favorites, setFavorites] = useState<Set<string>>(new Set());
  const [showFilters, setShowFilters] = useState(false);
  const [filters, setFilters] = useState<FilterState>({
    priceRange: [0, 500],
    companies: [],
    forms: [],
    sortBy: 'relevance',
  });

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

  // Apply all filters
  const filteredResults = mockSearchResults.filter((drug) => {
    // Form filter (quick filter pills)
    if (activeFilter !== 'all' && drug.form !== activeFilter) return false;
    
    // Price range filter
    if (drug.currentPrice < filters.priceRange[0] || drug.currentPrice > filters.priceRange[1]) return false;
    
    // Company filter
    if (filters.companies.length > 0 && !filters.companies.includes(drug.company)) return false;
    
    // Form filter from sheet
    if (filters.forms.length > 0 && !filters.forms.includes(drug.form)) return false;
    
    // Search query
    if (searchValue && !drug.tradeNameEn.toLowerCase().includes(searchValue.toLowerCase()) &&
        !drug.tradeNameAr.includes(searchValue) &&
        !drug.activeIngredient.toLowerCase().includes(searchValue.toLowerCase())) {
      return false;
    }
    
    return true;
  });

  // Sort results
  const sortedResults = [...filteredResults].sort((a, b) => {
    switch (filters.sortBy) {
      case 'price-low':
        return a.currentPrice - b.currentPrice;
      case 'price-high':
        return b.currentPrice - a.currentPrice;
      case 'name-az':
        return a.tradeNameEn.localeCompare(b.tradeNameEn);
      case 'newest':
        return (b.isNew ? 1 : 0) - (a.isNew ? 1 : 0);
      default:
        return 0;
    }
  });

  const activeFiltersCount = 
    (filters.companies.length > 0 ? 1 : 0) +
    (filters.forms.length > 0 ? 1 : 0) +
    (filters.priceRange[0] > 0 || filters.priceRange[1] < 500 ? 1 : 0) +
    (filters.sortBy !== 'relevance' ? 1 : 0);

  return (
    <div className="pb-24 bg-background min-h-screen">
      {/* Header */}
      <div className="sticky top-0 z-50 bg-surface/95 backdrop-blur-lg border-b border-border">
        <div className="flex items-center gap-3 px-4 py-3">
          <button 
            onClick={onBack}
            className="p-2 rounded-xl bg-accent hover:bg-accent/80 transition-colors"
          >
            <ArrowLeft className="w-5 h-5 text-foreground" />
          </button>
          <div className="flex-1">
            <SearchBar
              value={searchValue}
              onChange={setSearchValue}
              onFilterClick={() => setShowFilters(true)}
            />
          </div>
        </div>

        {/* Filter Pills */}
        <div className="px-4 pb-3">
          <div className="flex gap-2 overflow-x-auto scrollbar-hide">
            {filterOptions.map((filter) => (
              <button
                key={filter.id}
                onClick={() => setActiveFilter(filter.id)}
                className={cn(
                  "px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all",
                  activeFilter === filter.id
                    ? "bg-primary text-primary-foreground"
                    : "bg-accent text-foreground hover:bg-accent/80"
                )}
              >
                {filter.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Results Count & Active Filters */}
      <div className="px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <p className="text-sm text-muted-foreground">
            <span className="font-semibold text-foreground">{sortedResults.length}</span> results
          </p>
          {activeFiltersCount > 0 && (
            <span className="px-2 py-0.5 rounded-full bg-primary/10 text-primary text-xs font-medium">
              {activeFiltersCount} filter{activeFiltersCount > 1 ? 's' : ''} active
            </span>
          )}
        </div>
        <button 
          onClick={() => setShowFilters(true)}
          className="flex items-center gap-1 text-sm text-primary font-medium"
        >
          <SlidersHorizontal className="w-4 h-4" />
          Filters
        </button>
      </div>

      {/* Results List */}
      <div className="px-4 space-y-3">
        {sortedResults.map((drug, index) => (
          <div
            key={drug.id}
            className="animate-fade-in"
            style={{ animationDelay: `${index * 50}ms` }}
          >
            <DrugCard
              drug={{ ...drug, isFavorite: favorites.has(drug.id) }}
              onFavoriteToggle={toggleFavorite}
              onClick={() => onDrugClick?.(drug.id)}
            />
          </div>
        ))}
      </div>

      {/* No Results State */}
      {sortedResults.length === 0 && (
        <div className="flex flex-col items-center justify-center py-16 px-4">
          <div className="w-20 h-20 rounded-full bg-muted flex items-center justify-center mb-4">
            <X className="w-10 h-10 text-muted-foreground" />
          </div>
          <h3 className="text-lg font-semibold text-foreground mb-2">No results found</h3>
          <p className="text-sm text-muted-foreground text-center">
            Try adjusting your search or filters to find what you're looking for.
          </p>
        </div>
      )}

      {/* Filters Sheet */}
      <SearchFiltersSheet
        isOpen={showFilters}
        onClose={() => setShowFilters(false)}
        filters={filters}
        onApplyFilters={setFilters}
      />
    </div>
  );
};

export default SearchResultsScreen;
