import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

class StreakRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('StreakRemoteDatasource');

  StreakRemoteDatasource({required this.dio});

  Future<int> fetchStreak() async {
    try {
      final response = await dio.get('/users/me/streak');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return (data['streak'] as num?)?.toInt() ?? 0;
      }

      _logger.error('Failed to load streak: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to load streak');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchStreak', e);
      throw _dioToException(e, 'Failed to load streak');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Streak not found');
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
