import React, { useState } from 'react';
import MobileFrame from '@/components/MobileFrame';
import BottomNav from '@/components/layout/BottomNav';
import HomeScreen from '@/components/screens/HomeScreen';
import HomeScreenAr from '@/components/screens/HomeScreenAr';
import SearchResultsScreen from '@/components/screens/SearchResultsScreen';
import DrugDetailsScreen from '@/components/screens/DrugDetailsScreen';
import FavoritesScreen from '@/components/screens/FavoritesScreen';
import HistoryScreen from '@/components/screens/HistoryScreen';
import ProfileScreen from '@/components/screens/ProfileScreen';
import SettingsScreen from '@/components/screens/SettingsScreen';
import InteractionsScreen from '@/components/screens/InteractionsScreen';
import DoseCalculatorScreen from '@/components/screens/DoseCalculatorScreen';
import ThemeToggle from '@/components/layout/ThemeToggle';
import { ThemeProvider, useTheme } from '@/hooks/useTheme';

type Screen = 'home' | 'search' | 'drugDetails' | 'favorites' | 'history' | 'profile' | 'settings' | 'interactions' | 'doseCalculator';

const AppContent = () => {
  const [currentScreen, setCurrentScreen] = useState<Screen>('home');
  const [activeTab, setActiveTab] = useState('home');
  const [selectedDrugId, setSelectedDrugId] = useState<string | null>(null);
  const { language } = useTheme();

  const handleDrugClick = (id: string) => {
    setSelectedDrugId(id);
    setCurrentScreen('drugDetails');
  };

  const handleSearch = (query: string) => {
    if (query.length > 2) {
      setCurrentScreen('search');
    }
  };

  const handleBack = () => {
    if (currentScreen === 'drugDetails') {
      setCurrentScreen('search');
    } else {
      setCurrentScreen('home');
    }
  };

  const handleTabChange = (tab: string) => {
    setActiveTab(tab);
    if (tab === 'home') {
      setCurrentScreen('home');
    } else if (tab === 'search') {
      setCurrentScreen('search');
    } else if (tab === 'favorites') {
      setCurrentScreen('favorites');
    } else if (tab === 'history') {
      setCurrentScreen('history');
    } else if (tab === 'profile') {
      setCurrentScreen('profile');
    }
  };

  return (
    <>
      <ThemeToggle />
      <MobileFrame>
        {currentScreen === 'home' && (
          language === 'ar' ? (
            <HomeScreenAr 
              onDrugClick={handleDrugClick}
              onSearch={handleSearch}
              onInteractionsClick={() => setCurrentScreen('interactions')}
              onDoseCalculatorClick={() => setCurrentScreen('doseCalculator')}
            />
          ) : (
            <HomeScreen 
              onDrugClick={handleDrugClick}
              onSearch={handleSearch}
              onInteractionsClick={() => setCurrentScreen('interactions')}
              onDoseCalculatorClick={() => setCurrentScreen('doseCalculator')}
            />
          )
        )}
        
        {currentScreen === 'search' && (
          <SearchResultsScreen 
            onBack={handleBack}
            onDrugClick={handleDrugClick}
          />
        )}
        
        {currentScreen === 'drugDetails' && (
          <DrugDetailsScreen onBack={handleBack} />
        )}

        {currentScreen === 'favorites' && (
          <FavoritesScreen onDrugClick={handleDrugClick} />
        )}

        {currentScreen === 'history' && (
          <HistoryScreen onDrugClick={handleDrugClick} />
        )}

        {currentScreen === 'profile' && (
          <ProfileScreen onSettingsClick={() => setCurrentScreen('settings')} />
        )}

        {currentScreen === 'settings' && (
          <SettingsScreen onBack={() => setCurrentScreen('profile')} />
        )}

        {currentScreen === 'interactions' && (
          <InteractionsScreen onBack={() => setCurrentScreen('home')} />
        )}

        {currentScreen === 'doseCalculator' && (
          <DoseCalculatorScreen onBack={() => setCurrentScreen('home')} />
        )}
        
        <BottomNav
          activeTab={activeTab} 
          onTabChange={handleTabChange} 
        />
      </MobileFrame>
    </>
  );
};

const Index = () => {
  return (
    <ThemeProvider>
      <AppContent />
    </ThemeProvider>
  );
};

export default Index;
