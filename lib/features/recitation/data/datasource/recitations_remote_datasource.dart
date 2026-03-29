import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/network/dio_error_handler.dart';
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

      final responseData = response.data as Map<String, dynamic>;
      final List<dynamic> recitationsData =
          responseData['recitations'] as List<dynamic>? ?? [];

      return recitationsData
          .map(
            (json) => RecitationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to fetch recitations');
    }
  }

  // Get saved recitations
  Future<List<RecitationModel>> fetchSavedRecitations() async {
    try {
      final response = await dio.get('/users/me/recitations');

      final responseData = response.data as Map<String, dynamic>;
      final List<dynamic> recitationsData =
          responseData['recitations'] as List<dynamic>? ?? [];
      return recitationsData
          .map(
            (json) => RecitationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to fetch saved recitations');
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

      return RecitationContentModel.fromJson(response.data);
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to fetch recitation content');
    }
  }

  // Save recitation to user's saved recitations
  Future<bool> saveRecitation(String id) async {
    try {
      final response = await dio.post(
        '/users/me/recitations',
        data: {'text_id': id},
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to save recitation');
    }
  }

  // Unsave recitation from user's saved recitations
  Future<bool> unsaveRecitation(String textId) async {
    try {
      final response = await dio.delete('/users/me/recitations/$textId');

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to unsave recitation');
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

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to update recitations order');
    }
  }
}
