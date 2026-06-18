import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';

class PlanDaysRemoteDatasource {
  final Dio dio;

  PlanDaysRemoteDatasource({required this.dio});

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

  // get plan days list by plan id
  Future<List<PlanDaysModel>> getPlanDaysByPlanId(String planId) async {
    try {
      final response = await dio.get('/plans/$planId/days');
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data['days'] as List<dynamic>;
        return jsonData.map((json) => PlanDaysModel.fromJson(json)).toList();
      } else {
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 403) {
          throw const AuthorizationException('Forbidden');
        } else if (response.statusCode == 404) {
          throw const NotFoundException('Plan days not found');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to load plan days: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      _throwDioException(e, 'Failed to load plan days');
    }
  }

  // Get specific day's content with tasks and plan items
  Future<PlanDaysModel> getDayContent(String planId, int dayNumber) async {
    try {
      final response = await dio.get('/plans/$planId/days/$dayNumber');
      if (response.statusCode == 200) {
        return PlanDaysModel.fromJson(response.data);
      } else {
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 403) {
          throw const AuthorizationException('Forbidden');
        } else if (response.statusCode == 404) {
          throw const NotFoundException('Plan day not found');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to load plan day content: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      _throwDioException(e, 'Failed to load plan day content');
    }
  }
}
