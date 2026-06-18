import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';

class TasksRemoteDatasource {
  final Dio dio;

  TasksRemoteDatasource({required this.dio});

  // Helper method to handle Dio errors
  Never _throwDioException(DioException e, String defaultMessage) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw const NetworkException('Connection timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      throw const NetworkException('No internet connection');
    } else if (e.response?.statusCode != null) {
      final statusCode = e.response!.statusCode!;
      if (statusCode == 401) {
        throw const AuthenticationException('Unauthorized');
      } else if (statusCode == 403) {
        throw const AuthorizationException('Forbidden');
      } else if (statusCode == 404) {
        throw const NotFoundException('Resource not found');
      } else if (statusCode == 429) {
        throw const RateLimitException('Too many requests');
      } else {
        throw ServerException('$defaultMessage: $statusCode');
      }
    } else {
      throw const NetworkException('Network error');
    }
  }

  // Get tasks by plan item ID
  Future<List<PlanTasksModel>> getTasksByPlanItemId(String planItemId) async {
    try {
      final response = await dio.get('/plan-items/$planItemId/tasks');
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data as List<dynamic>;
        return jsonData.map((json) => PlanTasksModel.fromJson(json)).toList();
      } else {
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 403) {
          throw const AuthorizationException('Forbidden');
        } else if (response.statusCode == 404) {
          throw const NotFoundException('Tasks not found');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to load tasks: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      _throwDioException(e, 'Failed to load tasks');
    }
  }

  // Get task by ID
  Future<PlanTasksModel> getTaskById(String id) async {
    try {
      final response = await dio.get('/tasks/$id');
      if (response.statusCode == 200) {
        return PlanTasksModel.fromJson(response.data);
      } else {
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 403) {
          throw const AuthorizationException('Forbidden');
        } else if (response.statusCode == 404) {
          throw const NotFoundException('Task not found');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to load task: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      _throwDioException(e, 'Failed to load task');
    }
  }

  // Update task
  Future<PlanTasksModel> updateTask(String id, PlanTasksModel task) async {
    try {
      final response = await dio.put(
        '/tasks/$id',
        data: task.toJson(),
      );
      if (response.statusCode == 200) {
        return PlanTasksModel.fromJson(response.data);
      } else {
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 403) {
          throw const AuthorizationException('Forbidden');
        } else if (response.statusCode == 404) {
          throw const NotFoundException('Task not found');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to update task: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      _throwDioException(e, 'Failed to update task');
    }
  }
}
