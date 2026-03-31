import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_completion_status_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';

/// User plans remote datasource.
///
/// Error handling is centralized in ErrorInterceptor, which converts
/// DioExceptions to typed AppExceptions. Exceptions propagate naturally
/// to the repository layer for mapping to Failures.
class UserPlansRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('UserPlansRemoteDatasource');

  UserPlansRemoteDatasource({required this.dio});

  Future<UserPlanListResponseModel> fetchUserPlans({
    required String language,
    int? skip,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{'language': language};
    if (skip != null) queryParams['skip'] = skip;
    if (limit != null) queryParams['limit'] = limit;

    final response = await dio.get(
      '/users/me/plans',
      queryParameters: queryParams,
    );

    if (response.data is String) {
      _logger.error('Received plain text response instead of JSON');
      throw const ServerException('Invalid response format from server');
    }
    return UserPlanListResponseModel.fromJson(response.data);
  }

  Future<bool> subscribeToPlan(String planId) async {
    final response = await dio.post(
      '/users/me/plans',
      data: {'plan_id': planId},
    );
    return response.statusCode == 204;
  }

  Future<List<PlanProgressModel>> getUserPlanProgressDetails(
    String planId,
  ) async {
    final response = await dio.get('/users/me/plans/$planId');
    final jsonData = response.data as List<dynamic>;
    return jsonData.map((json) => PlanProgressModel.fromJson(json)).toList();
  }

  Future<UserPlanDayDetailResponse> fetchUserPlanDayContent(
    String planId,
    int dayNumber,
  ) async {
    final response = await dio.get('/users/me/plan/$planId/days/$dayNumber');
    return UserPlanDayDetailResponse.fromJson(response.data);
  }

  Future<Map<int, bool>> fetchPlanDaysCompletionStatus(String planId) async {
    final response = await dio.get('/users/me/plans/$planId/days/completion_status');
    final jsonData = response.data as Map<String, dynamic>;
    final completionResponse =
        UserPlanDayCompletionStatusResponse.fromJson(jsonData);
    return completionResponse.toCompletionStatusMap();
  }

  Future<bool> completeSubTask(String subTaskId) async {
    final response = await dio.post('/users/me/sub-tasks/$subTaskId/complete');
    return response.statusCode == 204;
  }

  Future<bool> completeTask(String taskId) async {
    final response = await dio.post('/users/me/tasks/$taskId/complete');
    return response.statusCode == 204;
  }

  Future<bool> deleteTask(String taskId) async {
    final response = await dio.delete('/users/me/task/$taskId');
    return response.statusCode == 204;
  }

  Future<bool> unenrollFromPlan(String planId) async {
    final response = await dio.delete('/users/me/plans/$planId');
    return response.statusCode == 204;
  }
}
