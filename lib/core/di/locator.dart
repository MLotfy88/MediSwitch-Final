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
import '../../data/datasources/local/interaction_local_data_source.dart'; // Keep disabled for now
import '../../data/datasources/remote/config_remote_data_source.dart'; // Keep disabled
import '../../data/datasources/remote/analytics_remote_data_source.dart'; // Keep disabled
// Repositories
import '../../data/repositories/drug_repository_impl.dart';
import '../../data/repositories/interaction_repository_impl.dart'; // Keep disabled
import '../../domain/repositories/drug_repository.dart';
import '../../domain/repositories/interaction_repository.dart'; // Keep disabled
import '../../domain/repositories/config_repository.dart'; // Keep disabled
import '../../data/repositories/config_repository_impl.dart'; // Keep disabled
import '../../domain/repositories/analytics_repository.dart'; // Keep disabled
import '../../data/repositories/analytics_repository_impl.dart'; // Keep disabled
// Use Cases
import '../../domain/usecases/get_all_drugs.dart';
import '../../domain/usecases/search_drugs.dart';
import '../../domain/usecases/filter_drugs_by_category.dart';
import '../../domain/usecases/get_available_categories.dart';
import '../../domain/usecases/find_drug_alternatives.dart'; // Keep disabled
import '../../domain/usecases/load_interaction_data.dart'; // Keep disabled
import '../../domain/usecases/get_admob_config.dart'; // Keep disabled
import '../../domain/usecases/get_general_config.dart'; // Keep disabled
import '../../domain/usecases/get_last_update_timestamp.dart';
import '../../domain/usecases/get_analytics_summary.dart'; // Keep disabled
// Services
import '../../domain/services/dosage_calculator_service.dart'; // Keep disabled
import '../../domain/services/interaction_checker_service.dart'; // Keep disabled
import '../../domain/services/analytics_service.dart'; // Keep disabled
import '../../data/services/analytics_service_impl.dart'; // Keep disabled
import '../../presentation/services/ad_service.dart'; // Keep disabled
// Providers / Blocs
import '../../presentation/bloc/medicine_provider.dart';
import '../../presentation/bloc/alternatives_provider.dart'; // Keep disabled
import '../../presentation/bloc/dose_calculator_provider.dart'; // Keep disabled
import '../../presentation/bloc/interaction_provider.dart'; // Keep disabled
import '../../presentation/bloc/settings_provider.dart';
import '../../presentation/bloc/subscription_provider.dart'; // Keep disabled

// Global Service Locator instance
final locator = GetIt.instance;

Future<void> setupLocator() async {
  // --- External Dependencies ---
  locator.registerSingletonAsync<SharedPreferences>(() async {
    return await SharedPreferences.getInstance();
  });
  locator.registerLazySingleton<http.Client>(() => http.Client());

  // --- Core ---
  // Re-enable DB Helper registration
  locator.registerSingletonAsync<DatabaseHelper>(() async {
    final helper = DatabaseHelper();
    await helper.database; // Initialize DB
    return helper;
  });

  // --- Data Sources ---
  // Wait for SharedPreferences AND DatabaseHelper to be ready
  await Future.wait([
    locator.isReady<SharedPreferences>(),
    locator.isReady<DatabaseHelper>(),
  ]);

  // Re-enable necessary Data Sources
  locator.registerLazySingleton<DrugRemoteDataSource>(() {
    const backendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://localhost:8000',
    );
    return DrugRemoteDataSourceImpl(
      baseUrl: backendUrl,
      client: locator<http.Client>(),
    );
  });
  locator.registerLazySingleton<SqliteLocalDataSource>(
    () => SqliteLocalDataSource(dbHelper: locator<DatabaseHelper>()),
  );
  // Keep others disabled
  // locator.registerLazySingleton<InteractionLocalDataSource>(() => InteractionLocalDataSourceImpl());
  // locator.registerLazySingleton<ConfigRemoteDataSource>(() => ...);
  // locator.registerLazySingleton<AnalyticsRemoteDataSource>(() => ...);

  // --- Repositories ---
  // Re-enable necessary Repositories
  locator.registerLazySingleton<DrugRepository>(
    () => DrugRepositoryImpl(
      remoteDataSource: locator<DrugRemoteDataSource>(),
      localDataSource: locator<SqliteLocalDataSource>(),
      // isConnected: true, // Keep update check disabled for now
    ),
  );
  // Keep others disabled
  // locator.registerLazySingleton<InteractionRepository>(() => InteractionRepositoryImpl());
  // locator.registerLazySingleton<ConfigRepository>(() => ...);
  // locator.registerLazySingleton<AnalyticsRepository>(() => ...);

  // --- Use Cases ---
  // Re-enable necessary Use Cases
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
  // Keep others disabled
  // locator.registerLazySingleton(() => FindDrugAlternativesUseCase(locator<DrugRepository>()));
  // locator.registerLazySingleton(() => LoadInteractionData(locator<InteractionRepository>()));
  // locator.registerLazySingleton(() => GetAdMobConfig(locator<ConfigRepository>()));
  // locator.registerLazySingleton(() => GetGeneralConfig(locator<ConfigRepository>()));
  // locator.registerLazySingleton(() => GetAnalyticsSummary(locator<AnalyticsRepository>()));

  // --- Services ---
  // Keep disabled for now
  // locator.registerLazySingleton(() => DosageCalculatorService());
  // locator.registerLazySingleton(() => InteractionCheckerService());
  // locator.registerLazySingleton(() => AdService());
  // locator.registerLazySingleton<AnalyticsService>(() { ... });

  // --- Providers / Blocs ---
  // Re-enable MedicineProvider
  locator.registerFactory(
    () => MedicineProvider(
      getAllDrugsUseCase: locator<GetAllDrugs>(),
      searchDrugsUseCase: locator<SearchDrugsUseCase>(),
      filterDrugsByCategoryUseCase: locator<FilterDrugsByCategoryUseCase>(),
      getAvailableCategoriesUseCase: locator<GetAvailableCategoriesUseCase>(),
      getLastUpdateTimestampUseCase: locator<GetLastUpdateTimestampUseCase>(),
      // Provide a dummy GetAnalyticsSummary as AnalyticsRepository is disabled
      getAnalyticsSummaryUseCase: GetAnalyticsSummary(
        DummyAnalyticsRepository(),
      ),
    ),
  );
  // Keep others disabled
  // locator.registerFactory(() => AlternativesProvider(...));
  // locator.registerFactory(() => DoseCalculatorProvider(...));
  // locator.registerFactory(() => InteractionProvider(...));
  locator.registerFactory(
    () => SettingsProvider(),
  ); // Keep SettingsProvider enabled
  // Keep SubscriptionProvider disabled for now
  // locator.registerLazySingleton(() => SubscriptionProvider());

  // Ensure essential async singletons are ready before proceeding
  // await locator.allReady(); // Keep commented out

  print("Service locator setup complete (Drug dependencies re-enabled).");
}

// Dummy implementation if AnalyticsRepository is disabled
class DummyAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<Either<Failure, AnalyticsSummary>> getAnalyticsSummary() async {
    // Return default empty summary
    return Right(
      AnalyticsSummary(topSearchQueries: []),
    ); // Only topSearchQueries exists
  }

  @override
  Future<Either<Failure, Unit>> logEvent(
    String eventName, {
    Map<String, dynamic>? data,
  }) async {
    // Do nothing
    return const Right(unit);
  }
}
