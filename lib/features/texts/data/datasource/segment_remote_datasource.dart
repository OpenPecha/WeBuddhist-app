import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary_response.dart';
import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation_response.dart';

class SegmentRemoteDatasource {
  final Dio dio;

  SegmentRemoteDatasource({required this.dio});

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

  // get all segment commentaries
  Future<SegmentCommentaryResponse> getSegmentCommentaries(
    String segmentId,
  ) async {
    try {
      final response = await dio.get('/segments/$segmentId/commentaries');

      if (response.statusCode == 200) {
        return SegmentCommentaryResponse.fromJson(response.data);
      } else {
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 404) {
          throw const NotFoundException('Segment commentaries not found');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to load segment commentaries: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      _throwDioException(e, 'Failed to load segment commentaries');
    }
  }

  // get all translations of a segment
  Future<List<SegmentTranslationResponse>> getSegmentTranslations(
    String segmentId,
  ) async {
    try {
      final response = await dio.get('/segments/$segmentId/translations');

      if (response.statusCode == 200) {
        final List<dynamic> jsonMap = response.data as List<dynamic>;
        return jsonMap
            .map((e) => SegmentTranslationResponse.fromJson(e))
            .toList();
      } else {
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 404) {
          throw const NotFoundException('Segment translations not found');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to load segment translations: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      _throwDioException(e, 'Failed to load segment translations');
    }
  }
}
