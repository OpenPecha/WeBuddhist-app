import 'package:flutter_pecha/features/home/domain/usecases/get_featured_day_usecase.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_tags_usecase.dart';
import 'package:flutter_pecha/features/home/presentation/providers/tags_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/featured_day_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/home/data/datasource/tags_remote_datasource.dart';
import 'package:flutter_pecha/features/home/data/datasource/featured_day_remote_datasource.dart';

// ========== Datasource Providers ==========

/// Provider for TagsRemoteDatasource.
final tagsRemoteDatasourceProvider = Provider<TagsRemoteDatasource>((ref) {
  return TagsRemoteDatasource(
    dio: ref.watch(dioProvider),
  );
});

/// Provider for FeaturedDayRemoteDatasource.
final featuredDayRemoteDatasourceProvider = Provider<FeaturedDayRemoteDatasource>((ref) {
  return FeaturedDayRemoteDatasource(
    dio: ref.watch(dioProvider),
  );
});

// ========== Use Case Providers ==========

/// Provider for GetTagsUseCase.
final getTagsUseCaseProvider = Provider<GetTagsUseCase>((ref) {
  final repository = ref.watch(tagsRepositoryProvider);
  return GetTagsUseCase(
    ({required String language}) async => repository.getTags(language: language),
  );
});

/// Provider for GetFeaturedDayUseCase.
final getFeaturedDayUseCaseProvider = Provider<GetFeaturedDayUseCase>((ref) {
  final repository = ref.watch(featuredDayRepositoryProvider);
  return GetFeaturedDayUseCase(
    ({String? language}) async => repository.getFeaturedDay(language: language),
  );
});
