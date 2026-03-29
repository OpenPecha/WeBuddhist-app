import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/network/dio_error_handler.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_completion_status_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';

class UserPlansRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('UserPlansRemoteDatasource');

  UserPlansRemoteDatasource({required this.dio});

  Future<UserPlanListResponseModel> fetchUserPlans({
    required String language,
    int? skip,
    int? limit,
  }) async {
    try {
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
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to load user plans');
    }
  }

  Future<bool> subscribeToPlan(String planId) async {
    try {
      final response = await dio.post(
        '/users/me/plans',
        data: {'plan_id': planId},
      );
      return response.statusCode == 204;
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to subscribe to plan');
    }
  }

  Future<List<PlanProgressModel>> getUserPlanProgressDetails(
    String planId,
  ) async {
    try {
      final response = await dio.get('/users/me/plans/$planId');
      final jsonData = response.data as List<dynamic>;
      return jsonData.map((json) => PlanProgressModel.fromJson(json)).toList();
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to load user plan progress details');
    }
  }

  Future<UserPlanDayDetailResponse> fetchUserPlanDayContent(
    String planId,
    int dayNumber,
  ) async {
    try {
      final response = await dio.get('/users/me/plan/$planId/days/$dayNumber');
      return UserPlanDayDetailResponse.fromJson(response.data);
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to load user plan day content');
    }
  }

  Future<Map<int, bool>> fetchPlanDaysCompletionStatus(String planId) async {
    try {
      final response = await dio.get('/users/me/plans/$planId/days/completion_status');
      final jsonData = response.data as Map<String, dynamic>;
      final completionResponse =
          UserPlanDayCompletionStatusResponse.fromJson(jsonData);
      return completionResponse.toCompletionStatusMap();
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to load plan days completion status');
    }
  }

  Future<bool> completeSubTask(String subTaskId) async {
    try {
      final response = await dio.post('/users/me/sub-tasks/$subTaskId/complete');
      return response.statusCode == 204;
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to complete sub task');
    }
  }

  Future<bool> completeTask(String taskId) async {
    try {
      final response = await dio.post('/users/me/tasks/$taskId/complete');
      return response.statusCode == 204;
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to complete task');
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      final response = await dio.delete('/users/me/task/$taskId');
      return response.statusCode == 204;
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to delete task');
    }
  }

  Future<bool> unenrollFromPlan(String planId) async {
    try {
      final response = await dio.delete('/users/me/plans/$planId');
      return response.statusCode == 204;
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to unenroll from plan');
    }
  }
}
