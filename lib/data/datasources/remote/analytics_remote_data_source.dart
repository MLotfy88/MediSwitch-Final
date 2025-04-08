import 'dart:async'; // For TimeoutException
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/error/exceptions.dart';
import '../../../domain/repositories/analytics_repository.dart'; // Import AnalyticsSummary

abstract class AnalyticsRemoteDataSource {
  /// Fetches analytics summary from `/api/v1/analytics/summary/`
  /// Throws a [ServerException] for server errors.
  /// Throws a [NetworkException] for network errors.
  Future<AnalyticsSummary> getAnalyticsSummary();
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final http.Client client;
  final String baseUrl;
  // TODO: Add mechanism to get auth token if endpoint requires authentication
  // final AuthTokenProvider authTokenProvider;

  AnalyticsRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
    // required this.authTokenProvider,
  });

  @override
  Future<AnalyticsSummary> getAnalyticsSummary() async {
    final url = Uri.parse('$baseUrl/api/v1/analytics/summary/');
    print('Fetching Analytics Summary from: $url');

    // TODO: Add Authorization header if needed
    // final token = await authTokenProvider.getToken();
    // final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
    final headers = {
      'Content-Type': 'application/json',
    }; // Assuming public for now

    try {
      final response = await client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data =
              json.decode(response.body) as Map<String, dynamic>;
          // Basic validation of the expected structure
          if (data.containsKey('top_search_queries') &&
              data['top_search_queries'] is List) {
            // Ensure the list items are maps
            final List<Map<String, dynamic>> topQueries =
                List<Map<String, dynamic>>.from(
                  (data['top_search_queries'] as List).map(
                    (item) => item as Map<String, dynamic>,
                  ),
                );
            return AnalyticsSummary(topSearchQueries: topQueries);
          } else {
            print('Error: Invalid analytics summary format from $url');
            throw ServerException(
              message: 'Invalid response format from server.',
            );
          }
        } catch (e) {
          print('Error parsing analytics summary JSON: $e');
          throw ServerException(message: 'Failed to parse server response.');
        }
      } else {
        print(
          'Server error fetching analytics summary: ${response.statusCode} ${response.reasonPhrase}',
        );
        throw ServerException(
          message: 'Failed to load analytics summary from server.',
        );
      }
    } on SocketException {
      print('Network error fetching analytics summary.');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
      );
    } on TimeoutException {
      print('Request timeout fetching analytics summary.');
      throw NetworkException(message: 'Request timed out. Please try again.');
    } catch (e) {
      print('Unexpected error fetching analytics summary: $e');
      throw ServerException(message: 'An unexpected error occurred.');
    }
  }
}
