import 'dart:async'; // For TimeoutException
import 'dart:convert';
import 'dart:io'; // For SocketException

import 'package:http/http.dart' as http;

import '../../../core/error/exceptions.dart'; // Keep for now, will create if needed
import '../../models/admob_config_model.dart'; // Corrected path
import '../../models/general_config_model.dart'; // Corrected path

abstract class ConfigRemoteDataSource {
  /// Fetches AdMob config from `/api/v1/config/ads`
  /// Throws a [ServerException] for all error codes.
  Future<AdMobConfigModel> getAdMobConfig();

  /// Fetches General config from `/api/v1/config/general`
  /// Throws a [ServerException] for all error codes.
  Future<GeneralConfigModel> getGeneralConfig();
}

class ConfigRemoteDataSourceImpl implements ConfigRemoteDataSource {
  final http.Client client;
  final String baseUrl; // Base URL for the backend API

  ConfigRemoteDataSourceImpl({required this.client, required this.baseUrl});

  @override
  Future<AdMobConfigModel> getAdMobConfig() async {
    final url = Uri.parse('$baseUrl/api/config');
    print('Fetching AdMob config from: $url'); // Logging
    try {
      final response = await client
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15)); // Add timeout

      if (response.statusCode == 200) {
        try {
          return AdMobConfigModel.fromJson(
            json.decode(response.body) as Map<String, dynamic>,
          );
        } catch (e) {
          print('Error parsing AdMob config JSON: $e');
          throw ServerException(message: 'Failed to parse server response.');
        }
      } else {
        print(
          'Server error fetching AdMob config: ${response.statusCode} ${response.reasonPhrase}',
        );
        throw ServerException(
          message: 'Failed to load AdMob config from server.',
        );
      }
    } on SocketException {
      print('Network error fetching AdMob config.');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
      );
    } on TimeoutException {
      print('Request timeout fetching AdMob config.');
      throw NetworkException(message: 'Request timed out. Please try again.');
    } catch (e) {
      print('Unexpected error fetching AdMob config: $e');
      throw ServerException(message: 'An unexpected error occurred.');
    }
  }

  @override
  Future<GeneralConfigModel> getGeneralConfig() async {
    final url = Uri.parse('$baseUrl/api/v1/config/general/');
    print('Fetching General config from: $url'); // Logging
    try {
      final response = await client
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15)); // Add timeout

      if (response.statusCode == 200) {
        try {
          return GeneralConfigModel.fromJson(
            json.decode(response.body) as Map<String, dynamic>,
          );
        } catch (e) {
          print('Error parsing General config JSON: $e');
          throw ServerException(message: 'Failed to parse server response.');
        }
      } else {
        print(
          'Server error fetching General config: ${response.statusCode} ${response.reasonPhrase}',
        );
        throw ServerException(
          message: 'Failed to load General config from server.',
        );
      }
    } on SocketException {
      print('Network error fetching General config.');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
      );
    } on TimeoutException {
      print('Request timeout fetching General config.');
      throw NetworkException(message: 'Request timed out. Please try again.');
    } catch (e) {
      print('Unexpected error fetching General config: $e');
      throw ServerException(message: 'An unexpected error occurred.');
    }
  }
}
