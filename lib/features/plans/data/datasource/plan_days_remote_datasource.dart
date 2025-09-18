import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/plans/models/plan_days_model.dart';
import 'package:http/http.dart' as http;

class PlanDaysRemoteDatasource {
  final http.Client client;
  final String baseUrl = dotenv.env['BASE_API_URL']!;

  PlanDaysRemoteDatasource({required this.client});

  // get plan days list by plan id
  Future<List<PlanDaysModel>> getPlanDaysByPlanId(String planId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/plans/$planId/days'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final responseData = json.decode(decoded);
        final List<dynamic> jsonData = responseData['days'] as List<dynamic>;
        return jsonData.map((json) => PlanDaysModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load plan days: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load plan days: $e');
    }
  }

  // Get specific day's content with tasks and plan items
  Future<PlanDaysModel> getDayContent(String planId, int dayNumber) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/plans/$planId/days/$dayNumber'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decoded);
        return PlanDaysModel.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load plan day content: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load plan day content: $e');
    }
  }
}
