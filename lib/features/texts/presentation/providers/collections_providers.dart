import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/texts/data/datasource/collections_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/collections_repository.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';

final collectionsRepositoryProvider = Provider(
  (ref) => CollectionsRepository(
    remoteDatasource: CollectionsRemoteDatasource(
      dio: ref.watch(dioProvider),
    ),
  ),
);

final collectionsListFutureProvider = FutureProvider.autoDispose((ref) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  return ref
      .watch(collectionsRepositoryProvider)
      .getCollections(language: languageCode);
});

final collectionsCategoryFutureProvider = FutureProvider.autoDispose.family((
  ref,
  String parentId,
) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  return ref
      .watch(collectionsRepositoryProvider)
      .getCollections(language: languageCode, parentId: parentId);
});
