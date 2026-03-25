import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_content_model.dart';

class RecitationsQueryParams {
  final String? language;
  final String? search;

  RecitationsQueryParams({this.language, this.search});

  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {};
    if (language != null) params['language'] = language!;
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    return params;
  }
}

class RecitationsRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('RecitationsRemoteDatasource');

  RecitationsRemoteDatasource({required this.dio});

  // Get all recitations
  Future<List<RecitationModel>> fetchRecitations({
    RecitationsQueryParams? queryParams,
  }) async {
    try {
      final response = await dio.get(
        '/recitations',
        queryParameters: queryParams?.toQueryParams(),
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        // Parse the nested "recitations" array from the response
        final List<dynamic> recitationsData =
            responseData['recitations'] as List<dynamic>? ?? [];

        return recitationsData
            .map(
              (json) => RecitationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        _logger.error('Failed to fetch recitations: ${response.statusCode}');
        throw Exception('Failed to fetch recitations: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error fetching recitations', e);
      throw Exception('Error fetching recitations: $e');
    }
  }

  // Get saved recitations
  Future<List<RecitationModel>> fetchSavedRecitations() async {
    try {
      final response = await dio.get('/users/me/recitations');
      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final List<dynamic> recitationsData =
            responseData['recitations'] as List<dynamic>? ?? [];
        return recitationsData
            .map(
              (json) => RecitationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        _logger.error(
          'Failed to fetch saved recitations: ${response.statusCode}',
        );
        throw Exception(
          'Failed to fetch saved recitations: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.error('Error fetching saved recitations', e);
      throw Exception('Error fetching saved recitations: $e');
    }
  }

  // Get recitation content by text ID
  Future<RecitationContentModel> fetchRecitationContent(
    String id, {
    required String language,
    List<String>? recitation,
    List<String>? translations,
    List<String>? transliterations,
    List<String>? adaptations,
  }) async {
    try {
      // Build request body according to API spec
      final requestBody = <String, dynamic>{
        'language': language,
        'recitation': recitation ?? [],
        'translations': translations ?? [],
        'transliterations': transliterations ?? [],
        'adaptations': adaptations ?? [],
      };

      _logger.debug('Fetching recitation content for ID: $id');
      _logger.debug('Request body: $requestBody');

      final response = await dio.post(
        '/recitations/$id',
        data: requestBody,
      );

      if (response.statusCode == 200) {
        return RecitationContentModel.fromJson(response.data);
      } else {
        _logger.error(
          'Failed to fetch recitation content: ${response.statusCode}',
        );
        throw Exception(
          'Failed to fetch recitation content: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.error('Error fetching recitation content', e);
      throw Exception('Error fetching recitation content: $e');
    }
  }

  // Save recitation to user's saved recitations
  Future<bool> saveRecitation(String id) async {
    try {
      final response = await dio.post(
        '/users/me/recitations',
        data: {'text_id': id},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _logger.error('Failed to save recitation', e);
      throw Exception('Failed to save recitation: $e');
    }
  }

  // Unsave recitation from user's saved recitations
  Future<bool> unsaveRecitation(String textId) async {
    try {
      final response = await dio.delete('/users/me/recitations/$textId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _logger.error('Failed to unsave recitation', e);
      throw Exception('Failed to unsave recitation: $e');
    }
  }

  // Update recitations order
  Future<bool> updateRecitationsOrder(
    List<Map<String, dynamic>> recitations,
  ) async {
    try {
      _logger.debug('Updating recitations order: $recitations');
      final response = await dio.put(
        '/users/me/recitations/order',
        data: {'recitations': recitations},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        _logger.error(
          'Failed to update recitations order: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      _logger.error('Failed to update recitations order', e);
      throw Exception('Failed to update recitations order: $e');
    }
  }
}
