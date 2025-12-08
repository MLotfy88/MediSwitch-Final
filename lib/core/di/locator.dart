import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
// Database Helper
import 'package:mediswitch/core/database/database_helper.dart';
// Services
import 'package:mediswitch/core/services/file_logger_service.dart';
import 'package:mediswitch/core/services/log_notifier.dart';
// Database Helper
// Database Helper

// Data Sources
import 'package:mediswitch/data/datasources/local/interaction_local_data_source.dart';
import 'package:mediswitch/data/datasources/local/sqlite_local_data_source.dart';
import 'package:mediswitch/data/datasources/remote/analytics_remote_data_source.dart';
import 'package:mediswitch/data/datasources/remote/config_remote_data_source.dart';
import 'package:mediswitch/data/datasources/remote/drug_remote_data_source.dart';
// Repositories
import 'package:mediswitch/data/repositories/analytics_repository_impl.dart';
import 'package:mediswitch/data/repositories/config_repository_impl.dart';
import 'package:mediswitch/data/repositories/drug_repository_impl.dart';
import 'package:mediswitch/data/repositories/interaction_repository_impl.dart';
// Services
import 'package:mediswitch/data/services/analytics_service_impl.dart';
import 'package:mediswitch/domain/repositories/analytics_repository.dart';
import 'package:mediswitch/domain/repositories/config_repository.dart';
import 'package:mediswitch/domain/repositories/drug_repository.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';
import 'package:mediswitch/domain/services/analytics_service.dart';
import 'package:mediswitch/domain/services/dosage_calculator_service.dart';
import 'package:mediswitch/domain/services/interaction_checker_service.dart';
// Use Cases
import 'package:mediswitch/domain/usecases/filter_drugs_by_category.dart';
import 'package:mediswitch/domain/usecases/find_drug_alternatives.dart';
import 'package:mediswitch/domain/usecases/get_admob_config.dart';
import 'package:mediswitch/domain/usecases/get_all_drugs.dart';
import 'package:mediswitch/domain/usecases/get_analytics_summary.dart';
import 'package:mediswitch/domain/usecases/get_available_categories.dart';
import 'package:mediswitch/domain/usecases/get_categories_with_count.dart';
import 'package:mediswitch/domain/usecases/get_general_config.dart';
import 'package:mediswitch/domain/usecases/get_high_risk_drugs.dart';
import 'package:mediswitch/domain/usecases/get_high_risk_ingredients.dart';
import 'package:mediswitch/domain/usecases/get_last_update_timestamp.dart';
import 'package:mediswitch/domain/usecases/get_popular_drugs.dart';
import 'package:mediswitch/domain/usecases/get_recently_updated_drugs.dart';
import 'package:mediswitch/domain/usecases/load_interaction_data.dart';
import 'package:mediswitch/domain/usecases/search_drugs.dart';
import 'package:mediswitch/presentation/bloc/ad_config_provider.dart';
// Providers / Blocs
import 'package:mediswitch/presentation/bloc/alternatives_provider.dart';
import 'package:mediswitch/presentation/bloc/dose_calculator_provider.dart';
import 'package:mediswitch/presentation/bloc/interaction_provider.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/bloc/settings_provider.dart';
import 'package:mediswitch/presentation/bloc/subscription_provider.dart';
import 'package:mediswitch/presentation/services/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global Service Locator instance
final locator = GetIt.instance;

Future<void> setupLocator() async {
  // Initialize logger first
  final logger = FileLoggerService();
  await logger.initialize();
  locator.registerSingleton<FileLoggerService>(logger);
  // Register the LogNotifier instance from the FileLoggerService
  locator.registerSingleton<LogNotifier>(logger.logNotifier);
  logger.i("--- Starting Full Locator Setup ---");

  // --- External Dependencies ---
  locator.registerSingletonAsync<SharedPreferences>(() async {
    logger.i("Locator: Registering SharedPreferences...");
    final prefs = await SharedPreferences.getInstance();
    logger.i("Locator: SharedPreferences registered.");
    return prefs;
  });
  locator.registerLazySingleton<http.Client>(() {
    logger.i("Locator: Registering http.Client.");
    return http.Client();
  });

  // --- Core ---
  locator.registerSingletonAsync<DatabaseHelper>(() async {
    logger.i("Locator: Registering DatabaseHelper...");
    final helper = DatabaseHelper();
    try {
      await helper.database; // Initialize DB
      logger.i("Locator: DatabaseHelper registered and DB initialized.");
    } catch (e, s) {
      logger.e("Locator: Error initializing DatabaseHelper", e, s);
      rethrow;
    }
    return helper;
  });

  // --- Data Sources ---
  logger.i("Locator: Waiting for SharedPreferences and DatabaseHelper...");
  try {
    await Future.wait([
      locator.isReady<SharedPreferences>(),
      locator.isReady<DatabaseHelper>(),
    ]);
    logger.i("Locator: SharedPreferences and DatabaseHelper ready.");
  } catch (e, s) {
    logger.e(
      "Locator: Error waiting for SharedPreferences/DatabaseHelper",
      e,
      s,
    );
  }

  locator.registerLazySingleton<DrugRemoteDataSource>(() {
    logger.i("Locator: Registering DrugRemoteDataSource...");
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
    logger.i("Locator: Registering SqliteLocalDataSource...");
    return SqliteLocalDataSource(dbHelper: locator<DatabaseHelper>());
  });
  locator.registerLazySingleton<InteractionLocalDataSource>(() {
    logger.i("Locator: Registering InteractionLocalDataSource...");
    return InteractionLocalDataSourceImpl();
  });
  locator.registerLazySingleton<ConfigRemoteDataSource>(() {
    logger.i("Locator: Registering ConfigRemoteDataSource...");
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
    logger.i("Locator: Registering AnalyticsRemoteDataSource...");
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
    logger.i("Locator: Registering DrugRepository...");
    return DrugRepositoryImpl(
      remoteDataSource: locator<DrugRemoteDataSource>(),
      localDataSource: locator<SqliteLocalDataSource>(),
    );
  });
  locator.registerLazySingleton<InteractionRepository>(() {
    logger.i("Locator: Registering InteractionRepository...");
    return InteractionRepositoryImpl(); // Loads data internally
  });
  locator.registerLazySingleton<ConfigRepository>(() {
    logger.i("Locator: Registering ConfigRepository...");
    return ConfigRepositoryImpl(
      remoteDataSource: locator<ConfigRemoteDataSource>(),
    );
  });
  locator.registerLazySingleton<AnalyticsRepository>(() {
    logger.i("Locator: Registering AnalyticsRepository...");
    return AnalyticsRepositoryImpl(
      remoteDataSource: locator<AnalyticsRemoteDataSource>(),
    );
  });

  // --- Use Cases ---
  logger.i("Locator: Registering Use Cases...");
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
    () => GetCategoriesWithCountUseCase(locator<DrugRepository>()),
  );
  locator.registerLazySingleton(
    () => GetLastUpdateTimestampUseCase(locator<DrugRepository>()),
  );
  locator.registerLazySingleton(
    () => FindDrugAlternativesUseCase(locator<DrugRepository>()),
  );
  locator.registerLazySingleton(
    () => GetRecentlyUpdatedDrugsUseCase(locator<DrugRepository>()),
  );
  locator.registerLazySingleton(
    () => GetPopularDrugsUseCase(locator<DrugRepository>()),
  );
  locator.registerLazySingleton(
    () => GetHighRiskDrugsUseCase(
      interactionRepository: locator<InteractionRepository>(),
      drugRepository: locator<DrugRepository>(),
    ),
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
  logger.i("Locator: Registering Services...");
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
  logger.i("Locator: Registering Providers...");
  locator.registerLazySingleton(
    // Changed from registerFactory
    () => MedicineProvider(
      searchDrugsUseCase: locator<SearchDrugsUseCase>(),
      filterDrugsByCategoryUseCase: locator<FilterDrugsByCategoryUseCase>(),
      getCategoriesWithCountUseCase: locator<GetCategoriesWithCountUseCase>(),
      getLastUpdateTimestampUseCase: locator<GetLastUpdateTimestampUseCase>(),
      getRecentlyUpdatedDrugsUseCase: locator<GetRecentlyUpdatedDrugsUseCase>(),
      getPopularDrugsUseCase: locator<GetPopularDrugsUseCase>(),
      getHighRiskDrugsUseCase: locator<GetHighRiskDrugsUseCase>(),
      getHighRiskIngredientsUseCase: locator<GetHighRiskIngredientsUseCase>(),
      localDataSource: locator<SqliteLocalDataSource>(),
    ),
  );

  locator.registerLazySingleton(
    () => GetHighRiskIngredientsUseCase(
      interactionRepository: locator<InteractionRepository>(),
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
  locator.registerFactory(
    () => SettingsProvider(/* logger: locator<FileLoggerService>() */),
  );
  locator.registerLazySingleton(() => SubscriptionProvider());

  locator.registerLazySingleton(
    () => AdConfigProvider(
      // getAdMobConfig: locator<GetAdMobConfig>(), // If I inject it, but the provider creates it currently.
      // Wait, AdConfigProvider in previous step was updated to not use args in constructor?
      // Let's check AdConfigProvider again. It uses locator inside?
      // "class AdConfigProvider extends ChangeNotifier { ... final GetAdMobConfig _getAdMobConfig = locator<GetAdMobConfig>(); ... }"
      // Yes, it uses locator inside. So no args needed.
    ),
  );

  // Ensure all asynchronous singletons are ready before proceeding
  logger.i("Locator: Waiting for all async singletons...");
  await locator.allReady();
  logger.i("--- Full Locator Setup Complete ---");
}

// Dummy implementation is no longer needed
// class DummyAnalyticsRepository implements AnalyticsRepository { ... }
