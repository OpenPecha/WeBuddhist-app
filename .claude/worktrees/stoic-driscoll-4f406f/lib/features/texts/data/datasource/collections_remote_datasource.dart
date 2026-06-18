import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/texts/data/models/collections/collections_response.dart';

class CollectionsRemoteDatasource {
  final Dio dio;

  CollectionsRemoteDatasource({required this.dio});

  Future<CollectionsResponse> fetchCollections({
    String? parentId,
    String? language,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await dio.get(
        '/collections',
        queryParameters: {
          if (parentId != null) 'parent_id': parentId,
          if (language != null) 'language': language,
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        return CollectionsResponse.fromJson(response.data);
      } else {
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 403) {
          throw const AuthorizationException('Forbidden');
        } else if (response.statusCode == 404) {
          throw const NotFoundException('Collections not found');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to load collections: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
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
          throw const NotFoundException('Collections not found');
        } else if (statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to load collections: $statusCode');
        }
      } else {
        throw const NetworkException('Network error');
      }
    }
  }
}
