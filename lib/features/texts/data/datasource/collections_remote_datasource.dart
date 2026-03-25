import 'package:dio/dio.dart';
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
      throw Exception('Failed to load collections');
    }
  }
}
