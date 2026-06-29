import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';

class BookmarkRepository {
  final BookmarkRemoteDatasource remoteDatasource;

  BookmarkRepository({required this.remoteDatasource});

  Future<Either<Failure, bool>> createBookmark({
    required BookmarkType type,
    required String sourceId,
    String? name,
  }) async {
    try {
      final result = await remoteDatasource.createBookmark(
        type: type,
        sourceId: sourceId,
        name: name,
      );
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to create bookmark'));
    }
  }

  Future<Either<Failure, List<BookmarkDTO>>> fetchBookmarks({
    String? language,
  }) async {
    try {
      final result = await remoteDatasource.fetchBookmarks(language: language);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to load bookmarks'));
    }
  }

  Future<Either<Failure, BookmarkExistsResult>> checkBookmarkExists({
    required String sourceId,
    BookmarkType? type,
  }) async {
    try {
      final result = await remoteDatasource.checkBookmarkExists(
        sourceId: sourceId,
        type: type,
      );
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to check bookmark status'),
      );
    }
  }

  Future<Either<Failure, Unit>> deleteBookmark(String bookmarkId) async {
    try {
      await remoteDatasource.deleteBookmark(bookmarkId);
      return const Right(unit);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to remove bookmark'));
    }
  }
}
