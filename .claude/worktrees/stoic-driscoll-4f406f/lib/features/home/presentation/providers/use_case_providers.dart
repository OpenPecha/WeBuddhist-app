import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/home/data/datasource/featured_day_remote_datasource.dart';
import 'package:flutter_pecha/features/home/data/datasource/tags_remote_datasource.dart';
import 'package:flutter_pecha/features/home/data/repositories/featured_day_repository.dart';
import 'package:flutter_pecha/features/home/data/repositories/tags_repository.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_featured_day_usecase.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_tags_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============ Datasources ============

final featuredDayRemoteDatasourceProvider = Provider<FeaturedDayRemoteDatasource>((ref) {
  return FeaturedDayRemoteDatasource(dio: ref.watch(dioProvider));
});

final tagsRemoteDatasourceProvider = Provider<TagsRemoteDatasource>((ref) {
  return TagsRemoteDatasource(dio: ref.watch(dioProvider));
});

// ============ Domain Repositories ============

final featuredDayDomainRepositoryProvider = Provider<FeaturedDayRepositoryInterface>((ref) {
  return FeaturedDayRepository(
    featuredDayRemoteDatasource: ref.watch(featuredDayRemoteDatasourceProvider),
  );
});

final tagsDomainRepositoryProvider = Provider<TagsRepositoryInterface>((ref) {
  return TagsRepository(
    tagsRemoteDatasource: ref.watch(tagsRemoteDatasourceProvider),
  );
});

// ============ Use Cases ============

final getFeaturedDayUseCaseProvider = Provider<GetFeaturedDayUseCase>((ref) {
  final repository = ref.watch(featuredDayDomainRepositoryProvider);
  return GetFeaturedDayUseCase(repository.getFeaturedDay);
});

final getTagsUseCaseProvider = Provider<GetTagsUseCase>((ref) {
  final repository = ref.watch(tagsDomainRepositoryProvider);
  return GetTagsUseCase(repository.getTags);
});
