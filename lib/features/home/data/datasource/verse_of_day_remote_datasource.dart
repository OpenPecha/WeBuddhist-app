import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/home/data/models/verse_of_day_model.dart';

class VerseOfDayRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('VerseOfDayRemoteDatasource');

  static const _baseUrl = 'https://api.webuddhist.com/api/v1';

  VerseOfDayRemoteDatasource({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

  Future<VerseOfDayModel> fetchVerseOfDay({required String language}) async {
    try {
      final response = await dio.get(
        '$_baseUrl/verse-of-day/today',
        queryParameters: {'lang': language},
      );

      if (response.statusCode == 200) {
        return VerseOfDayModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        _logger.error('Failed to load verse of day: ${response.statusCode}');
        throw _statusToException(
          response.statusCode,
          'Failed to load verse of day',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchVerseOfDay', e);
      throw _dioToException(e, 'Failed to load verse of day');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Verse of day not found');
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
