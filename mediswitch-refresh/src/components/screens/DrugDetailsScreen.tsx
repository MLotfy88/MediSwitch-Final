import React, { useState } from 'react';
import { 
  ArrowLeft, 
  Heart, 
  Share2, 
  Pill, 
  Info, 
  Droplets, 
  GitCompare, 
  AlertTriangle, 
  TrendingDown,
  Clock,
  Building2,
  Hash,
  ChevronRight
} from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import DrugCard, { Drug } from '@/components/drugs/DrugCard';

const tabs = [
  { id: 'info', label: 'Info', icon: Info },
  { id: 'dosage', label: 'Dosage', icon: Droplets },
  { id: 'alternatives', label: 'Alternatives', icon: GitCompare },
  { id: 'interactions', label: 'Interactions', icon: AlertTriangle },
  { id: 'price', label: 'Price History', icon: TrendingDown },
];

const mockDrug = {
  id: '1',
  tradeNameEn: 'Augmentin 1g',
  tradeNameAr: 'اوجمنتين ١ جرام',
  activeIngredient: 'Amoxicillin 875mg + Clavulanic Acid 125mg',
  form: 'tablet' as const,
  currentPrice: 185.00,
  oldPrice: 195.00,
  company: 'GlaxoSmithKline (GSK)',
  registrationNumber: 'EGY-2024-00123',
  description: 'Augmentin is a combination antibiotic used to treat a wide variety of bacterial infections. It works by stopping the growth of bacteria.',
  isPopular: true,
};

const mockDosage = {
  strength: '1000mg (875mg + 125mg)',
  standardDose: '1 Tablet every 12 hours',
  instructions: 'Take at the start of a meal to reduce GI side effects. Complete the full course even if symptoms improve.',
  maxDaily: '2 tablets (2000mg)',
};

const mockAlternatives: Drug[] = [
  {
    id: 'alt1',
    tradeNameEn: 'Hibiotic 1g',
    tradeNameAr: 'هايبيوتك',
    activeIngredient: 'Amoxicillin + Clavulanic Acid',
    form: 'tablet',
    currentPrice: 145.00,
    company: 'Amoun Pharma',
  },
  {
    id: 'alt2',
    tradeNameEn: 'Megamox 1g',
    tradeNameAr: 'ميجاموكس',
    activeIngredient: 'Amoxicillin + Clavulanic Acid',
    form: 'tablet',
    currentPrice: 160.00,
    oldPrice: 175.00,
    company: 'Pharco',
  },
];

const mockInteractions = [
  { id: '1', name: 'Warfarin', severity: 'major', description: 'Increased risk of bleeding' },
  { id: '2', name: 'Methotrexate', severity: 'major', description: 'Increased methotrexate toxicity' },
  { id: '3', name: 'Oral Contraceptives', severity: 'moderate', description: 'May reduce contraceptive efficacy' },
  { id: '4', name: 'Probenecid', severity: 'minor', description: 'Increased amoxicillin levels' },
];

const mockPriceHistory = [
  { date: 'Nov 2024', price: 195.00 },
  { date: 'Oct 2024', price: 195.00 },
  { date: 'Sep 2024', price: 180.00 },
  { date: 'Aug 2024', price: 175.00 },
  { date: 'Jul 2024', price: 175.00 },
  { date: 'Jun 2024', price: 165.00 },
];

interface DrugDetailsScreenProps {
  onBack?: () => void;
}

const DrugDetailsScreen: React.FC<DrugDetailsScreenProps> = ({ onBack }) => {
  const [activeTab, setActiveTab] = useState('info');
  const [isFavorite, setIsFavorite] = useState(false);

  const severityColors = {
    major: { bg: 'bg-danger-soft', text: 'text-danger', border: 'border-danger/20' },
    moderate: { bg: 'bg-warning-soft', text: 'text-warning-foreground', border: 'border-warning/30' },
    minor: { bg: 'bg-info-soft', text: 'text-info', border: 'border-info/20' },
  };

  return (
    <div className="pb-24 bg-background">
      {/* Hero Header */}
      <div className="bg-gradient-to-br from-primary via-primary to-primary-dark text-primary-foreground">
        <div className="flex items-center justify-between px-4 py-3">
          <button 
            onClick={onBack}
            className="p-2 rounded-xl bg-primary-foreground/10 hover:bg-primary-foreground/20 transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div className="flex gap-2">
            <button className="p-2 rounded-xl bg-primary-foreground/10 hover:bg-primary-foreground/20 transition-colors">
              <Share2 className="w-5 h-5" />
            </button>
            <button 
              onClick={() => setIsFavorite(!isFavorite)}
              className={cn(
                "p-2 rounded-xl transition-colors",
                isFavorite ? "bg-danger" : "bg-primary-foreground/10 hover:bg-primary-foreground/20"
              )}
            >
              <Heart className={cn("w-5 h-5", isFavorite && "fill-current")} />
            </button>
          </div>
        </div>

        <div className="px-4 pb-6 pt-2">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-14 h-14 rounded-2xl bg-primary-foreground/10 flex items-center justify-center">
              <Pill className="w-7 h-7" />
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-2">
                <h1 className="text-2xl font-bold">{mockDrug.tradeNameEn}</h1>
                {mockDrug.isPopular && <Badge variant="popular" size="sm">POPULAR</Badge>}
              </div>
              <p className="text-primary-foreground/80 font-arabic" dir="rtl">{mockDrug.tradeNameAr}</p>
            </div>
          </div>
          
          <p className="text-sm text-primary-foreground/70 mb-4">{mockDrug.company}</p>
          
          <div className="flex items-baseline gap-3">
            <span className="text-3xl font-bold">{mockDrug.currentPrice.toFixed(2)} EGP</span>
            {mockDrug.oldPrice && (
              <>
                <span className="text-lg text-primary-foreground/60 line-through">
                  {mockDrug.oldPrice.toFixed(2)}
                </span>
                <Badge variant="priceDown" className="bg-success/20 text-success-foreground">
                  <TrendingDown className="w-3 h-3 mr-1" />
                  {(((mockDrug.oldPrice - mockDrug.currentPrice) / mockDrug.oldPrice) * 100).toFixed(0)}%
                </Badge>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="sticky top-0 z-40 bg-surface border-b border-border">
        <div className="flex overflow-x-auto scrollbar-hide">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={cn(
                  "flex items-center gap-1.5 px-4 py-3 text-sm font-medium whitespace-nowrap border-b-2 transition-colors",
                  isActive 
                    ? "border-primary text-primary" 
                    : "border-transparent text-muted-foreground hover:text-foreground"
                )}
              >
                <Icon className="w-4 h-4" />
                {tab.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Tab Content */}
      <div className="px-4 py-4">
        {/* Info Tab */}
        {activeTab === 'info' && (
          <div className="space-y-4 animate-fade-in">
            <div className="bg-card rounded-xl p-4 card-shadow">
              <h3 className="font-semibold text-foreground mb-2">Description</h3>
              <p className="text-sm text-muted-foreground leading-relaxed">{mockDrug.description}</p>
            </div>

            <div className="bg-card rounded-xl p-4 card-shadow space-y-3">
              <h3 className="font-semibold text-foreground mb-2">Details</h3>
              
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-accent flex items-center justify-center">
                  <Pill className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <p className="text-xs text-muted-foreground">Active Ingredient</p>
                  <p className="text-sm font-medium text-foreground">{mockDrug.activeIngredient}</p>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-accent flex items-center justify-center">
                  <Building2 className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <p className="text-xs text-muted-foreground">Manufacturer</p>
                  <p className="text-sm font-medium text-foreground">{mockDrug.company}</p>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-accent flex items-center justify-center">
                  <Hash className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <p className="text-xs text-muted-foreground">Registration Number</p>
                  <p className="text-sm font-medium text-foreground">{mockDrug.registrationNumber}</p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Dosage Tab */}
        {activeTab === 'dosage' && (
          <div className="space-y-4 animate-fade-in">
            <div className="bg-card rounded-xl p-4 card-shadow">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center">
                  <Droplets className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <p className="text-xs text-muted-foreground">Strength</p>
                  <p className="text-lg font-bold text-foreground">{mockDosage.strength}</p>
                </div>
              </div>
              
              <div className="space-y-3 border-t border-border pt-4">
                <div className="flex items-start gap-3">
                  <Clock className="w-5 h-5 text-muted-foreground mt-0.5" />
                  <div>
                    <p className="text-xs text-muted-foreground">Standard Dose</p>
                    <p className="text-sm font-medium text-foreground">{mockDosage.standardDose}</p>
                  </div>
                </div>
                
                <div className="flex items-start gap-3">
                  <Info className="w-5 h-5 text-muted-foreground mt-0.5" />
                  <div>
                    <p className="text-xs text-muted-foreground">Maximum Daily Dose</p>
                    <p className="text-sm font-medium text-foreground">{mockDosage.maxDaily}</p>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-warning-soft border border-warning/20 rounded-xl p-4">
              <h3 className="font-semibold text-warning-foreground mb-2 flex items-center gap-2">
                <AlertTriangle className="w-4 h-4" />
                Instructions
              </h3>
              <p className="text-sm text-warning-foreground/80">{mockDosage.instructions}</p>
            </div>
          </div>
        )}

        {/* Alternatives Tab */}
        {activeTab === 'alternatives' && (
          <div className="space-y-3 animate-fade-in">
            <div className="bg-accent/50 rounded-xl p-3 mb-4">
              <p className="text-sm text-muted-foreground">
                <span className="font-semibold text-foreground">{mockAlternatives.length} alternatives</span> found with the same active ingredient
              </p>
            </div>
            {mockAlternatives.map((drug) => (
              <DrugCard key={drug.id} drug={drug} />
            ))}
          </div>
        )}

        {/* Interactions Tab */}
        {activeTab === 'interactions' && (
          <div className="space-y-3 animate-fade-in">
            <div className="bg-danger-soft rounded-xl p-3 mb-4">
              <p className="text-sm text-danger">
                <span className="font-semibold">{mockInteractions.length} known interactions.</span> Always consult a healthcare professional.
              </p>
            </div>
            {mockInteractions.map((interaction) => {
              const colors = severityColors[interaction.severity as keyof typeof severityColors];
              return (
                <div 
                  key={interaction.id} 
                  className={cn("rounded-xl p-4 border", colors.bg, colors.border)}
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-semibold text-foreground">{interaction.name}</span>
                    <Badge 
                      variant={interaction.severity === 'major' ? 'danger' : interaction.severity === 'moderate' ? 'warning' : 'info'}
                      size="sm"
                    >
                      {interaction.severity.toUpperCase()}
                    </Badge>
                  </div>
                  <p className="text-sm text-muted-foreground">{interaction.description}</p>
                </div>
              );
            })}
          </div>
        )}

        {/* Price History Tab */}
        {activeTab === 'price' && (
          <div className="animate-fade-in">
            <div className="bg-card rounded-xl p-4 card-shadow">
              <h3 className="font-semibold text-foreground mb-4">Price History</h3>
              <div className="space-y-2">
                {mockPriceHistory.map((item, index) => {
                  const prevPrice = mockPriceHistory[index + 1]?.price;
                  const change = prevPrice ? ((item.price - prevPrice) / prevPrice) * 100 : 0;
                  return (
                    <div key={item.date} className="flex items-center justify-between py-2 border-b border-border last:border-0">
                      <span className="text-sm text-muted-foreground">{item.date}</span>
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-foreground">{item.price.toFixed(2)} EGP</span>
                        {change !== 0 && (
                          <Badge variant={change > 0 ? 'priceUp' : 'priceDown'} size="sm">
                            {change > 0 ? '+' : ''}{change.toFixed(0)}%
                          </Badge>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default DrugDetailsScreen;
