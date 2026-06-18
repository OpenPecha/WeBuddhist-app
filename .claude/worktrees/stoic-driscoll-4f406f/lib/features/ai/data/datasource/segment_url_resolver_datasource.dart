import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';

/// Data source for resolving segment URLs from pecha segment IDs.
///
/// This datasource uses the main API Dio client which:
/// - Uses BASE_API_URL as base URL
/// - Automatically adds auth tokens via interceptors when needed
class SegmentUrlResolverDatasource {
  final Dio _dio;

  SegmentUrlResolverDatasource({required Dio dio}) : _dio = dio;

  /// Resolves a pecha segment ID to text_id and segment_id
  ///
  /// Calls GET /api/v1/search/chat/{pecha_segment_id}
  /// Returns a map with 'textId' and 'segmentId'
  Future<Map<String, String>> resolveSegmentUrl(String pechaSegmentId) async {
    try {
      final response = await _dio.get(
        '/search/chat/$pechaSegmentId',
        options: Options(headers: {'accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        // Response is a JSON object: {"text_id": "...", "segment_id": "..."}
        final jsonData = response.data as Map<String, dynamic>;

        final textId = jsonData['text_id'] as String?;
        final segmentId = jsonData['segment_id'] as String?;

        if (textId == null || textId.isEmpty) {
          throw const ServerException('Invalid response: missing text_id');
        }

        return {
          'textId': textId,
          'segmentId': segmentId ?? '',
        };
      } else if (response.statusCode == 404) {
        throw const ServerException('Segment not found');
      } else {
        throw ServerException(
          'Failed to resolve segment URL: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Network error: ${e.toString()}');
    }
  }
}
