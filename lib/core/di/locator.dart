import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  // --- Core ---
  // Temporarily disable DB Helper registration
  // locator.registerSingletonAsync<DatabaseHelper>(() async {
  //    final helper = DatabaseHelper();
  //    await helper.database;
  //    return helper;
  // });
  // --- Data Sources ---
  // Wait only for SharedPreferences for now
  await locator.isReady<SharedPreferences>();
  // await Future.wait([
  //    locator.isReady<SharedPreferences>(),
  //    locator.isReady<DatabaseHelper>(),
  // ]);

  // --- Temporarily Disable Most Registrations ---
  print("INFO: Temporarily disabling most locator registrations for testing.");

  // locator.registerLazySingleton<DrugRemoteDataSource>(() { ... });
  // locator.registerLazySingleton<ConfigRemoteDataSource>(() { ... });
  // locator.registerLazySingleton<SqliteLocalDataSource>(() => ...);
  // locator.registerLazySingleton<InteractionLocalDataSource>(() => ...);
  // locator.registerLazySingleton<AnalyticsRemoteDataSource>(() { ... });

  // --- Repositories ---
  // locator.registerLazySingleton<DrugRepository>(() => ...);
  // locator.registerLazySingleton<ConfigRepository>(() => ...);
  // locator.registerLazySingleton<InteractionRepository>(() => ...);
  // locator.registerLazySingleton<AnalyticsRepository>(() => ...);

  // --- Use Cases ---
  // locator.registerLazySingleton(() => GetAllDrugs(locator<DrugRepository>()));
  // locator.registerLazySingleton(() => SearchDrugsUseCase(locator<DrugRepository>()));
  // locator.registerLazySingleton(() => FilterDrugsByCategoryUseCase(locator<DrugRepository>()));
  // locator.registerLazySingleton(() => GetAvailableCategoriesUseCase(locator<DrugRepository>()));
  // locator.registerLazySingleton(() => FindDrugAlternativesUseCase(locator<DrugRepository>()));
  // locator.registerLazySingleton(() => LoadInteractionData(locator<InteractionRepository>()));
  // locator.registerLazySingleton(() => GetLastUpdateTimestampUseCase(locator<DrugRepository>()));
  // locator.registerLazySingleton(() => GetAdMobConfig(locator<ConfigRepository>()));
  // locator.registerLazySingleton(() => GetGeneralConfig(locator<ConfigRepository>()));
  // locator.registerLazySingleton(() => GetAnalyticsSummary(locator<AnalyticsRepository>()));

  // --- Services ---
  // locator.registerLazySingleton(() => DosageCalculatorService());
  // locator.registerLazySingleton(() => InteractionCheckerService());
  // locator.registerLazySingleton<AnalyticsService>(() { ... });
  // --- Providers / Blocs ---
  // Register providers as Factories
  // Temporarily disable providers that depend on disabled components
  // locator.registerFactory(() => MedicineProvider(...));
  // locator.registerFactory(() => AlternativesProvider(...));
  // locator.registerFactory(() => DoseCalculatorProvider(...));
  // locator.registerFactory(() => InteractionProvider(...));

  // Keep SettingsProvider as it's needed by MyApp and only depends on SharedPreferences
  locator.registerFactory(() => SettingsProvider());

  // Temporarily disable SubscriptionProvider
  // locator.registerLazySingleton(() => SubscriptionProvider());

  // Ensure all asynchronous singletons are ready (optional, but good practice)
  // Commenting out to see if it improves perceived startup time.
  // Dependencies might not be ready immediately when accessed later.
  // await locator.allReady();

  print("Service locator setup complete."); // Add a log to confirm setup
}
