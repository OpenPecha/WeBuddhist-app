import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasource/tags_remote_datasource.dart';
import '../repositories/tags_repository.dart';

/// Repository provider for tags
final tagsRepositoryProvider = Provider<TagsRepository>((ref) {
  return TagsRepository(
    tagsRemoteDatasource: TagsRemoteDatasource(
      client: ref.watch(apiClientProvider),
    ),
  );
});

/// Future provider for fetching tags based on current locale
final tagsFutureProvider = FutureProvider<List<String>>((ref) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  return ref.watch(tagsRepositoryProvider).getTags(language: languageCode);
});
