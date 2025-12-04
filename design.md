```jsx
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence, AnimateSharedLayout } from 'framer-motion';
import { 
  Sun, Moon, Search, Filter, Heart, Calculator, AlertTriangle, 
  Pill, Menu, X, ChevronLeft, ChevronRight, Plus, Check, Star,
  Home, Settings, ArrowUpDown, AlertCircle, Info, User, Bell, 
  CreditCard, Shield, Languages, LogOut, Clock, Activity, Scale,
  FileText, Tag, Package, Droplet, Zap, HelpCircle, Share2, 
  BarChart2, TrendingUp, MapPin, Building2, Ruler, Percent, 
  FlaskConical, Calendar, MessageCircle, Bookmark, Loader2
} from 'lucide-react';

const App = () => {
  const [isDarkMode, setIsDarkMode] = useState(false);
  const [activeTab, setActiveTab] = useState('home');
  const [selectedDrug, setSelectedDrug] = useState(null);
  const [interactionDrugs, setInteractionDrugs] = useState([]);
  const [showFilters, setShowFilters] = useState(false);
  const [activeDrugTab, setActiveDrugTab] = useState('info');
  const [searchQuery, setSearchQuery] = useState('');
  const [filteredDrugs, setFilteredDrugs] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  
  // Theme settings
  useEffect(() => {
    document.documentElement.classList.toggle('dark', isDarkMode);
  }, [isDarkMode]);
  
  // Filter drugs based on search query
  useEffect(() => {
    if (searchQuery.trim() === '') {
      setFilteredDrugs(drugs);
      return;
    }
    
    const query = searchQuery.toLowerCase();
    const filtered = drugs.filter(drug => 
      drug.name.toLowerCase().includes(query) || 
      drug.arabicName.toLowerCase().includes(query) ||
      drug.category.toLowerCase().includes(query) ||
      drug.company.toLowerCase().includes(query)
    );
    setFilteredDrugs(filtered);
  }, [searchQuery]);
  
  // Mock data
  const categories = [
    { id: 1, name: 'مسكنات', icon: <Pill size={20} /> },
    { id: 2, name: 'مضادات حيوية', icon: <FlaskConical size={20} /> },
    { id: 3, name: 'أمراض مزمنة', icon: <Heart size={20} /> },
    { id: 4, name: 'فيتامينات', icon: <Droplet size={20} /> },
    { id: 5, name: 'مضادات الهيستامين', icon: <Zap size={20} /> },
    { id: 6, name: 'أدوية القلب', icon: <Activity size={20} /> },
    { id: 7, name: 'السكري', icon: <Scale size={20} /> },
    { id: 8, name: 'الضغط', icon: <BarChart2 size={20} /> },
  ];
  
  const drugs = [
    { 
      id: 1, 
      name: 'بانادول', 
      arabicName: 'أسيتامينوفين', 
      price: '12.50', 
      oldPrice: '15.00', 
      category: 'مسكنات',
      company: 'شركة الأدوية الدولية',
      description: 'يُستخدم لعلاج الآلام الخفيفة إلى المتوسطة والحمى. يُنصح بعدم تجاوز الجرعة اليومية القصوى.',
      dosage: '500 ملغ كل 4-6 ساعات حسب الحاجة، بحد أقصى 4000 ملغ يومياً',
      form: 'أقراص',
      unit: 'علبة تحتوي على 20 قرص',
      interactions: [
        { severity: 'major', drug: 'وارفارين', effect: 'زيادة خطر النزيف', recommendation: 'تجنب الاستخدام المتزامن أو المراقبة الطبية الدقيقة' },
        { severity: 'moderate', drug: 'الكحول', effect: 'زيادة خطر تلف الكبد', recommendation: 'تجنب شرب الكحول أثناء تناول الدواء' }
      ],
      lastUpdated: '15 نوفمبر 2023',
      isFavorite: true,
      priceHistory: [
        { date: 'أكتوبر 2023', price: '15.00' },
        { date: 'نوفمبر 2023', price: '12.50' }
      ]
    },
    { 
      id: 2, 
      name: 'أموكسيسيلين', 
      arabicName: 'أموكسيسيلين', 
      price: '22.75', 
      category: 'مضادات حيوية',
      company: 'شركة النيل للأدوية',
      description: 'مضاد حيوي واسع الطيف يُستخدم لعلاج الالتهابات البكتيرية المختلفة.',
      dosage: '500 ملغ كل 8 ساعات، أو حسب إرشادات الطبيب',
      form: 'أقراص',
      unit: 'علبة تحتوي على 14 قرص',
      interactions: [
        { severity: 'moderate', drug: 'الميثوتريكسات', effect: 'زيادة مستويات الميثوتريكسات في الدم', recommendation: 'المراقبة الطبية ضرورية' }
      ],
      lastUpdated: '10 نوفمبر 2023',
      isFavorite: false,
      priceHistory: [
        { date: 'سبتمبر 2023', price: '20.50' },
        { date: 'نوفمبر 2023', price: '22.75' }
      ]
    },
    { 
      id: 3, 
      name: 'جلوكوفاج', 
      arabicName: 'ميتفورمين', 
      price: '18.30', 
      category: 'أمراض مزمنة',
      company: 'شركة مصر للأدوية',
      description: 'يُستخدم لعلاج مرض السكري من النوع الثاني، يساعد على التحكم في مستويات السكر في الدم.',
      dosage: '500-1000 ملغ مرتين يومياً مع الوجبات',
      form: 'أقراص ممتدة المفعول',
      unit: 'علبة تحتوي على 30 قرص',
      interactions: [
        { severity: 'major', drug: 'الContrast dye', effect: 'زيادة خطر Acidosis اللبني', recommendation: 'يجب إيقاف الدواء قبل الإجراءات التي تتضمن صبغة التباين' }
      ],
      lastUpdated: '12 نوفمبر 2023',
      isFavorite: false,
      priceHistory: [
        { date: 'أكتوبر 2023', price: '18.30' }
      ]
    },
    { 
      id: 4, 
      name: 'ديكساميثازون', 
      arabicName: 'ديكساميثازون', 
      price: '8.90', 
      category: 'مسكنات',
      company: 'شركة الأدوية الحديثة',
      description: 'كورتيكوستيرويد قوي يُستخدم للحد من الالتهاب والألم في حالات مختلفة.',
      dosage: '0.5-9 ملغ يومياً مقسمة على عدة جرعات',
      form: 'أقراص',
      unit: 'علبة تحتوي على 10 أقراص',
      interactions: [
        { severity: 'major', drug: 'الوارفارين', effect: 'زيادة خطر النزيف', recommendation: 'المراقبة المنتظمة لـ INR ضرورية' }
      ],
      lastUpdated: '5 نوفمبر 2023',
      isFavorite: false,
      priceHistory: [
        { date: 'سبتمبر 2023', price: '9.50' },
        { date: 'نوفمبر 2023', price: '8.90' }
      ]
    },
    { 
      id: 5, 
      name: 'لوراتيدين', 
      arabicName: 'لوراتيدين', 
      price: '15.25', 
      category: 'مضادات الهيستامين',
      company: 'شركة النيل للأدوية',
      description: 'مضاد هيستامين غير مسبب للنعاس يُستخدم لعلاج الحساسية الموسمية وأعراضها.',
      dosage: '10 ملغ مرة يومياً',
      form: 'أقراص',
      unit: 'علبة تحتوي على 10 أقراص',
      interactions: [],
      lastUpdated: '8 نوفمبر 2023',
      isFavorite: true,
      priceHistory: [
        { date: 'أكتوبر 2023', price: '15.25' }
      ]
    },
    { 
      id: 6, 
      name: 'أتورفاستاتين', 
      arabicName: 'أتورفاستاتين', 
      price: '35.75', 
      category: 'أدوية القلب',
      company: 'شركة مصر للأدوية',
      description: 'يُستخدم لخفض مستويات الكوليسترول الضار (LDL) والدهون الثلاثية في الدم.',
      dosage: '10-80 ملغ مرة يومياً في المساء',
      form: 'أقراص',
      unit: 'علبة تحتوي على 28 قرص',
      interactions: [
        { severity: 'major', drug: 'الجريب فروت', effect: 'زيادة تركيز الدواء في الدم', recommendation: 'تجنب تناول الجريب فروت أثناء العلاج' }
      ],
      lastUpdated: '14 نوفمبر 2023',
      isFavorite: false,
      priceHistory: [
        { date: 'سبتمبر 2023', price: '32.50' },
        { date: 'نوفمبر 2023', price: '35.75' }
      ]
    },
  ];
  
  const popularDrugs = drugs.slice(0, 3);
  const recentDrugs = drugs.slice(2, 5);
  const alternatives = drugs.slice(1, 4);
  
  const getBgColor = () => isDarkMode ? 'bg-slate-900' : 'bg-slate-50';
  const getTextColor = () => isDarkMode ? 'text-slate-200' : 'text-slate-800';
  const getCardBg = () => isDarkMode ? 'bg-slate-800' : 'bg-white';
  const getBorderColor = () => isDarkMode ? 'border-slate-700' : 'border-slate-200';
  const getHeaderBg = () => isDarkMode ? 'bg-gradient-to-r from-indigo-900 to-purple-900' : 'bg-gradient-to-r from-indigo-600 to-purple-600';
  const getPrimaryColor = () => isDarkMode ? 'text-indigo-400' : 'text-indigo-600';
  const getSecondaryBg = () => isDarkMode ? 'bg-slate-800/70' : 'bg-slate-100';
  const getHoverBg = () => isDarkMode ? 'hover:bg-slate-700/50' : 'hover:bg-slate-50';
  
  const FavoriteButton = ({ isFavorite, onClick }) => (
    <button 
      onClick={onClick}
      className={`p-1.5 rounded-lg transition-all duration-200 ${
        isFavorite 
          ? 'text-amber-500 bg-amber-500/10' 
          : `${getHoverBg()}`
      }`}
    >
      <Heart 
        size={18} 
        fill={isFavorite ? 'currentColor' : 'none'} 
        className={isFavorite ? 'text-amber-500' : getTextColor()}
      />
    </button>
  );
  
  const DrugCard = ({ drug, detailed = false }) => (
    <motion.div 
      whileHover={{ y: -3 }}
      className={`${getCardBg()} ${getBorderColor()} border rounded-2xl overflow-hidden shadow-sm transition-all duration-200`}
    >
      <div className="p-4">
        <div className="flex items-start">
          <div className="flex-1 min-w-0">
            <div className="flex items-baseline flex-wrap">
              <h3 className="font-bold text-lg truncate">{drug.name}</h3>
              {drug.oldPrice && (
                <span className={`mr-2 px-2 py-0.5 rounded-full text-xs font-medium ${
                  isDarkMode ? 'bg-emerald-900/40 text-emerald-400' : 'bg-emerald-100 text-emerald-800'
                }`}>
                  <TrendingUp size={12} className="inline mr-0.5" />
                  سعر منخفض
                </span>
              )}
            </div>
            <p className={`mt-0.5 ${getPrimaryColor()} font-medium text-base truncate`}>
              {drug.arabicName}
            </p>
            
            {detailed && (
              <div className="mt-3 space-y-2">
                <div className="flex flex-wrap items-center gap-x-4 gap-y-1.5">
                  <div className="flex items-center">
                    <Building2 size={16} className="text-slate-500 dark:text-slate-400 mr-1.5" />
                    <span className={`text-sm ${getTextColor()}`}>
                      {drug.company}
                    </span>
                  </div>
                  
                  <div className="flex items-center">
                    <Tag size={16} className="text-slate-500 dark:text-slate-400 mr-1.5" />
                    <span className={`px-2 py-0.5 rounded-full text-xs ${
                      isDarkMode ? 'bg-indigo-900/70 text-indigo-300' : 'bg-indigo-100 text-indigo-800'
                    }`}>
                      {drug.category}
                    </span>
                  </div>
                </div>
                
                <div className="flex items-center">
                  <Ruler size={16} className="text-slate-500 dark:text-slate-400 mr-1.5" />
                  <span className={`text-sm ${getTextColor()}`}>
                    {drug.form} • {drug.unit}
                  </span>
                </div>
              </div>
            )}
          </div>
          
          <div className="text-left mr-3 flex-shrink-0">
            <div className="flex flex-col items-end">
              <div className="flex items-baseline">
                <span className="font-bold text-xl text-emerald-600">{drug.price} ج.م</span>
                {drug.oldPrice && (
                  <span className={`mr-2 text-sm font-medium ${
                    isDarkMode ? 'text-slate-400' : 'text-slate-500'
                  } line-through`}>
                    {drug.oldPrice} ج.م
                  </span>
                )}
              </div>
              {detailed && drug.oldPrice && (
                <span className="text-xs bg-emerald-100 text-emerald-800 px-1.5 py-0.5 rounded-full mt-1 inline-block">
                  -16%
                </span>
              )}
            </div>
          </div>
        </div>
        
        {detailed && (
          <div className="mt-4 pt-4 border-t border-slate-200 dark:border-slate-700">
            <p className={`text-sm ${getTextColor()} opacity-90 line-clamp-2`}>
              {drug.description}
            </p>
          </div>
        )}
        
        <div className="mt-4 flex justify-between items-center pt-2">
          <div className="flex space-x-2 space-x-reverse">
            <button 
              className={`p-1.5 rounded-lg ${
                isDarkMode ? 'hover:bg-slate-700' : 'hover:bg-slate-100'
              }`}
              onClick={(e) => {
                e.stopPropagation();
                setSelectedDrug(drug);
              }}
            >
              <Info size={18} className={getTextColor()} />
            </button>
            <FavoriteButton 
              isFavorite={drug.isFavorite} 
              onClick={(e) => {
                e.stopPropagation();
                // Handle favorite toggle
              }} 
            />
          </div>
          
          {detailed && (
            <motion.button
              whileTap={{ scale: 0.95 }}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium flex items-center ${
                isDarkMode 
                  ? 'bg-indigo-900/70 text-indigo-300 hover:bg-indigo-800/70' 
                  : 'bg-indigo-50 text-indigo-700 hover:bg-indigo-100'
              }`}
            >
              <ArrowUpDown size={16} className="ml-1.5" />
              عرض البدائل
            </motion.button>
          )}
        </div>
      </div>
    </motion.div>
  );
  
  const CategoryChip = ({ category }) => (
    <motion.div 
      whileTap={{ scale: 0.98 }}
      className={`flex flex-col items-center p-3.5 rounded-2xl ${getCardBg()} ${getBorderColor()} border transition-all duration-200`}
    >
      <div className={`p-3 rounded-xl mb-2 ${
        isDarkMode ? 'bg-indigo-900/50' : 'bg-indigo-50'
      } flex items-center justify-center`}>
        {React.cloneElement(category.icon, { 
          className: getPrimaryColor(),
          strokeWidth: 1.8
        })}
      </div>
      <span className={`text-sm font-medium ${getTextColor()} text-center leading-tight`}>{category.name}</span>
    </motion.div>
  );
  
  const InteractionCard = ({ severity, drug1, drug2, effect, recommendation }) => {
    const getSeverityConfig = () => {
      switch(severity) {
        case 'major':
          return {
            color: 'border-red-500 bg-red-500/5',
            badgeColor: 'bg-red-100 text-red-800 dark:bg-red-900/50 dark:text-red-400',
            iconColor: 'text-red-600',
            severityText: 'خطير',
            icon: <AlertCircle size={18} />
          };
        case 'moderate':
          return {
            color: 'border-amber-500 bg-amber-500/5',
            badgeColor: 'bg-amber-100 text-amber-800 dark:bg-amber-900/50 dark:text-amber-400',
            iconColor: 'text-amber-600',
            severityText: 'متوسط',
            icon: <AlertTriangle size={18} />
          };
        default:
          return {
            color: 'border-yellow-500 bg-yellow-500/5',
            badgeColor: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/50 dark:text-yellow-400',
            iconColor: 'text-yellow-600',
            severityText: 'طفيف',
            icon: <Info size={18} />
          };
      }
    };
    
    const config = getSeverityConfig();
    
    return (
      <motion.div 
        initial={{ opacity: 0, x: -20 }}
        animate={{ opacity: 1, x: 0 }}
        className={`${getCardBg()} ${getBorderColor()} border rounded-2xl p-4 mb-4 ${config.color}`}
      >
        <div className="flex items-start">
          <div className={`${config.badgeColor} p-2 rounded-lg mr-3 mt-1 flex-shrink-0`}>
            {config.icon}
          </div>
          <div className="flex-1 min-w-0">
            <h4 className="font-bold text-base truncate">{drug1} + {drug2}</h4>
            <div className="mt-2 space-y-1.5">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400 flex items-center">
                  <span className="ml-1">•</span> التأثير:
                </p>
                <p className={`mt-0.5 text-sm ${getTextColor()} opacity-90`}>
                  {effect}
                </p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400 flex items-center">
                  <span className="ml-1">•</span> التوصية:
                </p>
                <p className={`mt-0.5 text-sm ${getTextColor()} opacity-90`}>
                  {recommendation}
                </p>
              </div>
            </div>
            <div className="mt-3 flex flex-wrap gap-1.5">
              <span className={`px-2.5 py-0.5 rounded-full text-xs font-medium ${config.badgeColor}`}>
                {config.severityText}
              </span>
              <span className={`px-2.5 py-0.5 rounded-full text-xs font-medium ${
                isDarkMode ? 'bg-indigo-900/70 text-indigo-300' : 'bg-indigo-100 text-indigo-800'
              }`}>
                <Zap size={12} className="inline mr-0.5" /> يتطلب مراقبة
              </span>
            </div>
          </div>
        </div>
      </motion.div>
    );
  };
  
  const SettingsItem = ({ icon, title, description, children, rightIcon = <ChevronLeft size={18} />, onClick }) => (
    <motion.div
      whileTap={{ scale: 0.99 }}
      className={`${getCardBg()} rounded-2xl overflow-hidden mb-3`}
    >
      <button 
        onClick={onClick}
        className="w-full text-left"
      >
        <div className="flex items-center p-4">
          <div className={`p-3 rounded-xl mr-4 ${
            isDarkMode ? 'bg-indigo-900/70' : 'bg-indigo-50'
          }`}>
            {React.cloneElement(icon, { 
              className: getPrimaryColor(),
              size: 22,
              strokeWidth: 1.8
            })}
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="font-bold text-base truncate">{title}</h3>
            {description && (
              <p className={`text-sm mt-0.5 ${isDarkMode ? 'text-slate-300' : 'text-slate-600'} truncate`}>
                {description}
              </p>
            )}
            {children}
          </div>
          {rightIcon && React.cloneElement(rightIcon, { 
            className: `${getTextColor()} opacity-70`,
            size: 18
          })}
        </div>
      </button>
    </motion.div>
  );
  
  const SectionHeader = ({ title, actionText, onAction, subtitle }) => (
    <div className="mb-5">
      <div className="flex justify-between items-start mb-2">
        <div>
          <h2 className="text-xl font-bold">{title}</h2>
          {subtitle && (
            <p className={`text-sm mt-1 opacity-80 ${getTextColor()}`}>
              {subtitle}
            </p>
          )}
        </div>
        {actionText && (
          <button 
            onClick={onAction}
            className={`text-sm font-medium flex items-center ${getPrimaryColor()}`}
          >
            {actionText} <ChevronLeft size={16} className="mr-1" strokeWidth={2} />
          </button>
        )}
      </div>
      <div className={`h-1 rounded-full ${
        isDarkMode ? 'bg-indigo-900/50' : 'bg-indigo-100'
      }`} style={{ width: '50px' }} />
    </div>
  );
  
  const PriceHistoryChart = ({ priceHistory }) => {
    if (!priceHistory || priceHistory.length === 0) return null;
    
    const maxHeight = 80;
    const maxValue = Math.max(...priceHistory.map(item => parseFloat(item.price)));
    const minValue = Math.min(...priceHistory.map(item => parseFloat(item.price)));
    const range = maxValue - minValue || 1;
    
    return (
      <div className="mt-4">
        <div className="flex justify-between text-xs mb-2">
          <span className="font-medium text-emerald-600">{maxValue} ج.م</span>
          <span className="font-medium text-slate-500">{minValue} ج.م</span>
        </div>
        
        <div className="flex items-end h-20 space-x-2">
          {priceHistory.map((item, index) => {
            const height = ((parseFloat(item.price) - minValue) / range) * maxHeight + 10;
            const isLast = index === priceHistory.length - 1;
            
            return (
              <div key={index} className="flex-1 flex flex-col items-center">
                <div 
                  className={`w-6 rounded-t-lg ${
                    isLast ? 'bg-emerald-500' : 'bg-slate-300 dark:bg-slate-600'
                  }`}
                  style={{ height: `${height}px` }}
                />
                <span className={`text-xs mt-1 ${isLast ? 'font-bold text-emerald-600' : 'text-slate-500'}`}>
                  {item.date.split(' ')[0]}
                </span>
              </div>
            );
          })}
        </div>
        
        <div className="mt-2 flex justify-between text-xs">
          <span className="text-slate-500">أول سعر</span>
          <span className="font-medium text-emerald-600">آخر سعر</span>
        </div>
      </div>
    );
  };
  
  const DrugDetailsScreen = () => {
    if (!selectedDrug) return null;
    
    const getInteractionAlertConfig = () => {
      if (!selectedDrug.interactions || selectedDrug.interactions.length === 0) {
        return {
          color: 'bg-emerald-50 dark:bg-emerald-900/20 border-emerald-200 dark:border-emerald-800',
          textColor: 'text-emerald-700 dark:text-emerald-400',
          icon: <Check className="text-emerald-600" size={20} />,
          title: 'آمن',
          message: 'لا توجد تفاعلات دوائية معروفة لهذا الدواء'
        };
      }
      
      const hasMajor = selectedDrug.interactions.some(i => i.severity === 'major');
      const count = selectedDrug.interactions.length;
      
      if (hasMajor) {
        return {
          color: 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800',
          textColor: 'text-red-700 dark:text-red-400',
          icon: <AlertCircle className="text-red-600" size={20} />,
          title: 'تحذير خطير',
          message: `يوجد ${count} تفاعلات خطيرة لهذا الدواء`
        };
      }
      
      return {
        color: 'bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800',
        textColor: 'text-amber-700 dark:text-amber-400',
        icon: <AlertTriangle className="text-amber-600" size={20} />,
        title: 'تحذير',
        message: `يوجد ${count} تفاعلات دوائية لهذا الدواء`
      };
    };
    
    const interactionConfig = getInteractionAlertConfig();
    
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -20 }}
        transition={{ duration: 0.3 }}
        className="pb-24"
      >
        {/* Back Button */}
        <div className="flex items-center mb-5">
          <button 
            onClick={() => setSelectedDrug(null)}
            className={`p-1.5 rounded-full ${
              isDarkMode ? 'hover:bg-slate-700' : 'hover:bg-slate-100'
            } mr-2`}
          >
            <ChevronRight size={22} className={getTextColor()} strokeWidth={2} />
          </button>
          <h1 className="text-xl font-bold">تفاصيل الدواء</h1>
        </div>
        
        {/* Drug Header */}
        <div className="mb-8">
          <div className="relative rounded-2xl overflow-hidden">
            <div className={`h-40 ${getHeaderBg()} flex items-center justify-center`}>
              <div className="bg-white/20 backdrop-blur-sm p-4 rounded-xl">
                <Pill size={48} className="text-white" strokeWidth={1.8} />
              </div>
            </div>
            
            <div className={`absolute -bottom-6 left-0 right-0 flex justify-center px-4`}>
              <div className={`${getCardBg()} rounded-2xl shadow-lg border ${getBorderColor()} p-4 w-full max-w-md`}>
                <div className="flex items-start">
                  <div className="flex-1 min-w-0 mr-4">
                    <div className="flex items-baseline">
                      <h1 className="font-bold text-xl truncate">{selectedDrug.name}</h1>
                      {selectedDrug.oldPrice && (
                        <span className={`mr-2 px-2 py-0.5 rounded-full text-xs font-medium ${
                          isDarkMode ? 'bg-emerald-900/40 text-emerald-400' : 'bg-emerald-100 text-emerald-800'
                        }`}>
                          <TrendingUp size={12} className="inline mr-0.5" />
                          سعر منخفض
                        </span>
                      )}
                    </div>
                    <p className={`mt-0.5 ${getPrimaryColor()} font-medium text-lg truncate`}>
                      {selectedDrug.arabicName}
                    </p>
                    
                    <div className="mt-3 flex items-baseline">
                      <span className="font-extrabold text-2xl text-emerald-600">{selectedDrug.price} ج.م</span>
                      {selectedDrug.oldPrice && (
                        <span className={`mr-2 text-base font-medium ${
                          isDarkMode ? 'text-slate-400' : 'text-slate-500'
                        } line-through`}>
                          {selectedDrug.oldPrice} ج.م
                        </span>
                      )}
                    </div>
                  </div>
                  
                  <div className="flex flex-col items-end space-y-2">
                    <FavoriteButton 
                      isFavorite={selectedDrug.isFavorite} 
                      onClick={() => {}} 
                    />
                    <button className={`p-2 rounded-lg ${
                      isDarkMode ? 'bg-indigo-900/50' : 'bg-indigo-50'
                    }`}>
                      <Share2 size={20} className={getPrimaryColor()} strokeWidth={1.8} />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        {/* Alert Banner */}
        <div className={`mb-6 p-4 rounded-xl border ${interactionConfig.color}`}>
          <div className="flex items-start">
            <div className="mr-3 mt-0.5">
              {interactionConfig.icon}
            </div>
            <div>
              <h4 className={`font-bold ${interactionConfig.textColor}`}>{interactionConfig.title}</h4>
              <p className={`mt-1 text-sm ${interactionConfig.textColor}`}>
                {interactionConfig.message}
              </p>
              {selectedDrug.interactions && selectedDrug.interactions.length > 0 && (
                <button 
                  onClick={() => setActiveDrugTab('interactions')}
                  className={`mt-2 text-sm font-medium ${getPrimaryColor()} flex items-center`}
                >
                  عرض التفاصيل <ChevronLeft size={16} className="mr-1" strokeWidth={2} />
                </button>
              )}
            </div>
          </div>
        </div>
        
        {/* Tabs Navigation */}
        <div className="mb-6">
          <div className="flex overflow-x-auto scrollbar-hide border-b border-slate-200 dark:border-slate-700 pb-1">
            {[
              { id: 'info', label: 'المعلومات', icon: <Info size={16} /> },
              { id: 'alternatives', label: 'البدائل', icon: <ArrowUpDown size={16} /> },
              { id: 'dosage', label: 'الجرعات', icon: <Scale size={16} /> },
              { id: 'interactions', label: 'التفاعلات', icon: <AlertCircle size={16} /> },
              { id: 'price', label: 'السعر', icon: <BarChart2 size={16} /> }
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveDrugTab(tab.id)}
                className={`flex items-center px-4 py-2.5 text-sm font-medium whitespace-nowrap border-b-2 ${
                  activeDrugTab === tab.id
                    ? 'border-indigo-600 text-indigo-600 dark:border-indigo-400 dark:text-indigo-400'
                    : `${getTextColor()} opacity-70 border-transparent`
                }`}
              >
                {React.cloneElement(tab.icon, {
                  className: activeDrugTab === tab.id ? (isDarkMode ? 'text-indigo-400' : 'text-indigo-600') : `${getTextColor()} opacity-70`,
                  strokeWidth: 1.8
                })}
                <span className="mr-1.5">{tab.label}</span>
              </button>
            ))}
          </div>
        </div>
        
        {/* Tab Content */}
        <AnimatePresence mode="wait">
          {activeDrugTab === 'info' && (
            <motion.div
              key="info"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="space-y-5"
            >
              <div className={`${getCardBg()} rounded-2xl p-5`}>
                <h3 className="font-bold text-lg mb-4 flex items-center">
                  <FileText size={18} className={`${getPrimaryColor()} ml-2`} strokeWidth={1.8} />
                  الوصف الكامل
                </h3>
                <p className={`leading-relaxed text-base ${getTextColor()} opacity-90`}>
                  {selectedDrug.description}
                </p>
              </div>
              
              <div className={`${getCardBg()} rounded-2xl p-5`}>
                <h3 className="font-bold text-lg mb-4 flex items-center">
                  <Tag size={18} className={`${getPrimaryColor()} ml-2`} strokeWidth={1.8} />
                  المعلومات الأساسية
                </h3>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-3">
                    <div className="flex items-start">
                      <Building2 size={20} className={`${getPrimaryColor()} mt-1 flex-shrink-0`} strokeWidth={1.8} />
                      <div className="mr-3">
                        <p className="text-sm text-slate-500 dark:text-slate-400">الشركة المصنعة</p>
                        <p className={`font-medium text-base ${getTextColor()}`}>{selectedDrug.company}</p>
                      </div>
                    </div>
                    
                    <div className="flex items-start">
                      <Droplet size={20} className={`${getPrimaryColor()} mt-1 flex-shrink-0`} strokeWidth={1.8} />
                      <div className="mr-3">
                        <p className="text-sm text-slate-500 dark:text-slate-400">الشكل الصيدلي</p>
                        <p className={`font-medium text-base ${getTextColor()}`}>{selectedDrug.form}</p>
                      </div>
                    </div>
                  </div>
                  
                  <div className="space-y-3">
                    <div className="flex items-start">
                      <Package size={20} className={`${getPrimaryColor()} mt-1 flex-shrink-0`} strokeWidth={1.8} />
                      <div className="mr-3">
                        <p className="text-sm text-slate-500 dark:text-slate-400">الوحدة</p>
                        <p className={`font-medium text-base ${getTextColor()}`}>{selectedDrug.unit}</p>
                      </div>
                    </div>
                    
                    <div className="flex items-start">
                      <Clock size={20} className={`${getPrimaryColor()} mt-1 flex-shrink-0`} strokeWidth={1.8} />
                      <div className="mr-3">
                        <p className="text-sm text-slate-500 dark:text-slate-400">آخر تحديث</p>
                        <p className={`font-medium text-base ${getTextColor()}`}>{selectedDrug.lastUpdated}</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              
              <div className={`${getCardBg()} rounded-2xl p-5`}>
                <h3 className="font-bold text-lg mb-4 flex items-center">
                  <MessageCircle size={18} className={`${getPrimaryColor()} ml-2`} strokeWidth={1.8} />
                  ملاحظات المستخدمين
                </h3>
                <div className="space-y-4">
                  {[1, 2].map((_, index) => (
                    <div key={index} className="flex items-start">
                      <div className={`w-9 h-9 rounded-full flex items-center justify-center mr-3 ${
                        isDarkMode ? 'bg-indigo-900/70' : 'bg-indigo-100'
                      }`}>
                        <span className={`font-bold ${
                          isDarkMode ? 'text-indigo-300' : 'text-indigo-700'
                        }`}>{index + 1}</span>
                      </div>
                      <div>
                        <div className="flex items-baseline">
                          <h4 className="font-medium">محمد أحمد</h4>
                          <div className="flex ml-2">
                            {[...Array(4)].map((_, i) => (
                              <Star key={i} size={14} className="text-amber-400 fill-current" />
                            ))}
                            <Star size={14} className="text-slate-300 dark:text-slate-600" />
                          </div>
                        </div>
                        <p className={`mt-1 text-sm ${getTextColor()} opacity-90`}>
                          {index === 0 
                            ? 'دواء فعال جداً للصداع النصفي، أنصح به بشدة.' 
                            : 'يعمل بشكل جيد ولكن يسبب لي بعض الدوخة في البداية.'}
                        </p>
                        <p className={`mt-1 text-xs ${isDarkMode ? 'text-slate-400' : 'text-slate-500'}`}>
                          {index === 0 ? 'قبل أسبوع' : 'قبل 3 أيام'}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
                
                <button className={`mt-4 w-full py-2.5 rounded-xl border ${
                  getBorderColor()
                } flex items-center justify-center`}>
                  <Plus size={18} className={getTextColor()} strokeWidth={1.8} />
                  <span className={`mr-2 ${getTextColor()}`}>إضافة مراجعة</span>
                </button>
              </div>
            </motion.div>
          )}
          
          {activeDrugTab === 'alternatives' && (
            <motion.div
              key="alternatives"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="space-y-5"
            >
              <div className={`${getCardBg()} rounded-2xl p-5`}>
                <h3 className="font-bold text-lg mb-4 flex items-center">
                  <ArrowUpDown size={18} className={`${getPrimaryColor()} ml-2`} strokeWidth={1.8} />
                  البدائل المتاحة
                </h3>
                <p className={`mb-4 ${getTextColor()} opacity-90`}>
                  هذه قائمة بالبدائل التي تحتوي على نفس المادة الفعالة أو مواد فعالة مشابهة يمكن استخدامها كبدائل لهذا الدواء.
                </p>
                
                <div className="space-y-4">
                  {alternatives.filter(a => a.id !== selectedDrug.id).map((drug) => (
                    <div key={drug.id} className={`rounded-xl p-4 border ${getBorderColor()}`}>
                      <div className="flex items-start">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-baseline">
                            <h4 className="font-bold text-lg">{drug.name}</h4>
                            {drug.oldPrice && (
                              <span className={`mr-2 px-2 py-0.5 rounded-full text-xs font-medium ${
                                isDarkMode ? 'bg-emerald-900/40 text-emerald-400' : 'bg-emerald-100 text-emerald-800'
                              }`}>
                                أفضل سعر
                              </span>
                            )}
                          </div>
                          <p className={`${getPrimaryColor()} font-medium mt-0.5`}>{drug.arabicName}</p>
                          
                          <div className="mt-3 grid grid-cols-1 md:grid-cols-2 gap-3">
                            <div>
                              <p className="text-sm font-medium text-slate-600 dark:text-slate-400">الشركة</p>
                              <p className={`text-sm mt-0.5 ${getTextColor()}`}>{drug.company}</p>
                            </div>
                            <div>
                              <p className="text-sm font-medium text-slate-600 dark:text-slate-400">الفئة</p>
                              <span className={`text-sm mt-0.5 px-2 py-0.5 rounded-full ${
                                isDarkMode ? 'bg-indigo-900/70 text-indigo-300' : 'bg-indigo-100 text-indigo-800'
                              }`}>
                                {drug.category}
                              </span>
                            </div>
                          </div>
                        </div>
                        
                        <div className="text-left mr-3 flex-shrink-0">
                          <div className="flex flex-col items-end">
                            <span className="font-bold text-xl text-emerald-600">{drug.price} ج.م</span>
                            {drug.oldPrice && (
                              <span className={`mt-1 text-sm ${
                                isDarkMode ? 'text-slate-400' : 'text-slate-500'
                              } line-through`}>
                                {drug.oldPrice} ج.م
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                      
                      <div className="mt-4 pt-4 border-t border-slate-200 dark:border-slate-700 flex justify-end">
                        <button 
                          className={`px-4 py-2 rounded-xl font-medium ${
                            isDarkMode 
                              ? 'bg-indigo-900/70 text-indigo-300 hover:bg-indigo-800/70' 
                              : 'bg-indigo-50 text-indigo-700 hover:bg-indigo-100'
                          }`}
                        >
                          مقارنة
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              
              <div className={`${getSecondaryBg()} rounded-2xl p-5`}>
                <div className="flex items-start">
                  <div className="bg-gradient-to-br from-amber-400 to-amber-600 p-2 rounded-xl mr-3 mt-1">
                    <Star size={24} className="text-white" strokeWidth={1.8} />
                  </div>
                  <div>
                    <h4 className="font-bold text-lg">ميزة Premium</h4>
                    <p className={`text-sm mt-2 ${getTextColor()} opacity-90`}>
                      اشترك في الحساب المميز للحصول على:
                    </p>
                    <ul className="mt-3 space-y-2 pr-2">
                      <li className="flex items-start">
                        <span className="text-emerald-600 mr-2 mt-1">•</span>
                        <span className={`${getTextColor()} opacity-90`}>تحليل مفصل للبدائل مع مقارنة الأسعار والفعالية</span>
                      </li>
                      <li className="flex items-start">
                        <span className="text-emerald-600 mr-2 mt-1">•</span>
                        <span className={`${getTextColor()} opacity-90`}>تنبيهات فورية عند تغير أسعار الأدوية</span>
                      </li>
                      <li className="flex items-start">
                        <span className="text-emerald-600 mr-2 mt-1">•</span>
                        <span className={`${getTextColor()} opacity-90`}>وصول إلى قاعدة بيانات التفاعلات الدوائية الكاملة</span>
                      </li>
                    </ul>
                    <button className="mt-4 bg-amber-500 hover:bg-amber-600 text-white font-bold px-5 py-2.5 rounded-xl transition-colors flex items-center">
                      <Star size={18} className="ml-2" strokeWidth={1.8} />
                      ترقية الحساب
                    </button>
                  </div>
                </div>
              </div>
            </motion.div>
          )}
          
          {activeDrugTab === 'dosage' && (
            <motion.div
              key="dosage"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="space-y-6"
            >
              <div className={`${getCardBg()} rounded-2xl p-5`}>
                <h3 className="font-bold text-lg mb-4 flex items-center">
                  <Scale size={18} className={`${getPrimaryColor()} ml-2`} strokeWidth={1.8} />
                  الجرعة القياسية
                </h3>
                <div className="bg-blue-50 dark:bg-blue-900/30 border border-blue-200 dark:border-blue-800 rounded-xl p-5">
                  <p className="font-bold text-xl text-center text-blue-800 dark:text-blue-300">{selectedDrug.dosage}</p>
                </div>
              </div>
              
              <div className={`${getCardBg()} rounded-2xl p-5`}>
                <h3 className="font-bold text-lg mb-4 flex items-center">
                  <Activity size={18} className={`${getPrimaryColor()} ml-2`} strokeWidth={1.8} />
                  تعليمات الاستخدام
                </h3>
                <div className="space-y-4">
                  {[1, 2, 3, 4].map((num) => (
                    <div key={num} className="flex">
                      <div className="bg-indigo-100 text-indigo-800 dark:bg-indigo-900/50 dark:text-indigo-300 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm mr-3 flex-shrink-0">
                        {num}
                      </div>
                      <p className={`${getTextColor()} opacity-90`}>
                        {num === 1 && 'تناول الدواء مع كمية كافية من الماء.'}
                        {num === 2 && 'يفضل تناول الدواء مع الطعام لتقليل التهيج المعدي.'}
                        {num === 3 && 'لا تتجاوز الجرعة اليومية القصوى الموصى بها.'}
                        {num === 4 && 'يجب إكمال الجرعة الموصوفة بالكامل حتى لو تحسنت الأعراض.'}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
              
              <button 
                onClick={() => {
                  setActiveTab('calculator');
                  setSelectedDrug(null);
                }}
                className="w-full bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white font-bold py-4 rounded-2xl transition-all duration-200 shadow-lg hover:shadow-xl flex items-center justify-center"
              >
                <Calculator size={22} className="ml-2" strokeWidth={1.8} />
                حساب الجرعة المخصصة حسب الوزن والعمر
              </button>
              
              <div className={`${getCardBg()} rounded-2xl p-5 border border-amber-200 dark:border-amber-800 bg-amber-50/50 dark:bg-amber-900/20`}>
                <div className="flex items-start">
                  <div className="bg-amber-100 text-amber-800 dark:bg-amber-900/50 dark:text-amber-300 p-2 rounded-lg mr-3 mt-1">
                    <AlertTriangle size={20} strokeWidth={1.8} />
                  </div>
                  <div>
                    <h4 className="font-bold text-amber-800 dark:text-amber-300">تحذيرات هامة</h4>
                    <ul className="mt-3 space-y-2.5 pr-1">
                      {[1, 2, 3].map((num) => (
                        <li key={num} className="flex items-start">
                          <span className="text-amber-600 mr-2 mt-1">•</span>
                          <span className={`${getTextColor()} opacity-90`}>
                            {num === 1 && 'لا تستخدم هذا الدواء دون استشارة طبية إذا كنت تعاني من مشاكل في الكبد أو الكلى.'}
                            {num === 2 && 'تجنب شرب الكحول أثناء تناول هذا الدواء.'}
                            {num === 3 && 'أخبر طبيبك عن جميع الأدوية التي تتناولها قبل استخدام هذا الدواء.'}
                          </span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              </div>
            </motion.div>
          )}
          
          {activeDrugTab === 'interactions' && (
            <motion.div
              key="interactions"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="space-y-6"
            >
              {selectedDrug.interactions && selectedDrug.interactions.length > 0 ? (
                <>
                  <div className="text-center mb-6 p-5 rounded-2xl bg-gradient-to-br from-red-50 to-amber-50 dark:from-red-900/20 dark:to-amber-900/20">
                    <div className="inline-block p-4 bg-red-100 dark:bg-red-900/40 rounded-2xl mb-4">
                      <AlertCircle size={40} className="text-red-600" strokeWidth={1.8} />
                    </div>
                    <h3 className="font-bold text-2xl text-red-600 dark:text-red-400">
                      تفاعلات دوائية خطيرة
                    </h3>
                    <p className={`mt-3 text-lg ${getTextColor()} opacity-90`}>
                      تم اكتشاف {selectedDrug.interactions.length} تفاعلات دوائية لهذا الدواء
                    </p>
                  </div>
                  
                  <div className="space-y-4">
                    {selectedDrug.interactions.map((interaction, index) => (
                      <InteractionCard 
                        key={index}
                        severity={interaction.severity}
                        drug1={selectedDrug.name}
                        drug2={interaction.drug}
                        effect={interaction.effect}
                        recommendation={interaction.recommendation}
                      />
                    ))}
                  </div>
                  
                  <div className={`${getCardBg()} rounded-2xl p-5 border border-rose-200 dark:border-rose-800`}>
                    <div className="flex items-start">
                      <div className="bg-rose-100 text-rose-800 dark:bg-rose-900/40 dark:text-rose-300 p-3 rounded-xl mr-4 mt-1">
                        <HelpCircle size={24} strokeWidth={1.8} />
                      </div>
                      <div>
                        <h4 className="font-bold text-xl text-rose-600 dark:text-rose-400">نصائح هامة</h4>
                        <ul className="mt-4 space-y-3 pr-1">
                          {[1, 2, 3].map((num) => (
                            <li key={num} className="flex items-start">
                              <span className="text-rose-600 mr-3 mt-1 text-lg">•</span>
                              <span className={`${getTextColor()} opacity-90 text-base`}>
                                {num === 1 && 'أخبر طبيبك أو الصيدلي دائمًا عن جميع الأدوية التي تتناولها (بما في ذلك المكملات الغذائية والأدوية بدون وصفة).'}
                                {num === 2 && 'لا تتوقف عن تناول أي دواء دون استشارة طبيبك أولاً.'}
                                {num === 3 && 'إذا كنت تعاني من أي أعراض غير طبيعية أثناء تناول الأدوية، اطلب المساعدة الطبية فورًا.'}
                              </span>
                            </li>
                          ))}
                        </ul>
                      </div>
                    </div>
                  </div>
                  
                  <button 
                    onClick={() => {
                      setActiveTab('interactions');
                      setSelectedDrug(null);
                      setInteractionDrugs([selectedDrug.name]);
                    }}
                    className="w-full bg-gradient-to-r from-rose-600 to-amber-600 hover:from-rose-700 hover:to-amber-700 text-white font-bold py-4 rounded-2xl transition-all duration-200 shadow-lg hover:shadow-xl flex items-center justify-center"
                  >
                    <AlertTriangle size={22} className="ml-2" strokeWidth={1.8} />
                    فحص تفاعلات مع أدوية أخرى
                  </button>
                </>
              ) : (
                <div className="text-center py-12">
                  <div className="inline-block p-5 bg-emerald-100 dark:bg-emerald-900/30 rounded-2xl mb-5">
                    <Check size={48} className="text-emerald-600" strokeWidth={1.6} />
                  </div>
                  <h3 className="font-bold text-2xl text-emerald-600 dark:text-emerald-400 mb-3">
                    لا توجد تفاعلات دوائية معروفة
                  </h3>
                  <p className={`max-w-md mx-auto text-lg ${getTextColor()} opacity-90`}>
                    لم يتم تسجيل أي تفاعلات دوائية خطيرة لهذا الدواء في قاعدة البيانات الحالية.
                  </p>
                  <div className={`${getSecondaryBg()} rounded-xl p-5 mt-7 max-w-md mx-auto`}>
                    <p className="text-base opacity-80 leading-relaxed">
                      <span className="font-bold">ملاحظة:</span> هذه المعلومات لأغراض إعلامية فقط وليست بديلاً عن الاستشارة الطبية. استشر طبيبك دائمًا قبل تناول أي دواء.
                    </p>
                  </div>
                </div>
              )}
            </motion.div>
          )}
          
          {activeDrugTab === 'price' && (
            <motion.div
              key="price"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="space-y-6"
            >
              <div className={`${getCardBg()} rounded-2xl p-5`}>
                <div className="flex items-start justify-between mb-5">
                  <div>
                    <h3 className="font-bold text-lg">تحليل السعر الحالي</h3>
                    <p className={`mt-1 ${getTextColor()} opacity-90`}>
                      مقارنة مع متوسط أسعار السوق
                    </p>
                  </div>
                  <div className="bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300 px-3 py-1 rounded-full text-sm font-medium">
                    أفضل سعر
                  </div>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                  <div className="text-center p-4 bg-slate-50 dark:bg-slate-800/50 rounded-xl">
                    <p className="text-sm text-slate-500 dark:text-slate-400">سعرنا</p>
                    <p className="font-bold text-2xl text-emerald-600 mt-1">{selectedDrug.price} ج.م</p>
                  </div>
                  <div className="text-center p-4 bg-slate-50 dark:bg-slate-800/50 rounded-xl">
                    <p className="text-sm text-slate-500 dark:text-slate-400">متوسط السوق</p>
                    <p className="font-bold text-2xl text-slate-600 dark:text-slate-300 mt-1">18.75 ج.م</p>
                  </div>
                  <div className="text-center p-4 bg-slate-50 dark:bg-slate-800/50 rounded-xl">
                    <p className="text-sm text-slate-500 dark:text-slate-400">أعلى سعر</p>
                    <p className="font-bold text-2xl text-rose-600 mt-1">22.50 ج.م</p>
                  </div>
                </div>
                
                <div className="mt-4">
                  <p className="text-sm font-medium mb-2">توفير مقارنة بالسوق</p>
                  <div className="w-full bg-slate-200 dark:bg-slate-700 rounded-full h-3 overflow-hidden">
                    <div 
                      className="h-full bg-emerald-500 rounded-full transition-all duration-500"
                      style={{ width: '65%' }}
                    />
                  </div>
                  <p className="text-sm text-emerald-600 mt-1 font-medium">توفر 6.25 ج.م (33%)</p>
                </div>
              </div>
              
              <div className={`${getCardBg()} rounded-2xl p-5`}>
                <h3 className="font-bold text-lg mb-4 flex items-center">
                  <BarChart2 size={18} className={`${getPrimaryColor()} ml-2`} strokeWidth={1.8} />
                  تاريخ السعر
                </h3>
                <PriceHistoryChart priceHistory={selectedDrug.priceHistory} />
              </div>
              
              <div className={`${getCardBg()} rounded-2xl p-5`}>
                <h3 className="font-bold text-lg mb-4 flex items-center">
                  <MapPin size={18} className={`${getPrimaryColor()} ml-2`} strokeWidth={1.8} />
                  الصيدليات القريبة
                </h3>
                
                <div className="space-y-4">
                  {[1, 2, 3].map((index) => (
                    <div key={index} className={`rounded-xl p-3 border ${getBorderColor()}`}>
                      <div className="flex items-start">
                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center mr-3 ${
                          isDarkMode ? 'bg-indigo-900/50' : 'bg-indigo-50'
                        }`}>
                          <span className={`font-bold text-lg ${
                            isDarkMode ? 'text-indigo-400' : 'text-indigo-600'
                          }`}>
                            {index}
                          </span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <h4 className="font-bold">صيدلية النيل {index}</h4>
                          <p className={`mt-0.5 text-sm ${getTextColor()} opacity-90 truncate`}>
                            {index === 1 && 'شارع التحرير، القاهرة'}
                            {index === 2 && 'مدينة نصر، القاهرة'}
                            {index === 3 && 'الجيزة، القاهرة'}
                          </p>
                        </div>
                        <div className="text-left mr-2">
                          <span className="font-bold text-emerald-600">{selectedDrug.price} ج.م</span>
                          <p className={`mt-0.5 text-xs ${
                            isDarkMode ? 'text-slate-400' : 'text-slate-500'
                          }`}>
                            متاح الآن
                          </p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
                
                <button className={`mt-4 w-full py-3 rounded-xl border ${
                  getBorderColor()
                } flex items-center justify-center`}>
                  <ChevronLeft size={18} className={getTextColor()} strokeWidth={1.8} />
                  <span className={`mr-2 ${getTextColor()}`}>عرض جميع الصيدليات</span>
                </button>
              </div>
              
              <button 
                className="w-full bg-gradient-to-r from-emerald-500 to-cyan-500 hover:from-emerald-600 hover:to-cyan-600 text-white font-bold py-4 rounded-2xl transition-all duration-200 shadow-lg hover:shadow-xl flex items-center justify-center"
              >
                <Bookmark size={22} className="ml-2" strokeWidth={1.8} />
                حفظ السعر لمتابعته
              </button>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    );
  };
  
  return (
    <div className={`${getBgColor()} ${getTextColor()} min-h-screen font-sans antialiased overflow-x-hidden`}>
      {/* Header */}
      <header className={`${getHeaderBg()} text-white py-4 px-4 shadow-lg`}>
        <div className="max-w-4xl mx-auto flex justify-between items-center">
          <div className="flex items-center">
            <div className="bg-white/15 backdrop-blur-sm p-2.5 rounded-xl mr-3">
              <Pill size={30} className="text-white" strokeWidth={1.6} />
            </div>
            <div>
              <h1 className="text-xl font-bold tracking-tight">MediSwitch</h1>
              <p className="text-indigo-200 text-sm">مرجعك الآمن للأدوية</p>
            </div>
          </div>
          
          <div className="flex items-center space-x-3 space-x-reverse">
            <button 
              onClick={() => setShowFilters(true)}
              className="p-2.5 rounded-xl bg-white/15 backdrop-blur-sm hover:bg-white/25 transition-colors"
              title="فلترة"
            >
              <Filter size={20} strokeWidth={1.8} />
            </button>
            <button 
              onClick={() => setIsDarkMode(!isDarkMode)}
              className="p-2.5 rounded-xl bg-white/15 backdrop-blur-sm hover:bg-white/25 transition-colors"
              title={isDarkMode ? "الوضع الفاتح" : "الوضع الداكن"}
            >
              {isDarkMode ? <Sun size={20} strokeWidth={1.8} /> : <Moon size={20} strokeWidth={1.8} />}
            </button>
          </div>
        </div>
      </header>
      
      {/* Search Bar */}
      {!selectedDrug && activeTab === 'home' && (
        <div className="max-w-4xl mx-auto px-4 mb-5">
          <div className={`${getCardBg()} rounded-2xl overflow-hidden shadow-sm border ${getBorderColor()}`}>
            <div className="flex items-center p-3.5">
              <Search size={18} className={`${isDarkMode ? 'text-slate-400' : 'text-slate-500'}`} strokeWidth={1.8} />
              <input 
                type="text" 
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="ابحث عن دواء أو شركة أو مادة فعالة..." 
                className={`w-full bg-transparent outline-none text-base mr-3 ${
                  getTextColor()
                } placeholder-${isDarkMode ? 'slate-400' : 'slate-500'}`}
              />
              {searchQuery && (
                <button 
                  onClick={() => setSearchQuery('')}
                  className={`p-1 rounded-full ${
                    isDarkMode ? 'hover:bg-slate-700' : 'hover:bg-slate-100'
                  }`}
                >
                  <X size={18} strokeWidth={2} />
                </button>
              )}
            </div>
          </div>
        </div>
      )}
      
      {/* Main Content */}
      <main className="max-w-4xl mx-auto px-4 pb-28">
        <AnimatePresence mode="wait">
          {!selectedDrug ? (
            activeTab === 'home' && (
              <motion.div
                key="home"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
                transition={{ duration: 0.3 }}
              >
                {/* Greeting Section */}
                <div className="flex items-center mb-7">
                  <div className={`w-12 h-12 rounded-2xl flex items-center justify-center mr-4 ${
                    isDarkMode ? 'bg-indigo-900/70' : 'bg-indigo-100'
                  }`}>
                    <span className={`font-bold text-lg ${
                      isDarkMode ? 'text-indigo-300' : 'text-indigo-700'
                    }`}>أ</span>
                  </div>
                  <div>
                    <h2 className="text-2xl font-bold tracking-tight">مرحباً، أحمد</h2>
                    <p className="text-base opacity-90 mt-0.5">125 دواء في قاعدة البيانات</p>
                  </div>
                </div>
                
                {/* Categories Section */}
                <section className="mb-8">
                  <SectionHeader 
                    title="الفئات الطبية" 
                    actionText="عرض الكل" 
                    onAction={() => {}}
                    subtitle="اختر الفئة المناسبة لحالتك"
                  />
                  
                  <div className="grid grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4">
                    {categories.map((category) => (
                      <CategoryChip key={category.id} category={category} />
                    ))}
                  </div>
                </section>
                
                {/* Horizontal Lists */}
                <section className="mb-8">
                  <SectionHeader 
                    title="الأدوية الأكثر بحثاً" 
                    actionText="عرض الكل" 
                    onAction={() => {}}
                    subtitle="بناءً على عمليات البحث الأخيرة"
                  />
                  
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
                    {popularDrugs.map((drug) => (
                      <DrugCard key={drug.id} drug={drug} />
                    ))}
                  </div>
                </section>
                
                {/* Main Drug List */}
                <section>
                  <SectionHeader 
                    title="جميع الأدوية" 
                    subtitle="قائمة كاملة بجميع الأدوية المتاحة في قاعدة البيانات"
                  />
                  <div className="space-y-5">
                    {filteredDrugs.map((drug) => (
                      <DrugCard key={drug.id} drug={drug} detailed={true} />
                    ))}
                  </div>
                </section>
              </motion.div>
            )
          ) : (
            <DrugDetailsScreen key={`drug-${selectedDrug.id}`} />
          )}
          
          {activeTab === 'alternatives' && !selectedDrug && (
            <motion.div
              key="alternatives"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              <div className="mb-6">
                <div className="flex items-center mb-5">
                  <button 
                    onClick={() => setActiveTab('home')}
                    className={`p-1.5 rounded-full ${
                      isDarkMode ? 'hover:bg-slate-700' : 'hover:bg-slate-100'
                    } mr-2`}
                  >
                    <ChevronRight size={22} className={getTextColor()} strokeWidth={2} />
                  </button>
                  <h1 className="text-2xl font-bold">البدائل الدوائية</h1>
                </div>
                
                <div className="mb-6">
                  <div className={`${getCardBg()} ${getBorderColor()} border rounded-2xl p-4 flex items-center`}>
                    <Search size={20} className={`ml-3 ${isDarkMode ? 'text-slate-400' : 'text-slate-500'}`} strokeWidth={1.8} />
                    <input 
                      type="text" 
                      placeholder="ابحث عن دواء لعرض بدائله..." 
                      className={`w-full bg-transparent outline-none text-base ${
                        getTextColor()
                      } placeholder-${isDarkMode ? 'slate-400' : 'slate-500'}`}
                    />
                  </div>
                </div>
                
                <SectionHeader 
                  title="الأدوية الشائعة والبدائل" 
                  subtitle="اكتشف البدائل المتاحة للأدوية الأكثر استخداماً"
                />
              </div>
              
              <div className="space-y-6">
                {drugs.slice(0, 3).map((drug) => (
                  <div key={drug.id} className={`${getCardBg()} rounded-2xl overflow-hidden border ${getBorderColor()} shadow-sm`}>
                    <div className="p-5 border-b border-slate-200 dark:border-slate-700">
                      <div className="flex items-start">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-baseline">
                            <h3 className="font-bold text-xl">{drug.name}</h3>
                            {drug.oldPrice && (
                              <span className={`mr-2 px-2 py-0.5 rounded-full text-xs font-medium ${
                                isDarkMode ? 'bg-emerald-900/40 text-emerald-400' : 'bg-emerald-100 text-emerald-800'
                              }`}>
                                <TrendingUp size={12} className="inline mr-0.5" />
                                سعر منخفض
                              </span>
                            )}
                          </div>
                          <p className={`${getPrimaryColor()} font-medium text-lg mt-0.5`}>{drug.arabicName}</p>
                          <p className={`mt-1 ${getTextColor()} opacity-90`}>{drug.company}</p>
                        </div>
                        <div className="text-left mr-3 flex-shrink-0">
                          <span className="font-bold text-2xl text-emerald-600">{drug.price} ج.م</span>
                          {drug.oldPrice && (
                            <div className="mt-1 flex items-baseline">
                              <span className={`text-base ${
                                isDarkMode ? 'text-slate-400' : 'text-slate-500'
                              } line-through`}>
                                {drug.oldPrice} ج.م
                              </span>
                              <span className="text-xs bg-emerald-100 text-emerald-800 px-1.5 py-0.5 rounded-full mr-1">
                                -16%
                              </span>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                    
                    <div className="p-5">
                      <h4 className="font-bold text-lg mb-4 flex items-center">
                        <ArrowUpDown size={18} className={`${getPrimaryColor()} ml-2`} strokeWidth={1.8} />
                        أفضل البدائل المتاحة
                      </h4>
                      
                      <div className="space-y-4">
                        {alternatives.filter(a => a.id !== drug.id).slice(0, 2).map((alt) => (
                          <div key={alt.id} className={`rounded-xl p-4 border ${getBorderColor()}`}>
                            <div className="flex items-start">
                              <div className="flex-1 min-w-0">
                                <h5 className="font-bold text-lg">{alt.name}</h5>
                                <p className={`${getPrimaryColor()} text-base mt-0.5`}>{alt.arabicName}</p>
                                <p className={`mt-1 text-sm ${getTextColor()} opacity-90`}>{alt.company}</p>
                              </div>
                              <div className="text-left mr-3 flex-shrink-0">
                                <span className="font-bold text-xl text-emerald-600">{alt.price} ج.م</span>
                                <div className="mt-1">
                                  <span className={`px-2 py-0.5 rounded-full text-xs ${
                                    isDarkMode ? 'bg-indigo-900/70 text-indigo-300' : 'bg-indigo-100 text-indigo-800'
                                  }`}>
                                    {alt.category}
                                  </span>
                                </div>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                      
                      <button 
                        onClick={() => setSelectedDrug(drug)}
                        className={`mt-5 w-full ${getPrimaryColor()} font-bold py-3 rounded-xl border border-transparent hover:border ${
                          isDarkMode ? 'hover:border-indigo-700' : 'hover:border-indigo-300'
                        } transition-colors`}
                      >
                        عرض جميع البدائل <ChevronLeft size={18} className="mr-1.5" strokeWidth={2} />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </motion.div>
          )}
          
          {activeTab === 'calculator' && !selectedDrug && (
            <motion.div
              key="calculator"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              <div className="mb-6">
                <div className="flex items-center">
                  <button 
                    onClick={() => setActiveTab('home')}
                    className={`p-1.5 rounded-full ${
                      isDarkMode ? 'hover:bg-slate-700' : 'hover:bg-slate-100'
                    } mr-2`}
                  >
                    <ChevronRight size={22} className={getTextColor()} strokeWidth={2} />
                  </button>
                  <h1 className="text-2xl font-bold">حاسبة الجرعة حسب الوزن</h1>
                </div>
                <p className={`mt-2 ${getTextColor()} opacity-90`}>
                  احسب الجرعة المناسبة بناءً على وزن المريض وعمره
                </p>
              </div>
              
              <div className="space-y-5">
                <div>
                  <label className="block mb-2.5 font-medium text-base">اختر الدواء</label>
                  <div className={`${getCardBg()} ${getBorderColor()} border rounded-2xl p-4 flex items-center`}>
                    <Search size={20} className={`ml-3 ${isDarkMode ? 'text-slate-400' : 'text-slate-500'}`} strokeWidth={1.8} />
                    <input 
                      type="text" 
                      placeholder="ابحث عن دواء..." 
                      className={`w-full bg-transparent outline-none text-base ${
                        getTextColor()
                      } placeholder-${isDarkMode ? 'slate-400' : 'slate-500'}`}
                    />
                  </div>
                </div>
                
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                  <div>
                    <label className="block mb-2.5 font-medium text-base">وزن المريض (كجم)</label>
                    <div className={`${getCardBg()} ${getBorderColor()} border rounded-2xl p-4 flex items-center`}>
                      <input 
                        type="number" 
                        placeholder="70" 
                        className={`w-full bg-transparent outline-none text-xl font-bold ${
                          getTextColor()
                        }`}
                      />
                      <span className={`text-slate-500 dark:text-slate-400 mr-2`}>كجم</span>
                    </div>
                  </div>
                  
                  <div>
                    <label className="block mb-2.5 font-medium text-base">عمر المريض (سنوات)</label>
                    <div className={`${getCardBg()} ${getBorderColor()} border rounded-2xl p-4 flex items-center`}>
                      <input 
                        type="number" 
                        placeholder="35" 
                        className={`w-full bg-transparent outline-none text-xl font-bold ${
                          getTextColor()
                        }`}
                      />
                      <span className={`text-slate-500 dark:text-slate-400 mr-2`}>سنة</span>
                    </div>
                  </div>
                </div>
                
                <button className="w-full bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white font-bold py-4 rounded-2xl transition-all duration-200 shadow-lg hover:shadow-xl flex items-center justify-center">
                  <Calculator size={22} className="ml-2" strokeWidth={1.8} />
                  حساب الجرعة
                </button>
                
                <div className={`${getCardBg()} ${getBorderColor()} border rounded-2xl p-5 mt-3`}>
                  <div className="flex items-start mb-4">
                    <div className="bg-emerald-100 p-3 rounded-xl mr-4 mt-1">
                      <Check size={24} className="text-emerald-600" strokeWidth={1.8} />
                    </div>
                    <div>
                      <h3 className="font-bold text-xl">الجرعة المحسوبة</h3>
                      <p className="text-3xl font-extrabold text-emerald-600 mt-1">500 ملغ</p>
                      <p className={`mt-1 ${getTextColor()} opacity-90`}>
                        للجرعة الواحدة، يمكن تكرارها كل 4-6 ساعات
                      </p>
                    </div>
                  </div>
                  
                  <div className="mt-5 p-4 bg-amber-50 rounded-xl border border-amber-200">
                    <div className="flex items-start">
                      <AlertTriangle size={20} className="text-amber-600 mt-0.5 flex-shrink-0" strokeWidth={1.8} />
                      <p className="mr-3 text-amber-800 text-base">
                        <span className="font-bold">تحذير:</span> لا تتجاوز الجرعة اليومية القصوى 4000 ملغ. استشر طبيب متخصص قبل الاستخدام.
                      </p>
                    </div>
                  </div>
                  
                  <button className="mt-5 w-full bg-gradient-to-r from-indigo-100 to-indigo-200 dark:from-indigo-900/50 dark:to-indigo-800/50 text-indigo-800 dark:text-indigo-300 font-bold py-3.5 rounded-xl flex items-center justify-center">
                    <Star size={20} className="ml-2" strokeWidth={1.8} />
                    احفظ الحساب (ميزة Premium)
                  </button>
                </div>
                
                <div className={`${getSecondaryBg()} rounded-2xl p-5`}>
                  <h4 className="font-bold text-lg mb-3">كيف يتم حساب الجرعة؟</h4>
                  <p className={`${getTextColor()} opacity-90 leading-relaxed`}>
                    نستخدم أحدث البروتوكولات الطبية والمعايير الدولية لحساب الجرعة المناسبة لكل مريض بناءً على وزنه وعمره والحالة الطبية. يتم تحديث هذه المعايير بانتظام بالتعاون مع خبراء الصيدلة والطب.
                  </p>
                </div>
              </div>
            </motion.div>
          )}
          
          {activeTab === 'interactions' && !selectedDrug && (
            <motion.div
              key="interactions"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              <div className="mb-6">
                <div className="flex items-center">
                  <button 
                    onClick={() => setActiveTab('home')}
                    className={`p-1.5 rounded-full ${
                      isDarkMode ? 'hover:bg-slate-700' : 'hover:bg-slate-100'
                    } mr-2`}
                  >
                    <ChevronRight size={22} className={getTextColor()} strokeWidth={2} />
                  </button>
                  <h1 className="text-2xl font-bold">مدقق التفاعلات الدوائية</h1>
                </div>
                <p className={`mt-2 ${getTextColor()} opacity-90`}>
                  تحقق من التفاعلات المحتملة بين الأدوية المختلفة
                </p>
              </div>
              
              <div className="space-y-6">
                <div>
                  <label className="block mb-3 font-medium text-base">الأدوية المختارة</label>
                  <div className="flex flex-wrap gap-2 mb-5">
                    {interactionDrugs.map((drug, index) => (
                      <div 
                        key={index} 
                        className={`flex items-center px-4 py-1.5 rounded-full ${
                          isDarkMode ? 'bg-indigo-900/70 text-indigo-300' : 'bg-indigo-100 text-indigo-800'
                        }`}
                      >
                        <span className="text-base font-medium">{drug}</span>
                        <button 
                          onClick={() => setInteractionDrugs(interactionDrugs.filter((_, i) => i !== index))}
                          className="ml-2 hover:opacity-80"
                        >
                          <X size={18} strokeWidth={2} />
                        </button>
                      </div>
                    ))}
                    {interactionDrugs.length === 0 && (
                      <div className={`px-5 py-3 rounded-2xl border-2 border-dashed ${
                        getBorderColor()
                      } w-full text-center`}>
                        <span className={`opacity-70 ${getTextColor()} text-base`}>
                          لم يتم اختيار أي أدوية بعد
                        </span>
                      </div>
                    )}
                  </div>
                  
                  <button 
                    onClick={() => setInteractionDrugs([...interactionDrugs, 'بنادول'])}
                    className={`w-full border-2 border-dashed rounded-2xl py-5 ${
                      getBorderColor()
                    } flex flex-col items-center justify-center hover:bg-indigo-50/50 transition-colors`}
                  >
                    <div className={`bg-indigo-100 dark:bg-indigo-900/50 p-3.5 rounded-xl mb-2`}>
                      <Plus size={26} className={getPrimaryColor()} strokeWidth={1.8} />
                    </div>
                    <span className={`text-lg font-bold ${getTextColor()}`}>
                      إضافة دواء
                    </span>
                    <p className={`mt-1 text-sm ${isDarkMode ? 'text-slate-400' : 'text-slate-500'}`}>
                      اضغط لإضافة دواء آخر للتحقق من التفاعلات
                    </p>
                  </button>
                </div>
                
                <button className="w-full bg-gradient-to-r from-rose-600 to-amber-600 hover:from-rose-700 hover:to-amber-700 text-white font-bold py-4 rounded-2xl transition-all duration-200 shadow-lg hover:shadow-xl flex items-center justify-center">
                  <AlertTriangle size={22} className="ml-2" strokeWidth={1.8} />
                  فحص التفاعلات
                </button>
                
                <div className="mt-7">
                  <div className="flex items-center mb-5">
                    <div className="bg-rose-100 border-2 border-rose-500 text-rose-800 font-bold px-4 py-2 rounded-full text-lg flex items-center">
                      <AlertTriangle size={20} className="ml-2 text-rose-600" strokeWidth={2} />
                      تحذير خطير
                    </div>
                    <span className={`mr-4 text-lg font-medium ${getTextColor()}`}>
                      {interactionDrugs.length > 0 ? 'تم اكتشاف تفاعلات خطيرة' : 'لا توجد تفاعلات'}
                    </span>
                  </div>
                  
                  {interactionDrugs.length > 0 && (
                    <>
                      <InteractionCard 
                        severity="major" 
                        drug1="بانادول" 
                        drug2="وارفارين" 
                        effect="زيادة خطر النزيف" 
                        recommendation="تجنب الاستخدام المتزامن أو المراقبة الطبية الدقيقة"
                      />
                      <InteractionCard 
                        severity="moderate" 
                        drug1="أموكسيسيلين" 
                        drug2="الميثوتريكسات" 
                        effect="زيادة مستويات الميثوتريكسات في الدم" 
                        recommendation="المراقبة الطبية ضرورية"
                      />
                    </>
                  )}
                </div>
              </div>
            </motion.div>
          )}
          
          {activeTab === 'settings' && !selectedDrug && (
            <motion.div
              key="settings"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              <div className="mb-6">
                <div className="flex items-center">
                  <button 
                    onClick={() => setActiveTab('home')}
                    className={`p-1.5 rounded-full ${
                      isDarkMode ? 'hover:bg-slate-700' : 'hover:bg-slate-100'
                    } mr-2`}
                  >
                    <ChevronRight size={22} className={getTextColor()} strokeWidth={2} />
                  </button>
                  <h1 className="text-2xl font-bold">الإعدادات</h1>
                </div>
              </div>
              
              <div className="space-y-6">
                {/* Profile Section */}
                <div className={`${getCardBg()} rounded-2xl p-6`}>
                  <div className="flex items-center">
                    <div className={`w-16 h-16 rounded-2xl flex items-center justify-center ${
                      isDarkMode ? 'bg-indigo-900/70' : 'bg-indigo-100'
                    }`}>
                      <span className={`font-bold text-2xl ${
                        isDarkMode ? 'text-indigo-300' : 'text-indigo-700'
                      }`}>أ</span>
                    </div>
                    <div className="mr-5">
                      <h2 className="font-bold text-xl">أحمد محمد</h2>
                      <p className={`opacity-90 text-base ${getTextColor()}`}>ahmed@example.com</p>
                      <div className="mt-2 flex space-x-2 space-x-reverse">
                        <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                          isDarkMode ? 'bg-emerald-900/40 text-emerald-400' : 'bg-emerald-100 text-emerald-800'
                        }`}>
                          حساب مميز
                        </span>
                        <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                          isDarkMode ? 'bg-slate-700 text-white' : 'bg-slate-100 text-slate-800'
                        }`}>
                          منذ 2022
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                
                {/* Settings Sections */}
                <div className="space-y-3">
                  <SectionHeader title="الحساب" />
                  
                  <SettingsItem 
                    icon={<User />} 
                    title="الملف الشخصي" 
                    description="تعديل المعلومات والبيانات الشخصية"
                    onClick={() => {}}
                  />
                  <SettingsItem 
                    icon={<Bell />} 
                    title="الإشعارات" 
                    description="إدارة تنبيهات الأسعار والتحديثات"
                    onClick={() => {}}
                  />
                  <SettingsItem 
                    icon={<CreditCard />} 
                    title="الاشتراك" 
                    description="إدارة اشتراكك المميز"
                    rightIcon={<Star size={18} className="text-amber-500" strokeWidth={1.8} />}
                    onClick={() => {}}
                  />
                </div>
                
                <div className="space-y-3 mt-2">
                  <SectionHeader title="التفضيلات" />
                  
                  <SettingsItem 
                    icon={<Languages />} 
                    title="اللغة"
                    rightIcon={
                      <div className={`px-3 py-1 rounded-full text-sm font-medium ${
                        isDarkMode ? 'bg-slate-700 text-white' : 'bg-slate-100 text-slate-800'
                      }`}>
                        عربي
                      </div>
                    }
                    onClick={() => {}}
                  />
                  <SettingsItem 
                    icon={<Moon />} 
                    title="الوضع الداكن"
                    onClick={() => setIsDarkMode(!isDarkMode)}
                  >
                    <div className="mt-3 flex items-center">
                      <button 
                        onClick={(e) => {
                          e.stopPropagation();
                          setIsDarkMode(!isDarkMode);
                        }}
                        className={`w-12 h-6 rounded-full relative transition-colors ${
                          isDarkMode ? 'bg-indigo-600' : 'bg-slate-300'
                        }`}
                      >
                        <div className={`w-4 h-4 bg-white rounded-full absolute top-1 transition-transform ${
                          isDarkMode ? 'right-1 transform translate-x-0' : 'left-1 transform translate-x-0'
                        }`} />
                      </button>
                      <span className={`mr-3 text-base ${getTextColor()}`}>
                        {isDarkMode ? 'مفعل' : 'غير مفعل'}
                      </span>
                    </div>
                  </SettingsItem>
                  <SettingsItem 
                    icon={<MapPin />} 
                    title="الموقع" 
                    description="حدد موقعك للحصول على صيدليات قريبة"
                    onClick={() => {}}
                  />
                </div>
                
                <div className="space-y-3 mt-2">
                  <SectionHeader title="الأمان والدعم" />
                  
                  <SettingsItem 
                    icon={<Shield />} 
                    title="الأمان والخصوصية" 
                    description="حماية بياناتك ومعلوماتك"
                    onClick={() => {}}
                  />
                  <SettingsItem 
                    icon={<MessageCircle />} 
                    title="الدعم الفني" 
                    description="تواصل مع فريق الدعم"
                    onClick={() => {}}
                  />
                  <SettingsItem 
                    icon={<Info />} 
                    title="عن التطبيق" 
                    description="إصدار 2.1.0 • آخر تحديث: 15 نوفمبر 2023"
                    onClick={() => {}}
                  />
                </div>
                
                <button 
                  className={`w-full py-4 rounded-2xl font-bold mt-3 flex items-center justify-center ${
                    isDarkMode ? 'bg-rose-900/50 hover:bg-rose-900 text-rose-400' : 'bg-rose-50 hover:bg-rose-100 text-rose-700'
                  }`}
                >
                  <LogOut size={20} className="ml-2" strokeWidth={1.8} />
                  تسجيل الخروج
                </button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </main>
      
      {/* Bottom Navigation */}
      <nav className={`fixed bottom-0 left-0 right-0 ${getCardBg()} border-t ${getBorderColor()} py-3 px-4 shadow-lg z-50`}>
        <div className="max-w-4xl mx-auto flex justify-around items-center">
          {[
            { id: 'home', icon: <Home />, label: 'الرئيسية' },
            { id: 'alternatives', icon: <ArrowUpDown />, label: 'البدائل' },
            { id: 'calculator', icon: <Calculator />, label: 'الجرعات' },
            { id: 'interactions', icon: <AlertCircle />, label: 'التفاعلات' },
            { id: 'settings', icon: <Settings />, label: 'الإعدادات' },
          ].map((item) => (
            <button
              key={item.id}
              onClick={() => {
                setActiveTab(item.id);
                setSelectedDrug(null);
                setActiveDrugTab('info');
                window.scrollTo(0, 0);
              }}
              className={`flex flex-col items-center p-2 rounded-xl transition-all duration-200 ${
                activeTab === item.id
                  ? 'text-indigo-600 dark:text-indigo-400 scale-105'
                  : `${getTextColor()} opacity-70 hover:opacity-100`
              }`}
            >
              <div className={`p-2.5 rounded-xl mb-1 ${
                activeTab === item.id
                  ? 'bg-indigo-100 dark:bg-indigo-900/50'
                  : 'bg-transparent'
              }`}>
                {React.cloneElement(item.icon, { 
                  size: 24,
                  strokeWidth: 1.8,
                  className: activeTab === item.id 
                    ? 'text-indigo-600 dark:text-indigo-400'
                    : `${getTextColor()} opacity-70`
                })}
              </div>
              <span className="text-xs font-medium whitespace-nowrap">{item.label}</span>
            </button>
          ))}
        </div>
      </nav>
      
      {/* Filter Bottom Sheet */}
      {showFilters && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="fixed inset-0 bg-black/40 z-50 flex items-end"
          onClick={() => setShowFilters(false)}
        >
          <motion.div
            initial={{ y: "100%" }}
            animate={{ y: 0 }}
            className={`${getCardBg()} rounded-t-3xl h-5/6 overflow-y-auto`}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="p-5 border-b border-slate-200 dark:border-slate-700 flex justify-between items-center">
              <h2 className="text-xl font-bold">خيارات الفلترة المتقدمة</h2>
              <button onClick={() => setShowFilters(false)}>
                <X size={24} className={getTextColor()} strokeWidth={1.8} />
              </button>
            </div>
            
            <div className="p-5 space-y-7">
              <div>
                <h3 className="font-bold text-lg mb-4 flex items-center">
                  <Tag size={18} className={`${getPrimaryColor()} ml-2`} strokeWidth={1.8} />
                  الفئات
                </h3>
                <div className="flex flex-wrap gap-2">
                  {categories.map((category) => (
                    <button 
                      key={category.id}
                      className={`px-4 py-2 rounded-xl text-sm font-medium transition-all duration-200 ${
                        isDarkMode 
                          ? 'bg-slate-800 hover:bg-slate-700' 
                          : 'bg-slate-100 hover:bg-slate-200'
                      }`}
                    >
                      {category.name}
                    </button>
                  ))}
                </div>
              </div>
              
              <div>
                <h3 className="font-bold text-lg mb-4 flex items-center">
                  <Percent size={18} className={`${getPrimaryColor()} ml-2`} strokeWidth={1.8} />
                  نطاق السعر
                </h3>
                <div className="space-y-5">
                  <div>
                    <div className="flex justify-between text-sm mb-3">
                      <span>0 ج.م</span>
                      <span>200+ ج.م</span>
                    </div>
                    <div className="h-3 bg-slate-200 dark:bg-slate-700 rounded-xl overflow-hidden">
                      <div className="h-full bg-indigo-600 rounded-xl w-2/3"></div>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm mb-1.5">الحد الأدنى</label>
                      <div className={`${getCardBg()} ${getBorderColor()} border rounded-xl p-3 flex items-center`}>
                        <input 
                          type="number" 
                          placeholder="0" 
                          className={`w-full bg-transparent outline-none text-base ${
                            getTextColor()
                          }`}
                        />
                        <span className={`text-slate-500 dark:text-slate-400 mr-2`}>ج.م</span>
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm mb-1.5">الحد الأقصى</label>
                      <div className={`${getCardBg()} ${getBorderColor()} border rounded-xl p-3 flex items-center`}>
                        <input 
                          type="number" 
                          placeholder="200" 
                          className={`w-full bg-transparent outline-none text-base ${
                            getTextColor()
                          }`}
                        />
                        <span className={`text-slate-500 dark:text-slate-400 mr-2`}>ج.م</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              
              <div>
                <h3 className="font-bold text-lg mb-4 flex items-center">
                  <Building2 size={18} className={`${getPrimaryColor()} ml-2`} strokeWidth={1.8} />
                  الشركات
                </h3>
                <div className="space-y-2">
                  {[...new Set(drugs.map(d => d.company))].slice(0, 4).map((company, index) => (
                    <label key={index} className="flex items-center p-3 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                      <input 
                        type="checkbox" 
                        className="w-4 h-4 text-indigo-600 dark:text-indigo-400 rounded border-slate-300 dark:border-slate-600"
                      />
                      <span className={`mr-3 text-base ${getTextColor()}`}>{company}</span>
                    </label>
                  ))}
                </div>
              </div>
              
              <div className="pt-4 border-t border-slate-200 dark:border-slate-700">
                <div className="grid grid-cols-2 gap-4">
                  <button 
                    onClick={() => setShowFilters(false)}
                    className={`py-3.5 rounded-xl font-bold text-base ${
                      isDarkMode ? 'bg-slate-800 hover:bg-slate-700' : 'bg-slate-200 hover:bg-slate-300'
                    }`}
                  >
                    إعادة تعيين
                  </button>
                  <button 
                    onClick={() => setShowFilters(false)}
                    className="py-3.5 bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white font-bold rounded-xl text-base shadow-lg hover:shadow-xl transition-all duration-200"
                  >
                    تطبيق الفلاتر
                  </button>
                </div>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
      
      {/* Loading Overlay */}
      {isLoading && (
        <div className="fixed inset-0 bg-black/30 backdrop-blur-sm z-50 flex items-center justify-center">
          <div className="bg-white dark:bg-slate-800 rounded-2xl p-6 shadow-2xl">
            <Loader2 size={32} className="text-indigo-600 animate-spin" />
            <p className="mt-3 text-lg font-medium">جاري التحميل...</p>
          </div>
        </div>
      )}
    </div>
  );
};

export default App;
```