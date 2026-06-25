import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';

class BookmarkRepository {
  final BookmarkRemoteDatasource remoteDatasource;

  BookmarkRepository({required this.remoteDatasource});

  Future<Either<Failure, bool>> createBookmark({
    required BookmarkType type,
    required String sourceId,
  }) async {
    try {
      final result = await remoteDatasource.createBookmark(
        type: type,
        sourceId: sourceId,
      );
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to create bookmark'));
    }
  }
}
