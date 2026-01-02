import 'dart:convert';
import 'dart:io'; // For SocketException

import 'package:dartz/dartz.dart'; // Import dartz
import 'package:flutter/foundation.dart'; // For compute
import 'package:http/http.dart' as http;

import '../../../core/error/failures.dart'; // Corrected path for failures.dart

// Abstract class defining the contract for remote data source
abstract class DrugRemoteDataSource {
  /// Fetches the latest version info from the backend
  /// Returns Right(Map<String, dynamic>) on success, Left(Failure) on error
  Future<Either<Failure, Map<String, dynamic>>> getLatestVersion();

  /// Downloads the latest drug data file from the backend
  /// Returns Right(String) with file content on success, Left(Failure) on error
  Future<Either<Failure, String>> downloadLatestData();

  /// Get drugs updated after a specific timestamp (Delta Sync)
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncDrugs(
    int lastTimestamp,
  );

  /// Get interactions updated after a specific timestamp
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncInteractions(
    int lastTimestamp,
  );

  /// Get med-ingredients updated after a specific timestamp
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncMedIngredients(
    int lastTimestamp,
  );

  /// Get dosages updated after a specific timestamp
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncDosages(
    int lastTimestamp,
  );

  /// Get food interactions updated after a specific timestamp
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncFoodInteractions(
    int lastTimestamp,
  );

  /// Get disease interactions updated after a specific timestamp
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncDiseaseInteractions(
    int lastTimestamp,
  );
}

// Implementation of the remote data source
class DrugRemoteDataSourceImpl implements DrugRemoteDataSource {
  final String baseUrl;
  final http.Client client;

  DrugRemoteDataSourceImpl({required this.baseUrl, required this.client});

  // Factory constructor with default values
  factory DrugRemoteDataSourceImpl.create() {
    // Use String.fromEnvironment to make the URL configurable at build time.
    // Example build command: flutter run --dart-define=BACKEND_URL=https://your-production-url.com
    const backendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue:
          'https://mediswitch-api.m-m-lotfy-88.workers.dev', // Default for local development
    );
    print('Using Backend URL: $backendUrl'); // Log the URL being used

    return DrugRemoteDataSourceImpl(baseUrl: backendUrl, client: http.Client());
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getLatestVersion() async {
    final url = Uri.parse(
      '$baseUrl/api/sync/version',
    ); // Updated to use sync namespace
    try {
      final response = await client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes))
                as Map<String, dynamic>;
        return Right(data);
      } else {
        print(
          'Error: Failed to get version from $url - Status: ${response.statusCode}',
        );
        return Left(ServerFailure());
      }
    } on SocketException {
      print(
        'Error: Network error (SocketException) fetching version from $url',
      );
      return Left(NetworkFailure());
    } catch (e) {
      print('Error: Unexpected error fetching version from $url: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, String>> downloadLatestData() async {
    // NOTE: This legacy method might be deprecated soon in favor of sync/drugs
    final url = Uri.parse('$baseUrl/api/v1/data/latest/');
    print('DEBUG: Downloading CSV from: $url');
    try {
      final response = await client
          .get(url)
          .timeout(const Duration(seconds: 30));

      print('DEBUG: Download Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return Right(utf8.decode(response.bodyBytes));
      } else {
        print('Error: Failed to download data from $url');
        return Left(ServerFailure());
      }
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  int min(int a, int b) => a < b ? a : b;

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncDrugs(
    int lastTimestamp,
  ) async {
    return _getSyncData('$baseUrl/api/sync/drugs', lastTimestamp);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncInteractions(
    int lastTimestamp,
  ) async {
    return _getSyncData('$baseUrl/api/sync/interactions', lastTimestamp);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncMedIngredients(
    int lastTimestamp,
  ) async {
    return _getSyncData('$baseUrl/api/sync/med-ingredients', lastTimestamp);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncDosages(
    int lastTimestamp,
  ) async {
    return _getSyncData('$baseUrl/api/sync/dosages', lastTimestamp);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncFoodInteractions(
    int lastTimestamp,
  ) async {
    return _getSyncData('$baseUrl/api/sync/food-interactions', lastTimestamp);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncDiseaseInteractions(
    int lastTimestamp,
  ) async {
    return _getSyncData(
      '$baseUrl/api/sync/disease-interactions',
      lastTimestamp,
    );
  }

  Future<Either<Failure, Map<String, dynamic>>> _getSyncData(
    String endpoint,
    int lastTimestamp,
  ) async {
    // Ensure we use the correct query parameter
    final url = Uri.parse('$endpoint?since=$lastTimestamp');
    print('DEBUG: Requesting Sync: $url');
    try {
      final response = await client
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 60));

      print('DEBUG: Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = await compute(
          _parseJson,
          responseBody,
        );
        return Right(data);
      } else {
        final errorMsg = 'HTTP ${response.statusCode}';
        return Left(ServerFailure(message: errorMsg));
      }
    } on SocketException catch (e) {
      return Left(NetworkFailure(message: 'Network error: $e'));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}

// Top-level function for compute
Map<String, dynamic> _parseJson(String text) {
  return json.decode(text) as Map<String, dynamic>;
}
