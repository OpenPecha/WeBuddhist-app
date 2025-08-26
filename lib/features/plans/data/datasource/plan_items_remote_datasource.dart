import 'dart:convert';
import 'package:flutter_pecha/features/plans/models/plan_items_model.dart';
import 'package:http/http.dart' as http;

class PlanItemsRemoteDatasource {
  final http.Client client;
  final String baseUrl =
      'https://your-api-base-url.com'; // Replace with your actual API URL

  PlanItemsRemoteDatasource({required this.client});

  // get plan items by plan id
  Future<List<PlanItemsModel>> getPlanItemsByPlanId(String planId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/plans/$planId/items'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => PlanItemsModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load plan items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load plan items: $e');
    }
  }

  // Get plan item by ID
  Future<PlanItemsModel> getPlanItemById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/plan-items/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PlanItemsModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to load plan item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load plan item: $e');
    }
  }
}
