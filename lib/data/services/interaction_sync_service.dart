import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/drug_interaction.dart';

class InteractionSyncService {
  // TODO: Replace with your actual Cloudflare Worker URL after deployment
  static const String _baseUrl =
      'https://mediswitch-api.m-m-lotfy-88.workers.dev';

  final http.Client _client;

  InteractionSyncService({http.Client? client})
    : _client = client ?? http.Client();

  /// Fetches new interactions created/updated since [lastSyncDate]
  /// [lastSyncDate] should be in YYYY-MM-DD format
  Future<List<DrugInteraction>> fetchUpdates(String? lastSyncDate) async {
    try {
      if (lastSyncDate == null) {
        // First time sync? Maybe fetch all or just rely on bundled assets.
        // For efficiency, we rely on assets and only fetch updates since a known baseline.
        // Let's assume baseline is the app build date, e.g., '2024-01-01'.
        lastSyncDate = '2024-01-01';
      }

      final uri = Uri.parse(
        '$_baseUrl/api/interactions/sync?since=$lastSyncDate',
      );
      debugPrint('Syncing interactions from: $uri');

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = body['data'] as List<dynamic>;

        debugPrint('Fetched ${data.length} new interactions from cloud.');

        return data
            .map(
              (json) => DrugInteraction.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        debugPrint('Sync failed with status: ${response.statusCode}');
        throw Exception('Failed to load updates: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error syncing interactions: $e');
      // Return empty list on failure to ensure app continues with local data
      return [];
    }
  }
}
