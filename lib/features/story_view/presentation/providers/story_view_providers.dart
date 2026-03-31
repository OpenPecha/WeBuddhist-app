import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/story_view/data/datasource/story_local_datasource.dart';
import 'package:flutter_pecha/features/story_view/data/datasource/story_remote_datasource.dart';
import 'package:flutter_pecha/features/story_view/data/repositories/story_view_repository_impl.dart';
import 'package:flutter_pecha/features/story_view/domain/repositories/story_view_repository.dart';
import 'package:flutter_pecha/features/story_view/domain/usecases/story_view_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Data Layer Providers ==========

/// Provider for StoryLocalDataSource.
final storyLocalDataSourceProvider = Provider<StoryLocalDataSource>((ref) {
  return StoryLocalDataSource();
});

/// Provider for StoryRemoteDataSource.
final storyRemoteDataSourceProvider = Provider<StoryRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return StoryRemoteDataSource(dio: dio);
});

/// Provider for StoryView Repository.
final storyViewRepositoryProvider = Provider<StoryViewRepository>((ref) {
  final localDataSource = ref.watch(storyLocalDataSourceProvider);
  final remoteDataSource = ref.watch(storyRemoteDataSourceProvider);

  return StoryViewRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

// ========== Use Case Providers ==========

/// Provider for GetStoriesUseCase.
final getStoriesUseCaseProvider = Provider<GetStoriesUseCase>((ref) {
  final repository = ref.watch(storyViewRepositoryProvider);
  return GetStoriesUseCase(repository);
});

/// Provider for GetStoriesByTypeUseCase.
final getStoriesByTypeUseCaseProvider = Provider<GetStoriesByTypeUseCase>((ref) {
  final repository = ref.watch(storyViewRepositoryProvider);
  return GetStoriesByTypeUseCase(repository);
});

/// Provider for MarkStoryAsViewedUseCase.
final markStoryAsViewedUseCaseProvider = Provider<MarkStoryAsViewedUseCase>((ref) {
  final repository = ref.watch(storyViewRepositoryProvider);
  return MarkStoryAsViewedUseCase(repository);
});

/// Provider for GetViewedStoryIdsUseCase.
final getViewedStoryIdsUseCaseProvider = Provider<GetViewedStoryIdsUseCase>((ref) {
  final repository = ref.watch(storyViewRepositoryProvider);
  return GetViewedStoryIdsUseCase(repository);
});
