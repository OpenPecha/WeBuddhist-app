import 'package:dio/dio.dart';

/// Bookmark types supported by the API.
enum BookmarkType { text, verse, timer }

extension BookmarkTypeExt on BookmarkType {
  String get value {
    switch (this) {
      case BookmarkType.text:
        return 'TEXT';
      case BookmarkType.verse:
        return 'VERSE';
      case BookmarkType.timer:
        return 'TIMER';
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
  /// [type]     – one of [BookmarkType.text], [BookmarkType.verse], or [BookmarkType.timer]
  /// [sourceId] – text ID (TEXT), segment ID (VERSE), or timer ID (TIMER)
  ///
  /// A 409 response means the item is already bookmarked, which is treated as
  /// success so callers see "Bookmark saved" regardless of duplication.
  Future<bool> createBookmark({
    required BookmarkType type,
    required String sourceId,
  }) async {
    try {
      final response = await dio.post(
        '/users/me/bookmarks',
        data: {
          'type': type.value,
          'source_id': sourceId,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) return true;
      rethrow;
    }
  }
}
