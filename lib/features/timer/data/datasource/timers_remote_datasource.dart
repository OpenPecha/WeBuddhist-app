import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/timer/data/models/preset_timer_model.dart';

class TimersRemoteDatasource {
  TimersRemoteDatasource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('TimersRemoteDatasource');

  Future<List<PresetTimerModel>> fetchPresetTimers({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/timers',
        queryParameters: {'skip': skip, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = TimersResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return data.timers;
      }

      _logger.error('Failed to load timers: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to load timers');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchPresetTimers', e);
      throw _dioToException(e, 'Failed to load timers');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Timers not found');
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
