import 'package:dio/dio.dart';

/// Bookmark types supported by the API.
enum BookmarkType { text, verse }

extension BookmarkTypeExt on BookmarkType {
  String get value {
    switch (this) {
      case BookmarkType.text:
        return 'TEXT';
      case BookmarkType.verse:
        return 'VERSE';
    }
  }
}

/// Remote datasource for the bookmark endpoints.
///
/// Error handling is centralised in ErrorInterceptor, which converts
/// DioExceptions to typed AppExceptions that propagate to the repository layer.
class BookmarkRemoteDatasource {
  final Dio dio;

  BookmarkRemoteDatasource({required this.dio});

  /// POST /users/me/bookmarks
  ///
  /// [type]     – one of [BookmarkType.text] or [BookmarkType.verse]
  /// [sourceId] – text ID (TEXT) or segment ID (VERSE)
  Future<bool> createBookmark({
    required BookmarkType type,
    required String sourceId,
  }) async {
    final response = await dio.post(
      '/users/me/bookmarks',
      data: {
        'type': type.value,
        'source_id': sourceId,
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
