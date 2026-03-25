import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasource/tags_remote_datasource.dart';
import '../../data/repositories/tags_repository.dart';
import '../../domain/usecases/get_tags_usecase.dart';
import 'use_case_providers.dart';

/// Repository provider for tags
final tagsRepositoryProvider = Provider<TagsRepository>((ref) {
  return TagsRepository(
    tagsRemoteDatasource: TagsRemoteDatasource(
      dio: ref.watch(dioProvider),
    ),
  );
});

/// Future provider for fetching tags based on current locale
///
/// This provider uses the GetTagsUseCase to fetch tags, maintaining
/// clean architecture by routing through the use case layer.
final tagsFutureProvider = FutureProvider<List<String>>((ref) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  final useCase = ref.watch(getTagsUseCaseProvider);

  final result = useCase(GetTagsParams(language: languageCode));

  // For simplicity in this provider, we'll unwrap the Either
  // In a full implementation, you might want to handle the error case
  return result.then(
    (either) => either.fold(
      (failure) => throw Exception(failure.message),
      (tags) => tags,
    ),
  );
});
