import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:http/http.dart' as http;

/// Data source for resolving segment URLs from pecha segment IDs
class SegmentUrlResolverDatasource {
  final http.Client client;

  SegmentUrlResolverDatasource({required this.client});

  /// Resolves a pecha segment ID to text_id and segment_id
  /// 
  /// Calls GET /api/v1/search/chat/{pecha_segment_id}
  /// Returns a map with 'textId' and 'segmentId'
  Future<Map<String, String>> resolveSegmentUrl(String pechaSegmentId) async {
    try {
      final baseUrl = dotenv.env['BASE_API_URL'];
      if (baseUrl == null || baseUrl.isEmpty) {
        throw const ServerException('BASE_API_URL is not configured');
      }

      final url = Uri.parse('$baseUrl/search/chat/$pechaSegmentId');

      final response = await client.get(
        url,
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Response is a JSON object: {"text_id": "...", "segment_id": "..."}
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
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
