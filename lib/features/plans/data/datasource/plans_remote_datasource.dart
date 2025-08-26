import 'dart:convert';

import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:http/http.dart' as http;

class PlansRemoteDatasource {
  final http.Client client;
  final String baseUrl =
      'https://your-api-base-url.com'; // Replace with your actual API URL

  PlansRemoteDatasource({required this.client});

  // get all plans
  Future<List<PlansModel>> getPlans() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/plans'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => PlansModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load plans: $e');
    }
  }

  // get plan by id
  Future<PlansModel> getPlanById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/plans/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PlansModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to load plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load plan: $e');
    }
  }
}
