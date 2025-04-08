import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';

// Define the structure expected from the analytics summary endpoint
class AnalyticsSummary {
  final List<Map<String, dynamic>> topSearchQueries;
  // Add other summary fields if needed later

  AnalyticsSummary({required this.topSearchQueries});
}

abstract class AnalyticsRepository {
  /// Fetches the analytics summary data from the backend.
  Future<Either<Failure, AnalyticsSummary>> getAnalyticsSummary();
}
