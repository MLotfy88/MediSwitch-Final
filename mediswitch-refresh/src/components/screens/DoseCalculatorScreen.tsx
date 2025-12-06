import React, { useState } from 'react';
import { 
  Calculator, 
  ArrowLeft,
  User,
  Weight,
  Pill,
  RotateCcw,
  Info,
  ChevronDown,
  Baby,
  PersonStanding
} from 'lucide-react';
import { useTheme } from '@/hooks/useTheme';
import { cn } from '@/lib/utils';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';

interface DrugDosage {
  id: string;
  nameEn: string;
  nameAr: string;
  dosePerKg: number;
  maxDose: number;
  unit: string;
  frequency: string;
  frequencyAr: string;
  notes?: string;
  notesAr?: string;
}

const drugDosages: DrugDosage[] = [
  { 
    id: '1', 
    nameEn: 'Amoxicillin', 
    nameAr: 'أموكسيسيلين',
    dosePerKg: 25,
    maxDose: 500,
    unit: 'mg',
    frequency: 'every 8 hours',
    frequencyAr: 'كل ٨ ساعات',
    notes: 'For mild to moderate infections',
    notesAr: 'للعدوى الخفيفة إلى المتوسطة'
  },
  { 
    id: '2', 
    nameEn: 'Ibuprofen', 
    nameAr: 'إيبوبروفين',
    dosePerKg: 10,
    maxDose: 400,
    unit: 'mg',
    frequency: 'every 6-8 hours',
    frequencyAr: 'كل ٦-٨ ساعات',
    notes: 'Give with food. Max 40mg/kg/day',
    notesAr: 'يعطى مع الطعام. الحد الأقصى ٤٠ مجم/كجم/يوم'
  },
  { 
    id: '3', 
    nameEn: 'Paracetamol (Acetaminophen)', 
    nameAr: 'باراسيتامول',
    dosePerKg: 15,
    maxDose: 1000,
    unit: 'mg',
    frequency: 'every 4-6 hours',
    frequencyAr: 'كل ٤-٦ ساعات',
    notes: 'Max 4 doses per 24 hours',
    notesAr: 'الحد الأقصى ٤ جرعات في ٢٤ ساعة'
  },
  { 
    id: '4', 
    nameEn: 'Azithromycin', 
    nameAr: 'أزيثرومايسين',
    dosePerKg: 10,
    maxDose: 500,
    unit: 'mg',
    frequency: 'once daily',
    frequencyAr: 'مرة واحدة يومياً',
    notes: 'Day 1 loading dose may be 10mg/kg',
    notesAr: 'جرعة التحميل في اليوم الأول قد تكون ١٠ مجم/كجم'
  },
  { 
    id: '5', 
    nameEn: 'Cetirizine', 
    nameAr: 'سيتريزين',
    dosePerKg: 0.25,
    maxDose: 10,
    unit: 'mg',
    frequency: 'once daily',
    frequencyAr: 'مرة واحدة يومياً',
    notes: 'For children over 2 years',
    notesAr: 'للأطفال فوق سنتين'
  },
  { 
    id: '6', 
    nameEn: 'Metronidazole', 
    nameAr: 'ميترونيدازول',
    dosePerKg: 7.5,
    maxDose: 500,
    unit: 'mg',
    frequency: 'every 8 hours',
    frequencyAr: 'كل ٨ ساعات',
    notes: 'For anaerobic infections',
    notesAr: 'للعدوى اللاهوائية'
  },
];

interface DoseCalculatorScreenProps {
  onBack?: () => void;
}

const DoseCalculatorScreen: React.FC<DoseCalculatorScreenProps> = ({ onBack }) => {
  const { language, isRTL } = useTheme();
  const [weight, setWeight] = useState('');
  const [age, setAge] = useState('');
  const [ageUnit, setAgeUnit] = useState<'years' | 'months'>('years');
  const [selectedDrug, setSelectedDrug] = useState<DrugDosage | null>(null);
  const [showDrugList, setShowDrugList] = useState(false);

  const calculateDose = () => {
    if (!selectedDrug || !weight) return null;
    
    const weightNum = parseFloat(weight);
    if (isNaN(weightNum) || weightNum <= 0) return null;

    const calculatedDose = weightNum * selectedDrug.dosePerKg;
    const finalDose = Math.min(calculatedDose, selectedDrug.maxDose);
    
    return {
      dose: finalDose.toFixed(1),
      isMaxed: calculatedDose > selectedDrug.maxDose,
      unit: selectedDrug.unit,
      frequency: language === 'ar' ? selectedDrug.frequencyAr : selectedDrug.frequency,
    };
  };

  const result = calculateDose();

  const resetCalculator = () => {
    setWeight('');
    setAge('');
    setSelectedDrug(null);
  };

  const isChild = () => {
    if (!age) return null;
    const ageNum = parseFloat(age);
    if (ageUnit === 'months') return ageNum < 144; // 12 years in months
    return ageNum < 12;
  };

  return (
    <div className="pb-24 bg-background min-h-screen">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-gradient-to-br from-primary to-primary-dark text-primary-foreground px-4 py-4">
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
            <Calculator className="w-5 h-5" />
          </div>
          <div>
            <h1 className="text-lg font-bold">
              {language === 'ar' ? 'حاسبة الجرعات' : 'Dose Calculator'}
            </h1>
            <p className="text-xs opacity-80">
              {language === 'ar' ? 'احسب الجرعة المناسبة بناءً على الوزن' : 'Calculate appropriate dose based on weight'}
            </p>
          </div>
        </div>
      </div>

      <div className="px-4 py-4 space-y-4">
        {/* Patient Info Card */}
        <div className="bg-card rounded-xl p-4 card-shadow">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-foreground flex items-center gap-2" dir={isRTL ? 'rtl' : 'ltr'}>
              <User className="w-4 h-4 text-primary" />
              {language === 'ar' ? 'بيانات المريض' : 'Patient Information'}
            </h3>
            <button 
              onClick={resetCalculator}
              className="p-2 rounded-lg bg-muted hover:bg-muted/80 transition-colors"
            >
              <RotateCcw className="w-4 h-4 text-muted-foreground" />
            </button>
          </div>

          <div className="space-y-4">
            {/* Weight Input */}
            <div>
              <Label className="text-sm text-muted-foreground mb-2 flex items-center gap-2">
                <Weight className="w-4 h-4" />
                {language === 'ar' ? 'الوزن (كجم)' : 'Weight (kg)'}
              </Label>
              <Input
                type="number"
                value={weight}
                onChange={(e) => setWeight(e.target.value)}
                placeholder={language === 'ar' ? 'أدخل الوزن...' : 'Enter weight...'}
                className="text-lg"
              />
            </div>

            {/* Age Input */}
            <div>
              <Label className="text-sm text-muted-foreground mb-2 flex items-center gap-2">
                <User className="w-4 h-4" />
                {language === 'ar' ? 'العمر' : 'Age'}
              </Label>
              <div className="flex gap-2">
                <Input
                  type="number"
                  value={age}
                  onChange={(e) => setAge(e.target.value)}
                  placeholder={language === 'ar' ? 'العمر...' : 'Age...'}
                  className="flex-1"
                />
                <div className="flex rounded-lg overflow-hidden border border-border">
                  <button
                    onClick={() => setAgeUnit('years')}
                    className={cn(
                      "px-3 py-2 text-sm font-medium transition-colors",
                      ageUnit === 'years' 
                        ? "bg-primary text-primary-foreground" 
                        : "bg-muted text-muted-foreground hover:bg-muted/80"
                    )}
                  >
                    {language === 'ar' ? 'سنة' : 'Years'}
                  </button>
                  <button
                    onClick={() => setAgeUnit('months')}
                    className={cn(
                      "px-3 py-2 text-sm font-medium transition-colors",
                      ageUnit === 'months' 
                        ? "bg-primary text-primary-foreground" 
                        : "bg-muted text-muted-foreground hover:bg-muted/80"
                    )}
                  >
                    {language === 'ar' ? 'شهر' : 'Months'}
                  </button>
                </div>
              </div>
            </div>

            {/* Patient Type Badge */}
            {age && (
              <div className="flex items-center gap-2">
                {isChild() ? (
                  <Badge variant="info" className="flex items-center gap-1">
                    <Baby className="w-3 h-3" />
                    {language === 'ar' ? 'طفل' : 'Pediatric'}
                  </Badge>
                ) : (
                  <Badge variant="secondary" className="flex items-center gap-1">
                    <PersonStanding className="w-3 h-3" />
                    {language === 'ar' ? 'بالغ' : 'Adult'}
                  </Badge>
                )}
              </div>
            )}
          </div>
        </div>

        {/* Drug Selection */}
        <div className="bg-card rounded-xl p-4 card-shadow">
          <h3 className="font-semibold text-foreground mb-3 flex items-center gap-2" dir={isRTL ? 'rtl' : 'ltr'}>
            <Pill className="w-4 h-4 text-primary" />
            {language === 'ar' ? 'اختر الدواء' : 'Select Drug'}
          </h3>

          <button
            onClick={() => setShowDrugList(!showDrugList)}
            className="w-full flex items-center justify-between p-4 border border-border rounded-xl hover:bg-muted/50 transition-colors"
          >
            <span className={cn("font-medium", selectedDrug ? "text-foreground" : "text-muted-foreground")}>
              {selectedDrug 
                ? (language === 'ar' ? selectedDrug.nameAr : selectedDrug.nameEn)
                : (language === 'ar' ? 'اختر دواء...' : 'Select a drug...')}
            </span>
            <ChevronDown className={cn("w-5 h-5 text-muted-foreground transition-transform", showDrugList && "rotate-180")} />
          </button>

          {showDrugList && (
            <div className="mt-2 max-h-64 overflow-y-auto border border-border rounded-xl divide-y divide-border">
              {drugDosages.map((drug) => (
                <button
                  key={drug.id}
                  onClick={() => {
                    setSelectedDrug(drug);
                    setShowDrugList(false);
                  }}
                  className={cn(
                    "w-full p-4 text-start hover:bg-muted/50 transition-colors",
                    selectedDrug?.id === drug.id && "bg-primary/10"
                  )}
                  dir={isRTL ? 'rtl' : 'ltr'}
                >
                  <p className="font-medium text-foreground">
                    {language === 'ar' ? drug.nameAr : drug.nameEn}
                  </p>
                  <p className="text-xs text-muted-foreground mt-1">
                    {drug.dosePerKg} {drug.unit}/kg • {language === 'ar' ? drug.frequencyAr : drug.frequency}
                  </p>
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Result */}
        {result && selectedDrug && (
          <div className="bg-gradient-to-br from-success/10 to-success/5 border border-success/30 rounded-xl p-4 animate-fade-in">
            <h3 className="font-semibold text-success mb-4 flex items-center gap-2" dir={isRTL ? 'rtl' : 'ltr'}>
              <Calculator className="w-4 h-4" />
              {language === 'ar' ? 'الجرعة المحسوبة' : 'Calculated Dose'}
            </h3>

            <div className="text-center py-4">
              <p className="text-4xl font-bold text-success mb-1">
                {result.dose} {result.unit}
              </p>
              <p className="text-sm text-success/80">{result.frequency}</p>
              
              {result.isMaxed && (
                <Badge variant="warning" className="mt-3">
                  {language === 'ar' ? 'تم تطبيق الحد الأقصى للجرعة' : 'Maximum dose applied'}
                </Badge>
              )}
            </div>

            {/* Drug Info */}
            <div className="mt-4 pt-4 border-t border-success/20 space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">
                  {language === 'ar' ? 'الجرعة لكل كجم:' : 'Dose per kg:'}
                </span>
                <span className="font-medium text-foreground">
                  {selectedDrug.dosePerKg} {selectedDrug.unit}/kg
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">
                  {language === 'ar' ? 'الحد الأقصى للجرعة:' : 'Maximum dose:'}
                </span>
                <span className="font-medium text-foreground">
                  {selectedDrug.maxDose} {selectedDrug.unit}
                </span>
              </div>
              {selectedDrug.notes && (
                <div className="bg-background/50 rounded-lg p-3 mt-3">
                  <p className="text-xs text-muted-foreground" dir={isRTL ? 'rtl' : 'ltr'}>
                    <span className="font-semibold text-foreground">
                      {language === 'ar' ? 'ملاحظات: ' : 'Notes: '}
                    </span>
                    {language === 'ar' ? selectedDrug.notesAr : selectedDrug.notes}
                  </p>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Disclaimer */}
        <div className="bg-muted/50 rounded-xl p-4 flex items-start gap-3" dir={isRTL ? 'rtl' : 'ltr'}>
          <Info className="w-5 h-5 text-muted-foreground flex-shrink-0 mt-0.5" />
          <p className="text-xs text-muted-foreground">
            {language === 'ar' 
              ? 'هذه الحاسبة للإرشاد فقط ولا تحل محل المشورة الطبية المهنية. تحقق دائمًا من الجرعات مع مراجع موثوقة واستشر طبيبًا أو صيدليًا.'
              : 'This calculator is for guidance only and does not replace professional medical advice. Always verify doses with reliable references and consult a doctor or pharmacist.'}
          </p>
        </div>
      </div>
    </div>
  );
};

export default DoseCalculatorScreen;
