import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/more/data/models/user_stats_model.dart';

class UserStatsRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('UserStatsRemoteDatasource');

  UserStatsRemoteDatasource({required this.dio});

  Future<UserStatsModel> fetchUserStats() async {
    try {
      final response = await dio.get('/users/me/stats');

      if (response.statusCode == 200) {
        return UserStatsModel.fromJson(response.data as Map<String, dynamic>);
      }

      _logger.error('Failed to load user stats: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to load user stats');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchUserStats', e);
      throw _dioToException(e, 'Failed to load user stats');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('User stats not found');
    } else if (statusCode == 429) {
      return const RateLimitException('Too many requests');
    } else {
      return ServerException('$label: $statusCode');
    }
  }

  Exception _dioToException(DioException e, String label) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Connection timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      return const NetworkException('No internet connection');
    } else if (e.response?.statusCode != null) {
      return _statusToException(e.response!.statusCode, label);
    } else {
      return const NetworkException('Network error');
    }
  }
}
