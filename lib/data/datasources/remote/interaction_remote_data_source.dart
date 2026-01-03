import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/error/exceptions.dart';

abstract class InteractionRemoteDataSource {
  Future<List<Map<String, dynamic>>> getDrugInteractions(int medId);
  Future<List<Map<String, dynamic>>> getFoodInteractions(int medId);
  Future<List<Map<String, dynamic>>> getDiseaseInteractions(int medId);
}

class InteractionRemoteDataSourceImpl implements InteractionRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  InteractionRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
  });

  @override
  Future<List<Map<String, dynamic>>> getDrugInteractions(int medId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/interactions?med_id=$medId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as List?;
      return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    } else {
      throw ServerException(
        message: 'Failed to fetch drug interactions from server',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFoodInteractions(int medId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/admin/food-interactions?med_id=$medId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as List?;
      return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    } else {
      throw ServerException(
        message: 'Failed to fetch food interactions from server',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDiseaseInteractions(int medId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/admin/disease-interactions?med_id=$medId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as List?;
      return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    } else {
      throw ServerException(
        message: 'Failed to fetch disease interactions from server',
      );
    }
  }
}
