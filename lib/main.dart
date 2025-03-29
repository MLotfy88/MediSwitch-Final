import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import necessary components for manual DI
import 'data/datasources/local/csv_local_data_source.dart';
import 'data/datasources/remote/drug_remote_data_source.dart';
import 'data/repositories/drug_repository_impl.dart';
import 'domain/repositories/drug_repository.dart';
import 'domain/usecases/get_all_drugs.dart';
import 'domain/usecases/search_drugs.dart';
import 'domain/usecases/filter_drugs_by_category.dart';
import 'domain/usecases/get_available_categories.dart';
import 'domain/usecases/find_drug_alternatives.dart';
import 'presentation/bloc/medicine_provider.dart';
import 'presentation/bloc/settings_provider.dart'; // Import SettingsProvider
import 'presentation/screens/main_screen.dart';

void main() {
  // Manual Dependency Injection Setup (Temporary)
  // 1. Data Sources
  final CsvLocalDataSource csvLocalDataSource = CsvLocalDataSource();
  final DrugRemoteDataSource drugRemoteDataSource =
      DrugRemoteDataSourceImpl.create();
  // 2. Repository
  final DrugRepository drugRepository = DrugRepositoryImpl(
    localDataSource: csvLocalDataSource,
    remoteDataSource: drugRemoteDataSource, // Pass the remote data source
  );
  // 3. Use Cases
  final GetAllDrugs getAllDrugsUseCase = GetAllDrugs(drugRepository);
  final SearchDrugsUseCase searchDrugsUseCase = SearchDrugsUseCase(
    drugRepository,
  );
  final FilterDrugsByCategoryUseCase filterDrugsByCategoryUseCase =
      FilterDrugsByCategoryUseCase(drugRepository);
  final GetAvailableCategoriesUseCase getAvailableCategoriesUseCase =
      GetAvailableCategoriesUseCase(drugRepository);
  final FindDrugAlternativesUseCase findDrugAlternativesUseCase =
      FindDrugAlternativesUseCase(drugRepository);

  runApp(
    // Pass all required use cases to MyApp
    MyApp(
      getAllDrugsUseCase: getAllDrugsUseCase,
      searchDrugsUseCase: searchDrugsUseCase,
      filterDrugsByCategoryUseCase: filterDrugsByCategoryUseCase,
      getAvailableCategoriesUseCase: getAvailableCategoriesUseCase,
      findDrugAlternativesUseCase: findDrugAlternativesUseCase,
    ),
  );
}

class MyApp extends StatelessWidget {
  // Accept all required use cases
  final GetAllDrugs getAllDrugsUseCase;
  final SearchDrugsUseCase searchDrugsUseCase;
  final FilterDrugsByCategoryUseCase filterDrugsByCategoryUseCase;
  final GetAvailableCategoriesUseCase getAvailableCategoriesUseCase;
  final FindDrugAlternativesUseCase
  findDrugAlternativesUseCase; // Add the new use case

  const MyApp({
    super.key,
    required this.getAllDrugsUseCase,
    required this.searchDrugsUseCase,
    required this.filterDrugsByCategoryUseCase,
    required this.getAvailableCategoriesUseCase,
    required this.findDrugAlternativesUseCase, // Require the new use case
  });

  @override
  Widget build(BuildContext context) {
    // Wrap with MultiProvider to provide multiple providers
    return MultiProvider(
      providers: [
        // Provide MedicineProvider
        ChangeNotifierProvider(
          create:
              (_) => MedicineProvider(
                getAllDrugsUseCase: getAllDrugsUseCase,
                searchDrugsUseCase: searchDrugsUseCase,
                filterDrugsByCategoryUseCase: filterDrugsByCategoryUseCase,
                getAvailableCategoriesUseCase: getAvailableCategoriesUseCase,
              ),
        ),
        // Provide SettingsProvider
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        // Note: DoseCalculatorProvider and AlternativesProvider are provided
        // locally in main_screen.dart and home_screen.dart respectively,
        // which is fine for now, but could be moved here for global access if needed.
      ],
      // Consumer is needed here to access SettingsProvider for theme/locale
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          // Show loading indicator until settings are loaded
          if (!settingsProvider.isInitialized) {
            // Return a simple loading screen
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          // Build the app once settings are loaded
          return MaterialApp(
            title: 'MediSwitch',
            debugShowCheckedModeBanner: false,
            themeMode:
                settingsProvider.themeMode, // Use themeMode from provider
            theme: ThemeData(
              // Define light theme
              // Use colorSchemeSeed for easier Material 3 theming
              colorSchemeSeed: Colors.blue,
              brightness: Brightness.light,
              fontFamily: 'Arial', // Consider Noto Sans Arabic
              useMaterial3: true,
              // Add other light theme customizations if needed
            ),
            darkTheme: ThemeData(
              // Define dark theme
              colorSchemeSeed: Colors.blue,
              brightness: Brightness.dark, // Set brightness to dark
              fontFamily: 'Arial', // Consider Noto Sans Arabic
              useMaterial3: true,
              // Add other dark theme customizations if needed
            ),
            locale: settingsProvider.locale, // Use locale from provider
            // TODO: Add localization delegates and supported locales
            // localizationsDelegates: [ ... ],
            // supportedLocales: [ const Locale('en'), const Locale('ar'), ],
            home: const MainScreen(), // Ensure MainScreen is correctly imported
          );
        },
      ),
    );
  }
}
