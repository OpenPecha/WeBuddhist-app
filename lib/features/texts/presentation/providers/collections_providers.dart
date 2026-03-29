import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/collections_usecases.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final collectionsListFutureProvider = FutureProvider.autoDispose((ref) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  final useCase = ref.watch(getCollectionsUseCaseProvider);
  return useCase(CollectionsParams(language: languageCode));
});

final collectionsCategoryFutureProvider = FutureProvider.autoDispose.family((
  ref,
  String parentId,
) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  final useCase = ref.watch(getCollectionsUseCaseProvider);
  return useCase(CollectionsParams(
    language: languageCode,
    parentId: parentId,
  ));
});
