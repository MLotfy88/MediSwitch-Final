import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart'; // Import dartz for Either, Right, unit
import '../error/failures.dart'; // Import Failure base class
import '../../core/usecases/usecase.dart'; // Import NoParams if needed by use cases

// Database Helper
import '../database/database_helper.dart'; // Import DatabaseHelper

// Data Sources
// import '../../data/datasources/local/csv_local_data_source.dart'; // Removed CSV
import '../../data/datasources/local/sqlite_local_data_source.dart'; // Import SQLite
import '../../data/datasources/remote/drug_remote_data_source.dart';
import '../../data/datasources/local/interaction_local_data_source.dart';
import '../../data/datasources/remote/config_remote_data_source.dart'; // Import Config Remote DS
import '../../data/datasources/remote/analytics_remote_data_source.dart'; // Import Analytics Remote DS
// Repositories
import '../../data/repositories/drug_repository_impl.dart';
import '../../data/repositories/interaction_repository_impl.dart';
import '../../domain/repositories/drug_repository.dart';
import '../../domain/repositories/interaction_repository.dart';
import '../../domain/repositories/config_repository.dart'; // Import Config Repo
import '../../data/repositories/config_repository_impl.dart'; // Import Config Repo Impl
import '../../domain/repositories/analytics_repository.dart'; // Import Analytics Repo
import '../../data/repositories/analytics_repository_impl.dart'; // Import Analytics Repo Impl
// Use Cases
import '../../domain/usecases/get_all_drugs.dart';
import '../../domain/usecases/search_drugs.dart';
import '../../domain/usecases/filter_drugs_by_category.dart';
import '../../domain/usecases/get_available_categories.dart';
import '../../domain/usecases/find_drug_alternatives.dart';
import '../../domain/usecases/load_interaction_data.dart';
import '../../domain/usecases/get_admob_config.dart'; // Import Config Use Cases
import '../../domain/usecases/get_general_config.dart';
import '../../domain/usecases/get_last_update_timestamp.dart'; // Import GetLastUpdateTimestampUseCase
import '../../domain/usecases/get_analytics_summary.dart'; // Import Analytics Use Case
// Services
import '../../domain/services/dosage_calculator_service.dart';
import '../../domain/services/interaction_checker_service.dart';
import '../../domain/services/analytics_service.dart'; // Import Analytics Service interface
import '../../data/services/analytics_service_impl.dart'; // Import Analytics Service impl
import '../../presentation/services/ad_service.dart'; // Import AdService
// Providers / Blocs
import '../../presentation/bloc/medicine_provider.dart';
import '../../presentation/bloc/alternatives_provider.dart';
import '../../presentation/bloc/dose_calculator_provider.dart';
import '../../presentation/bloc/interaction_provider.dart';
import '../../presentation/bloc/settings_provider.dart';
import '../../presentation/bloc/subscription_provider.dart'; // Import Subscription Provider

// Global Service Locator instance
final locator = GetIt.instance;

Future<void> setupLocator() async {
  print("--- Starting Full Locator Setup ---");
  // --- External Dependencies ---
  locator.registerSingletonAsync<SharedPreferences>(() async {
    print("Registering SharedPreferences...");
    final prefs = await SharedPreferences.getInstance();
    print("SharedPreferences registered.");
    return prefs;
  });
  locator.registerLazySingleton<http.Client>(() {
    print("Registering http.Client.");
    return http.Client();
  });

  // --- Core ---
  // Register DatabaseHelper as a singleton and wait for it
  locator.registerSingletonAsync<DatabaseHelper>(() async {
    print("Registering DatabaseHelper...");
    final helper = DatabaseHelper();
    await helper.database; // Initialize DB
    print("DatabaseHelper registered and DB initialized.");
    return helper;
  });

  // --- Data Sources ---
  // Wait for SharedPreferences AND DatabaseHelper to be ready
  print("Waiting for SharedPreferences and DatabaseHelper...");
  await Future.wait([
    locator.isReady<SharedPreferences>(),
    locator.isReady<DatabaseHelper>(),
  ]);
  print("SharedPreferences and DatabaseHelper ready.");

  // Register Data Sources
  locator.registerLazySingleton<DrugRemoteDataSource>(() {
    print("Registering DrugRemoteDataSource...");
    const backendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://localhost:8000',
    );
    return DrugRemoteDataSourceImpl(
      baseUrl: backendUrl,
      client: locator<http.Client>(),
    );
  });
  locator.registerLazySingleton<SqliteLocalDataSource>(() {
    print("Registering SqliteLocalDataSource...");
    return SqliteLocalDataSource(dbHelper: locator<DatabaseHelper>());
  });
  locator.registerLazySingleton<InteractionLocalDataSource>(() {
    print("Registering InteractionLocalDataSource...");
    return InteractionLocalDataSourceImpl();
  });
  locator.registerLazySingleton<ConfigRemoteDataSource>(() {
    print("Registering ConfigRemoteDataSource...");
    const backendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://localhost:8000',
    );
    return ConfigRemoteDataSourceImpl(
      client: locator<http.Client>(),
      baseUrl: backendUrl,
    );
  });
  locator.registerLazySingleton<AnalyticsRemoteDataSource>(() {
    print("Registering AnalyticsRemoteDataSource...");
    const backendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://localhost:8000',
    );
    return AnalyticsRemoteDataSourceImpl(
      client: locator<http.Client>(),
      baseUrl: backendUrl,
    );
  });

  // --- Repositories ---
  locator.registerLazySingleton<DrugRepository>(() {
    print("Registering DrugRepository...");
    return DrugRepositoryImpl(
      remoteDataSource: locator<DrugRemoteDataSource>(),
      localDataSource: locator<SqliteLocalDataSource>(),
      // isConnected: true, // Let it determine connectivity internally if needed
    );
  });
  locator.registerLazySingleton<InteractionRepository>(() {
    print("Registering InteractionRepository...");
    return InteractionRepositoryImpl(); // Loads data internally
  });
  locator.registerLazySingleton<ConfigRepository>(() {
    print("Registering ConfigRepository...");
    return ConfigRepositoryImpl(
      remoteDataSource: locator<ConfigRemoteDataSource>(),
    );
  });
  locator.registerLazySingleton<AnalyticsRepository>(() {
    print("Registering AnalyticsRepository...");
    return AnalyticsRepositoryImpl(
      remoteDataSource: locator<AnalyticsRemoteDataSource>(),
    );
  });

  // --- Use Cases ---
  print("Registering Use Cases...");
  locator.registerLazySingleton(() => GetAllDrugs(locator<DrugRepository>()));
  locator.registerLazySingleton(
    () => SearchDrugsUseCase(locator<DrugRepository>()),
  );
  locator.registerLazySingleton(
    () => FilterDrugsByCategoryUseCase(locator<DrugRepository>()),
  );
  locator.registerLazySingleton(
    () => GetAvailableCategoriesUseCase(locator<DrugRepository>()),
  );
  locator.registerLazySingleton(
    () => GetLastUpdateTimestampUseCase(locator<DrugRepository>()),
  );
  locator.registerLazySingleton(
    () => FindDrugAlternativesUseCase(locator<DrugRepository>()),
  );
  locator.registerLazySingleton(
    () => LoadInteractionData(locator<InteractionRepository>()),
  );
  locator.registerLazySingleton(
    () => GetAdMobConfig(locator<ConfigRepository>()),
  );
  locator.registerLazySingleton(
    () => GetGeneralConfig(locator<ConfigRepository>()),
  );
  locator.registerLazySingleton(
    () => GetAnalyticsSummary(locator<AnalyticsRepository>()),
  );

  // --- Services ---
  print("Registering Services...");
  locator.registerLazySingleton(() => DosageCalculatorService());
  locator.registerLazySingleton(() => InteractionCheckerService());
  locator.registerLazySingleton(() => AdService());
  locator.registerLazySingleton<AnalyticsService>(() {
    const backendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://localhost:8000',
    );
    return AnalyticsServiceImpl(
      client: locator<http.Client>(),
      baseUrl: backendUrl,
    );
  });

  // --- Providers / Blocs ---
  print("Registering Providers...");
  locator.registerFactory(
    () => MedicineProvider(
      getAllDrugsUseCase: locator<GetAllDrugs>(),
      searchDrugsUseCase: locator<SearchDrugsUseCase>(),
      filterDrugsByCategoryUseCase: locator<FilterDrugsByCategoryUseCase>(),
      getAvailableCategoriesUseCase: locator<GetAvailableCategoriesUseCase>(),
      getLastUpdateTimestampUseCase: locator<GetLastUpdateTimestampUseCase>(),
      getAnalyticsSummaryUseCase:
          locator<GetAnalyticsSummary>(), // Use actual analytics
    ),
  );
  locator.registerFactory(
    () => AlternativesProvider(
      findDrugAlternativesUseCase: locator<FindDrugAlternativesUseCase>(),
    ),
  );
  locator.registerFactory(
    () => DoseCalculatorProvider(
      dosageCalculatorService: locator<DosageCalculatorService>(),
    ),
  );
  locator.registerFactory(
    () => InteractionProvider(
      interactionRepository: locator<InteractionRepository>(),
      interactionCheckerService: locator<InteractionCheckerService>(),
    ),
  );
  locator.registerFactory(() => SettingsProvider());
  locator.registerLazySingleton(() => SubscriptionProvider());

  // Ensure all asynchronous singletons are ready before proceeding
  print("Waiting for all async singletons...");
  await locator.allReady();
  print("--- Full Locator Setup Complete ---");
}

// Dummy implementation is no longer needed as AnalyticsRepository is registered
// class DummyAnalyticsRepository implements AnalyticsRepository { ... }
