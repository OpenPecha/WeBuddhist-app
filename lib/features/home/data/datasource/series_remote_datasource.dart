import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/home/data/models/series_model.dart';

class SeriesRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('SeriesRemoteDatasource');

  SeriesRemoteDatasource({required this.dio});

  /// Endpoint: GET /series?language={language}
  Future<List<SeriesModel>> fetchSeriesList({required String language}) async {
    try {
      final response = await dio.get(
        '/series',
        queryParameters: {'language': language},
      );

      if (response.statusCode == 200) {
        final List<dynamic> seriesJson =
            (response.data['series'] as List<dynamic>?) ?? [];
        return seriesJson
            .map((s) => SeriesModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        _logger.error('Failed to load series list: ${response.statusCode}');
        throw _statusToException(response.statusCode, 'Failed to load series');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchSeriesList', e);
      throw _dioToException(e, 'Failed to load series');
    }
  }

  /// Endpoint: GET /series/{id}?language={language}
  Future<SeriesModel> fetchSeriesById(
    String id, {
    required String language,
  }) async {
    try {
      final response = await dio.get(
        '/series/$id',
        queryParameters: {'language': language},
      );

      if (response.statusCode == 200) {
        return SeriesModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        _logger.error('Failed to load series $id: ${response.statusCode}');
        throw _statusToException(response.statusCode, 'Failed to load series');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchSeriesById', e);
      throw _dioToException(e, 'Failed to load series');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Series not found');
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
