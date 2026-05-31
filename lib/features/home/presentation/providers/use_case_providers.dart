import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/home/data/datasource/featured_day_remote_datasource.dart';
import 'package:flutter_pecha/features/home/data/datasource/series_remote_datasource.dart';
import 'package:flutter_pecha/features/home/data/datasource/tags_remote_datasource.dart';
import 'package:flutter_pecha/features/home/data/repositories/featured_day_repository.dart';
import 'package:flutter_pecha/features/home/data/repositories/series_repository.dart';
import 'package:flutter_pecha/features/home/data/repositories/tags_repository.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';
import 'package:flutter_pecha/features/home/domain/usecases/enroll_in_series_usecase.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_featured_day_usecase.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_series_by_id_usecase.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_series_list_usecase.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_tags_usecase.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_user_series_enrollments_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============ Datasources ============

final featuredDayRemoteDatasourceProvider = Provider<FeaturedDayRemoteDatasource>((ref) {
  return FeaturedDayRemoteDatasource(dio: ref.watch(dioProvider));
});

final tagsRemoteDatasourceProvider = Provider<TagsRemoteDatasource>((ref) {
  return TagsRemoteDatasource(dio: ref.watch(dioProvider));
});

final seriesRemoteDatasourceProvider = Provider<SeriesRemoteDatasource>((ref) {
  return SeriesRemoteDatasource(dio: ref.watch(dioProvider));
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

final seriesDomainRepositoryProvider = Provider<SeriesRepositoryInterface>((ref) {
  return SeriesRepository(
    remote: ref.watch(seriesRemoteDatasourceProvider),
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

final getSeriesListUseCaseProvider = Provider<GetSeriesListUseCase>((ref) {
  final repository = ref.watch(seriesDomainRepositoryProvider);
  return GetSeriesListUseCase(repository.getSeriesList);
});

final getSeriesByIdUseCaseProvider = Provider<GetSeriesByIdUseCase>((ref) {
  final repository = ref.watch(seriesDomainRepositoryProvider);
  return GetSeriesByIdUseCase(repository.getSeriesById);
});

final enrollInSeriesUseCaseProvider = Provider<EnrollInSeriesUseCase>((ref) {
  final repository = ref.watch(seriesDomainRepositoryProvider);
  return EnrollInSeriesUseCase(repository.enrollInSeries);
});

final getUserSeriesEnrollmentsUseCaseProvider =
    Provider<GetUserSeriesEnrollmentsUseCase>((ref) {
  final repository = ref.watch(seriesDomainRepositoryProvider);
  return GetUserSeriesEnrollmentsUseCase(repository.getUserSeriesEnrollments);
});
