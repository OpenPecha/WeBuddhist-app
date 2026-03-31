import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

class ShareRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('ShareRemoteDatasource');

  ShareRemoteDatasource({required this.dio});

  // POST request to share a short url
  Future<String> getShareUrl({
    required String textId,
    required String segmentId,
    required String language,
  }) async {
    try {
      final response = await dio.post(
        '/share',
        data: {
          'logo': false,
          'segment_id': segmentId,
          'text_id': textId,
          'content_index': 0,
          'language': language,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        final shortUrl = data['shortUrl'];
        if (shortUrl == null || shortUrl.toString().isEmpty) {
          throw const ServerException('Missing or empty shortUrl in response');
        }

        return shortUrl.toString();
      } else if (response.statusCode == 404) {
        throw const NotFoundException('Share endpoint not found');
      } else if (response.statusCode == 401) {
        throw const AuthenticationException('Unauthorized');
      } else if (response.statusCode == 429) {
        throw const RateLimitException('Too many requests');
      } else if (response.statusCode != null && response.statusCode! >= 500) {
        throw ServerException('Server error: ${response.statusCode}');
      } else {
        throw ServerException('HTTP error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.sendTimeout) {
        throw const NetworkException('Request timeout');
      }
      _logger.error('Network error', e);
      throw const NetworkException('Network error');
    }
  }
}
