import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Data Sources
import '../../data/datasources/local/csv_local_data_source.dart';
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
  // --- External Dependencies ---
  // Register SharedPreferences as a singleton Future
  locator.registerSingletonAsync<SharedPreferences>(() async {
    return await SharedPreferences.getInstance();
  });
  // Register http Client as a factory (or singleton if preferred)
  locator.registerLazySingleton<http.Client>(() => http.Client());

  // --- Data Sources ---
  // Wait for SharedPreferences to be ready before registering dependent sources
  await locator.isReady<SharedPreferences>();

  locator.registerLazySingleton<DrugRemoteDataSource>(() {
    const backendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://localhost:8000', // Default for local development
    );
    return DrugRemoteDataSourceImpl(
      baseUrl: backendUrl,
      client: locator<http.Client>(),
    );
  }); // End of DrugRemoteDataSource registration

  // Register ConfigRemoteDataSource separately
  locator.registerLazySingleton<ConfigRemoteDataSource>(() {
    const backendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://localhost:8000', // Default for local development
    );
    return ConfigRemoteDataSourceImpl(
      client: locator<http.Client>(),
      baseUrl: backendUrl,
    );
  });
  // CsvLocalDataSource is a singleton itself, accessed via factory constructor
  locator.registerLazySingleton<CsvLocalDataSource>(() => CsvLocalDataSource());
  locator.registerLazySingleton<InteractionLocalDataSource>(
    () => InteractionLocalDataSourceImpl(), // Assuming it loads from assets
  );
  locator.registerLazySingleton<AnalyticsRemoteDataSource>(() {
    const backendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://localhost:8000',
    );
    return AnalyticsRemoteDataSourceImpl(
      client: locator<http.Client>(),
      baseUrl: backendUrl,
      // authTokenProvider: locator<AuthTokenProvider>(), // Add if auth is needed
    );
  });

  // --- Repositories ---
  locator.registerLazySingleton<DrugRepository>(
    () => DrugRepositoryImpl(
      remoteDataSource: locator<DrugRemoteDataSource>(),
      localDataSource: locator<CsvLocalDataSource>(),
      // No SharedPreferences needed here, it's internal to CsvLocalDataSource
    ),
  );
  locator.registerLazySingleton<ConfigRepository>(
    () => ConfigRepositoryImpl(
      remoteDataSource: locator<ConfigRemoteDataSource>(),
    ),
  );
  locator.registerLazySingleton<InteractionRepository>(
    // InteractionRepositoryImpl loads data internally, no datasource needed in constructor
    () => InteractionRepositoryImpl(),
  );
  locator.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(
      remoteDataSource: locator<AnalyticsRemoteDataSource>(),
    ),
  );

  // --- Use Cases ---
  locator.registerLazySingleton(() => GetAllDrugs(locator<DrugRepository>()));
  locator.registerLazySingleton(
    () => SearchDrugsUseCase(locator<DrugRepository>()),
  ); // Corrected Name
  locator.registerLazySingleton(
    () => FilterDrugsByCategoryUseCase(
      locator<DrugRepository>(),
    ), // Corrected Name
  );
  locator.registerLazySingleton(
    () => GetAvailableCategoriesUseCase(
      locator<DrugRepository>(),
    ), // Corrected Name
  );
  locator.registerLazySingleton(
    () => FindDrugAlternativesUseCase(
      locator<DrugRepository>(),
    ), // Corrected Name
  );
  locator.registerLazySingleton(
    () => LoadInteractionData(locator<InteractionRepository>()),
  );
  locator.registerLazySingleton(
    // Register GetLastUpdateTimestampUseCase
    () => GetLastUpdateTimestampUseCase(locator<DrugRepository>()),
  );
  locator.registerLazySingleton(
    () => GetAdMobConfig(locator<ConfigRepository>()),
  );
  locator.registerLazySingleton(
    () => GetGeneralConfig(locator<ConfigRepository>()),
  );
  locator.registerLazySingleton(
    () => GetAnalyticsSummary(locator<AnalyticsRepository>()),
  ); // Register Analytics Use Case

  // --- Services ---
  locator.registerLazySingleton(() => DosageCalculatorService());
  locator.registerLazySingleton(() => InteractionCheckerService());
  locator.registerLazySingleton<AnalyticsService>(() {
    // Define baseUrl consistently
    const backendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://localhost:8000', // Default for local development
    );
    return AnalyticsServiceImpl(
      client: locator<http.Client>(),
      baseUrl: backendUrl,
    );
  }); // Close the registration closure
  // --- Providers / Blocs ---
  // Register providers as Factories because they hold state specific to where they are used.
  // They will depend on UseCases or Repositories.
  locator.registerFactory(
    () => MedicineProvider(
      getAllDrugsUseCase: locator<GetAllDrugs>(),
      searchDrugsUseCase: locator<SearchDrugsUseCase>(), // Corrected Name
      filterDrugsByCategoryUseCase:
          locator<FilterDrugsByCategoryUseCase>(), // Corrected Name
      getAvailableCategoriesUseCase:
          locator<GetAvailableCategoriesUseCase>(), // Corrected Name
      getLastUpdateTimestampUseCase: locator<GetLastUpdateTimestampUseCase>(),
      getAnalyticsSummaryUseCase:
          locator<GetAnalyticsSummary>(), // Added analytics use case
    ),
  );
  locator.registerFactory(
    () => AlternativesProvider(
      findDrugAlternativesUseCase:
          locator<FindDrugAlternativesUseCase>(), // Corrected Name
    ),
  );
  locator.registerFactory(
    () => DoseCalculatorProvider(
      dosageCalculatorService: locator<DosageCalculatorService>(),
    ),
  );
  locator.registerFactory(
    () => InteractionProvider(
      // Pass the repository and service instances from the locator
      interactionRepository: locator<InteractionRepository>(),
      interactionCheckerService: locator<InteractionCheckerService>(),
      // loadInteractionDataUseCase is not needed in constructor
    ),
  );
  locator.registerFactory(
    // SettingsProvider gets SharedPreferences internally
    () => SettingsProvider(),
  );
  // Register SubscriptionProvider as a Singleton since it manages background listeners
  locator.registerLazySingleton(() => SubscriptionProvider());

  // Ensure all asynchronous singletons are ready
  // await locator.allReady(); // Not strictly necessary if using isReady<SharedPreferences> above

  print("Service locator setup complete."); // Add a log to confirm setup
}
