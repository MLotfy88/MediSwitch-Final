import 'dart:convert';
import 'dart:io'; // For SocketException
import 'package:dartz/dartz.dart'; // Import dartz
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
}

// Implementation of the remote data source
class DrugRemoteDataSourceImpl implements DrugRemoteDataSource {
  final String baseUrl;
  final http.Client client;

  DrugRemoteDataSourceImpl({required this.baseUrl, required this.client});

  // Factory constructor with default values
  factory DrugRemoteDataSourceImpl.create() {
    return DrugRemoteDataSourceImpl(
      baseUrl:
          'http://localhost:8000', // Default URL, should be configurable in production
      client: http.Client(),
    );
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
        final Map<String, dynamic> data = json.decode(response.body);
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
}
