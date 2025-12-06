import React, { useState } from 'react';
import { X, Check } from 'lucide-react';
import { cn } from '@/lib/utils';
import { Slider } from '@/components/ui/slider';

export interface FilterState {
  priceRange: [number, number];
  companies: string[];
  forms: string[];
  sortBy: string;
}

interface SearchFiltersSheetProps {
  isOpen: boolean;
  onClose: () => void;
  filters: FilterState;
  onApplyFilters: (filters: FilterState) => void;
}

const companies = ['GSK', 'Novartis', 'Pfizer', 'Sanofi', 'AstraZeneca', 'Bayer', 'EVA Pharma', 'Amoun'];
const forms = [
  { id: 'tablet', label: 'Tablets' },
  { id: 'capsule', label: 'Capsules' },
  { id: 'syrup', label: 'Syrups' },
  { id: 'injection', label: 'Injections' },
  { id: 'cream', label: 'Creams' },
  { id: 'drops', label: 'Drops' },
];
const sortOptions = [
  { id: 'relevance', label: 'Relevance' },
  { id: 'price-low', label: 'Price: Low to High' },
  { id: 'price-high', label: 'Price: High to Low' },
  { id: 'name-az', label: 'Name: A-Z' },
  { id: 'newest', label: 'Newest First' },
];

const SearchFiltersSheet: React.FC<SearchFiltersSheetProps> = ({
  isOpen,
  onClose,
  filters,
  onApplyFilters,
}) => {
  const [localFilters, setLocalFilters] = useState<FilterState>(filters);

  const handlePriceChange = (value: number[]) => {
    setLocalFilters(prev => ({ ...prev, priceRange: [value[0], value[1]] }));
  };

  const toggleCompany = (company: string) => {
    setLocalFilters(prev => ({
      ...prev,
      companies: prev.companies.includes(company)
        ? prev.companies.filter(c => c !== company)
        : [...prev.companies, company]
    }));
  };

  const toggleForm = (form: string) => {
    setLocalFilters(prev => ({
      ...prev,
      forms: prev.forms.includes(form)
        ? prev.forms.filter(f => f !== form)
        : [...prev.forms, form]
    }));
  };

  const handleApply = () => {
    onApplyFilters(localFilters);
    onClose();
  };

  const handleReset = () => {
    const resetFilters: FilterState = {
      priceRange: [0, 500],
      companies: [],
      forms: [],
      sortBy: 'relevance',
    };
    setLocalFilters(resetFilters);
  };

  if (!isOpen) return null;

  return (
    <>
      {/* Backdrop */}
      <div 
        className="fixed inset-0 bg-foreground/40 z-[60] transition-opacity"
        onClick={onClose}
      />
      
      {/* Sheet */}
      <div className="fixed bottom-0 left-0 right-0 z-[70] bg-surface rounded-t-3xl max-h-[85vh] overflow-hidden animate-slide-up">
        {/* Handle */}
        <div className="flex justify-center pt-3 pb-2">
          <div className="w-10 h-1 bg-muted-foreground/30 rounded-full" />
        </div>

        {/* Header */}
        <div className="flex items-center justify-between px-4 pb-3 border-b border-border">
          <button onClick={handleReset} className="text-sm font-medium text-primary">
            Reset
          </button>
          <h2 className="text-lg font-semibold text-foreground">Filters</h2>
          <button 
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-accent transition-colors"
          >
            <X className="w-5 h-5 text-foreground" />
          </button>
        </div>

        {/* Content */}
        <div className="overflow-y-auto max-h-[calc(85vh-140px)] p-4 space-y-6">
          {/* Price Range */}
          <div>
            <h3 className="text-sm font-semibold text-foreground mb-3">Price Range (EGP)</h3>
            <div className="px-2">
              <Slider
                value={[localFilters.priceRange[0], localFilters.priceRange[1]]}
                onValueChange={handlePriceChange}
                max={500}
                min={0}
                step={10}
                className="mb-2"
              />
              <div className="flex justify-between text-sm text-muted-foreground">
                <span>{localFilters.priceRange[0]} EGP</span>
                <span>{localFilters.priceRange[1]} EGP</span>
              </div>
            </div>
          </div>

          {/* Sort By */}
          <div>
            <h3 className="text-sm font-semibold text-foreground mb-3">Sort By</h3>
            <div className="space-y-2">
              {sortOptions.map((option) => (
                <button
                  key={option.id}
                  onClick={() => setLocalFilters(prev => ({ ...prev, sortBy: option.id }))}
                  className={cn(
                    "w-full flex items-center justify-between px-4 py-3 rounded-xl transition-all",
                    localFilters.sortBy === option.id
                      ? "bg-primary/10 border border-primary"
                      : "bg-accent hover:bg-accent/80"
                  )}
                >
                  <span className={cn(
                    "text-sm font-medium",
                    localFilters.sortBy === option.id ? "text-primary" : "text-foreground"
                  )}>
                    {option.label}
                  </span>
                  {localFilters.sortBy === option.id && (
                    <Check className="w-4 h-4 text-primary" />
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Drug Form */}
          <div>
            <h3 className="text-sm font-semibold text-foreground mb-3">Drug Form</h3>
            <div className="flex flex-wrap gap-2">
              {forms.map((form) => (
                <button
                  key={form.id}
                  onClick={() => toggleForm(form.id)}
                  className={cn(
                    "px-4 py-2 rounded-full text-sm font-medium transition-all",
                    localFilters.forms.includes(form.id)
                      ? "bg-primary text-primary-foreground"
                      : "bg-accent text-foreground hover:bg-accent/80"
                  )}
                >
                  {form.label}
                </button>
              ))}
            </div>
          </div>

          {/* Companies */}
          <div>
            <h3 className="text-sm font-semibold text-foreground mb-3">Company</h3>
            <div className="flex flex-wrap gap-2">
              {companies.map((company) => (
                <button
                  key={company}
                  onClick={() => toggleCompany(company)}
                  className={cn(
                    "px-4 py-2 rounded-full text-sm font-medium transition-all",
                    localFilters.companies.includes(company)
                      ? "bg-secondary text-secondary-foreground"
                      : "bg-accent text-foreground hover:bg-accent/80"
                  )}
                >
                  {company}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-border bg-surface">
          <button
            onClick={handleApply}
            className="w-full py-3.5 bg-primary text-primary-foreground font-semibold rounded-xl hover:bg-primary-dark transition-colors"
          >
            Apply Filters
          </button>
        </div>
      </div>
    </>
  );
};

export default SearchFiltersSheet;
