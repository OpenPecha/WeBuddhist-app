import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/repositories/bookmark_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(
    remoteDatasource: BookmarkRemoteDatasource(
      dio: ref.watch(dioProvider),
    ),
  );
});

class CreateBookmarkParams {
  final BookmarkType type;
  final String sourceId;

  const CreateBookmarkParams({required this.type, required this.sourceId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateBookmarkParams &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          sourceId == other.sourceId;

  @override
  int get hashCode => Object.hash(type, sourceId);
}

final createBookmarkProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, CreateBookmarkParams>((ref, params) {
  return ref.watch(bookmarkRepositoryProvider).createBookmark(
        type: params.type,
        sourceId: params.sourceId,
      );
});
