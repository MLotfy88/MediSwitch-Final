import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mediswitch/data/datasources/local/sqlite_local_data_source.dart';

/// Service for downloading specialty-specific data
class SpecialtyDownloadService {
  final SqliteLocalDataSource _localDataSource;
  final http.Client _httpClient;
  final String _apiBaseUrl;

  SpecialtyDownloadService({
    required SqliteLocalDataSource localDataSource,
    http.Client? httpClient,
    String? apiBaseUrl,
  }) : _localDataSource = localDataSource,
       _httpClient = httpClient ?? http.Client(),
       _apiBaseUrl =
           apiBaseUrl ?? 'https://mediswitch-api.YOUR_DOMAIN.workers.dev';

  /// Download specialty data (interactions + dosages)
  Future<void> downloadSpecialtyData(
    String specialtyId,
    void Function(double progress) onProgress,
  ) async {
    try {
      onProgress(0.1);

      // Step 1: Fetch drug IDs for this specialty
      final drugsResponse = await _httpClient.get(
        Uri.parse('$_apiBaseUrl/api/specialty-drugs/$specialtyId'),
      );

      if (drugsResponse.statusCode != 200) {
        throw Exception('Failed to fetch specialty drugs');
      }

      final drugIds =
          (jsonDecode(drugsResponse.body)['drug_ids'] as List).cast<int>();

      onProgress(0.3);

      // Step 2: Fetch interactions for these drugs
      final interactionsResponse = await _httpClient.post(
        Uri.parse('$_apiBaseUrl/api/specialty-interactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'drug_ids': drugIds}),
      );

      if (interactionsResponse.statusCode != 200) {
        throw Exception('Failed to fetch specialty interactions');
      }

      final interactions =
          jsonDecode(interactionsResponse.body)['data'] as List;

      onProgress(0.6);

      // Step 3: Save interactions locally
      await _localDataSource.saveDrugInteractions(
        interactions.cast<Map<String, dynamic>>(),
      );

      onProgress(0.8);

      // Step 4: Fetch dosages for these drugs
      final dosagesResponse = await _httpClient.post(
        Uri.parse('$_apiBaseUrl/api/specialty-dosages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'drug_ids': drugIds}),
      );

      if (dosagesResponse.statusCode != 200) {
        throw Exception('Failed to fetch specialty dosages');
      }

      final dosages = jsonDecode(dosagesResponse.body)['data'] as List;

      // Step 5: Save dosages locally (if table exists)
      // TODO: Add saveDosageGuidelines method to local data source

      onProgress(1.0);
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  /// Check which specialties have been downloaded
  Future<Set<String>> getDownloadedSpecialties() async {
    // TODO: Implement tracking of downloaded specialties
    // This could be stored in shared_preferences or a metadata table
    return {};
  }
}
