import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/exceptions/plan_exceptions.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_completion_status_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';

class UserPlansRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('UserPlansRemoteDatasource');

  UserPlansRemoteDatasource({required this.dio});

  // get user plans by user id
  Future<UserPlanListResponseModel> fetchUserPlans({
    required String language,
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{'language': language};

      if (skip != null) {
        queryParams['skip'] = skip;
      }
      if (limit != null) {
        queryParams['limit'] = limit;
      }

      final response = await dio.get(
        '/users/me/plans',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return UserPlanListResponseModel.fromJson(response.data);
      } else {
        _logger.error('Failed to load user plans: ${response.statusCode}');
        throw Exception('Failed to load user plans: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error in fetchUserPlans', e);
      throw Exception('Failed to load user plans: $e');
    }
  }

  //subscribe user to a plan
  Future<bool> subscribeToPlan(String planId) async {
    try {
      final response = await dio.post(
        '/users/me/plans',
        data: {'plan_id': planId},
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        throw PlanApiException(
          'Failed to subscribe to plan',
          statusCode: response.statusCode,
          responseBody: response.data,
        );
      }
    } on DioException catch (e, stackTrace) {
      throw PlanApiException(
        'Network error while subscribing to plan',
        originalError: e.error,
        stackTrace: stackTrace,
      );
    } on PlanApiException {
      rethrow;
    } catch (e, stackTrace) {
      throw PlanOperationException(
        'subscribeToPlan',
        'Unexpected error during subscription',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // get user plan progress details
  Future<List<PlanProgressModel>> getUserPlanProgressDetails(
    String planId,
  ) async {
    try {
      final response = await dio.get('/users/me/plans/$planId');
      if (response.statusCode == 200) {
        final jsonData = response.data as List<dynamic>;
        return jsonData.map((json) => PlanProgressModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load user plan progress details: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load user plan progress details: $e');
    }
  }

  // fetch user plan day content or details
  Future<UserPlanDayDetailResponse> fetchUserPlanDayContent(
    String planId,
    int dayNumber,
  ) async {
    try {
      final response = await dio.get('/users/me/plan/$planId/days/$dayNumber');
      if (response.statusCode == 200) {
        return UserPlanDayDetailResponse.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to load user plan day content: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.error('Failed to load user plan day content', e);
      throw Exception('Failed to load user plan day content: $e');
    }
  }

  /// Fetch completion status for all days in a plan (bulk endpoint)
  /// Returns a map where key is dayNumber and value is isCompleted status
  Future<Map<int, bool>> fetchPlanDaysCompletionStatus(String planId) async {
    try {
      final response = await dio.get('/users/me/plans/$planId/days/completion_status');

      if (response.statusCode == 200) {
        final jsonData = response.data as Map<String, dynamic>;
        final completionResponse =
            UserPlanDayCompletionStatusResponse.fromJson(jsonData);

        return completionResponse.toCompletionStatusMap();
      } else {
        _logger.error(
          'Failed to load plan days completion status: ${response.statusCode}',
        );
        throw Exception(
          'Failed to load plan days completion status: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.error('Error fetching plan days completion status', e);
      throw Exception('Failed to load plan days completion status: $e');
    }
  }

  // sub tasks completion post request
  Future<bool> completeSubTask(String subTaskId) async {
    try {
      final response = await dio.post('/users/me/sub-tasks/$subTaskId/complete');

      if (response.statusCode == 204) {
        return true;
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.data}';
        _logger.error('Failed to complete sub task: $errorMessage');
        throw Exception('Failed to complete sub task: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      _logger.error('Failed to complete sub task', e);
      throw Exception('Failed to complete sub task: $e');
    }
  }

  // task completion post request
  Future<bool> completeTask(String taskId) async {
    try {
      final response = await dio.post('/users/me/tasks/$taskId/complete');

      if (response.statusCode == 204) {
        return true;
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.data}';
        _logger.error('Failed to complete task: $errorMessage');
        throw Exception('Failed to complete task: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      _logger.error('Failed to complete task', e);
      throw Exception('Failed to complete task: $e');
    }
  }

  // delete task request
  Future<bool> deleteTask(String taskId) async {
    try {
      final response = await dio.delete('/users/me/task/$taskId');

      if (response.statusCode == 204) {
        return true;
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.data}';
        _logger.error('Failed to delete task: $errorMessage');
        throw Exception('Failed to delete task: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      _logger.error('Failed to delete task', e);
      throw Exception('Failed to delete task: $e');
    }
  }

  // unenroll from plan request
  Future<bool> unenrollFromPlan(String planId) async {
    try {
      final response = await dio.delete('/users/me/plans/$planId');

      if (response.statusCode == 204) {
        return true;
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.data}';
        _logger.error('Failed to unenroll from plan: $errorMessage');
        throw Exception('Failed to unenroll from plan: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      _logger.error('Failed to unenroll from plan', e);
      throw Exception('Failed to unenroll from plan: $e');
    }
  }
}
