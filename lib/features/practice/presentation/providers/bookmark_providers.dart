import 'package:flutter_pecha/core/di/core_providers.dart';
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
