import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';
import '../models/author/author_model.dart';

class AuthorRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('AuthorRemoteDatasource');

  AuthorRemoteDatasource({required this.dio});

  Future<AuthorModel> getAuthorById(String authorId) async {
    try {
      final response = await dio.get('/authors/$authorId');

      if (response.statusCode == 200) {
        return AuthorModel.fromJson(response.data);
      } else {
        _logger.error('Error to load author: ${response.statusCode}');
        throw Exception('Error to load author: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Failed to load author', e);
      throw Exception('Failed to load author: $e');
    }
  }

  // gets plans by author id
  Future<List<PlansModel>> getPlansByAuthorId(String authorId) async {
    try {
      final response = await dio.get('/authors/$authorId/plans');
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data['plans'] as List<dynamic>;
        return jsonData
            .map((json) => PlansModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _logger.error('Failed to load plans: ${response.statusCode}');
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Failed to load plans', e);
      throw Exception('Failed to load plans: $e');
    }
  }
}
