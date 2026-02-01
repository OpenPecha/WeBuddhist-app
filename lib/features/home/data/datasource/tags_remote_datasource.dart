import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:http/http.dart' as http;

class TagsRemoteDatasource {
  final http.Client client;
  final String baseUrl = dotenv.env['BASE_API_URL']!;
  final _logger = AppLogger('TagsRemoteDatasource');

  TagsRemoteDatasource({required this.client});

  /// Fetch unique tags for plans
  /// Endpoint: GET /plans/tags?language={language}
  Future<List<String>> fetchTags({required String language}) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/plans/tags',
      ).replace(queryParameters: {'language': language});

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final responseData = json.decode(decoded);
        final List<dynamic> tagsJson = responseData['tags'] as List<dynamic>;
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
