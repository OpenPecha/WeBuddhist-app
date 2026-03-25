import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';

class PlanDaysRemoteDatasource {
  final Dio dio;

  PlanDaysRemoteDatasource({required this.dio});

  // get plan days list by plan id
  Future<List<PlanDaysModel>> getPlanDaysByPlanId(String planId) async {
    try {
      final response = await dio.get('/plans/$planId/days');
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data['days'] as List<dynamic>;
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
      final response = await dio.get('/plans/$planId/days/$dayNumber');
      if (response.statusCode == 200) {
        return PlanDaysModel.fromJson(response.data);
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
