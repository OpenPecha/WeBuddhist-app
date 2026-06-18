import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

class TagsRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('TagsRemoteDatasource');

  TagsRemoteDatasource({required this.dio});

  /// Fetch unique tags for plans
  /// Endpoint: GET /plans/tags?language={language}
  Future<List<String>> fetchTags({required String language}) async {
    try {
      final response = await dio.get(
        '/plans/tags',
        queryParameters: {'language': language},
      );

      if (response.statusCode == 200) {
        final List<dynamic> tagsJson = response.data['tags'] as List<dynamic>;
        return tagsJson.map((tag) => tag.toString()).toList();
      } else {
        _logger.error('Failed to load tags: ${response.statusCode}');
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 404) {
          throw const NotFoundException('Tags not found');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to load tags: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchTags', e);
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
        } else if (statusCode == 404) {
          throw const NotFoundException('Tags not found');
        } else if (statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to load tags: $statusCode');
        }
      } else {
        throw const NetworkException('Network error');
      }
    }
  }
}
