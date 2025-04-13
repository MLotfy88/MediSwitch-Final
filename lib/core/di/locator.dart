import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart'; // Import dartz for Either, Right, unit
import '../error/failures.dart'; // Import Failure base class
import '../../core/usecases/usecase.dart'; // Import NoParams if needed by use cases
import '../../domain/repositories/analytics_repository.dart'; // Needed for DummyAnalyticsRepository
import '../../presentation/bloc/settings_provider.dart';

// Global Service Locator instance
final locator = GetIt.instance;

Future<void> setupLocator() async {
  print("--- Starting Minimal Locator Setup ---");
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
  // DB Helper registration disabled

  // --- Data Sources ---
  // Wait only for SharedPreferences
  print("Waiting for SharedPreferences...");
  await locator.isReady<SharedPreferences>();
  print("SharedPreferences ready.");

  // Data Sources registration disabled

  // --- Repositories ---
  // Repositories registration disabled

  // --- Use Cases ---
  // Use Cases registration disabled

  // --- Services ---
  // Services registration disabled

  // --- Providers / Blocs ---
  locator.registerFactory(() {
    print("Registering SettingsProvider factory.");
    return SettingsProvider();
  }); // Keep SettingsProvider enabled

  // Other providers registration disabled

  // await locator.allReady(); // Keep commented out

  print("--- Minimal Locator Setup Complete ---");
}

// Dummy implementation remains for safety, though not used now
class DummyAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<Either<Failure, AnalyticsSummary>> getAnalyticsSummary() async {
    return Right(AnalyticsSummary(topSearchQueries: []));
  }

  @override
  Future<Either<Failure, Unit>> logEvent(
    String eventName, {
    Map<String, dynamic>? data,
  }) async {
    return const Right(unit);
  }
}
