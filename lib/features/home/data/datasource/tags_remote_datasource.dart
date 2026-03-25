import 'package:dio/dio.dart';
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
        throw Exception('Failed to load tags: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error in fetchTags', e);
      throw Exception('Failed to load tags: $e');
    }
  }
}
