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
    final url = Uri.parse('$baseUrl/api/v1/data/version/');
    try {
      final response = await client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        // Expecting {'version': 'timestamp_str', 'file_type': 'csv/xlsx', ...}
        if (data.containsKey('version') && data.containsKey('file_type')) {
          return Right(data);
        } else {
          print('Error: Invalid version response format from $url');
          return Left(ServerFailure()); // Or a more specific parsing failure
        }
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
      return Left(ServerFailure()); // General server/unexpected failure
    }
  }

  @override
  Future<Either<Failure, String>> downloadLatestData() async {
    final url = Uri.parse('$baseUrl/api/v1/data/latest/');
    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        // Return the file content directly
        return Right(response.body);
      } else {
        print(
          'Error: Failed to download data from $url - Status: ${response.statusCode}',
        );
        return Left(ServerFailure());
      }
    } on SocketException {
      print(
        'Error: Network error (SocketException) downloading data from $url',
      );
      return Left(NetworkFailure());
    } catch (e) {
      print('Error: Unexpected error downloading data from $url: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDeltaSyncDrugs(
    int lastTimestamp,
  ) async {
    final url = Uri.parse('$baseUrl/api/drugs/delta/$lastTimestamp');
    print('DEBUG: Requesting Delta Sync: $url');
    try {
      final response = await client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('DEBUG: Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        // Use compute to run json.decode in a background isolate
        final Map<String, dynamic> data = await compute(
          _parseJson,
          response.body,
        );
        return Right(data);
      } else {
        print(
          'Error: Failed to get delta sync from $url - Status: ${response.statusCode} - Body: ${response.body.substring(0, 100)}...',
        );
        return Left(ServerFailure());
      }
    } on SocketException catch (e) {
      print(
        'Error: Network error (SocketException) fetching delta sync from $url: $e',
      );
      return Left(NetworkFailure());
    } catch (e, s) {
      print('Error: Unexpected error fetching delta sync from $url: $e\n$s');
      return Left(ServerFailure());
    }
  }
}

// Top-level function for compute
Map<String, dynamic> _parseJson(String text) {
  return json.decode(text) as Map<String, dynamic>;
}
