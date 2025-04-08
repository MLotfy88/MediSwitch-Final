import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/services/analytics_service.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class AnalyticsServiceImpl implements AnalyticsService {
  final http.Client client;
  final String baseUrl; // Base URL for the backend API

  AnalyticsServiceImpl({required this.client, required this.baseUrl});

  @override
  Future<void> logEvent(String eventType, {Map<String, dynamic>? data}) async {
    final url = Uri.parse('$baseUrl/api/v1/analytics/log/');
    final body = json.encode({
      'event_type': eventType,
      'data': data ?? {}, // Ensure data is always a map, even if empty
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      // TODO: Add user identifier if available (e.g., from auth provider or device ID)
      // 'user_id': 'some_user_identifier',
    });

    if (kDebugMode) {
      print('Logging Analytics Event:');
      print('  URL: $url');
      print('  Body: $body');
    }

    try {
      final response = await client
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10)); // Add a timeout

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Successfully logged
        if (kDebugMode) {
          print('Analytics event logged successfully.');
        }
      } else {
        // Log error but don't throw exception to avoid crashing the app for analytics failure
        print(
          'Failed to log analytics event: ${response.statusCode} ${response.reasonPhrase}',
        );
        // Optionally log response body for debugging: print('Response body: ${response.body}');
      }
    } catch (e) {
      // Log network or other errors but don't crash
      print('Error logging analytics event: $e');
    }
  }
}
