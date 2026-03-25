import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/story_view/data/datasource/story_local_datasource.dart';
import 'package:flutter_pecha/features/story_view/data/datasource/story_remote_datasource.dart';
import 'package:flutter_pecha/features/story_view/data/models/story_model.dart';
import 'package:flutter_pecha/features/story_view/domain/entities/story.dart';
import 'package:flutter_pecha/features/story_view/domain/repositories/story_view_repository.dart';

/// Story view repository implementation.
class StoryViewRepositoryImpl implements StoryViewRepository {
  final StoryLocalDataSource _localDataSource;
  final StoryRemoteDataSource _remoteDataSource;

  StoryViewRepositoryImpl({
    required StoryLocalDataSource localDataSource,
    required StoryRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<Story>>> getStories() async {
    try {
      // Try to get from cache first
      final cachedModels = await _localDataSource.getCachedStories();

      // Always fetch from remote to get latest data
      final remoteModels = await _remoteDataSource.getStories();

      // Cache the remote data
      await _localDataSource.cacheStories(remoteModels);

      final stories = remoteModels.map((model) => model.toEntity()).toList();
      return Right(stories);
    } catch (e) {
      // If remote fetch fails, try to return cached data
      try {
        final cachedModels = await _localDataSource.getCachedStories();
        if (cachedModels.isNotEmpty) {
          final stories = cachedModels.map((model) => model.toEntity()).toList();
          return Right(stories);
        }
      } catch (_) {}

      return Left(NetworkFailure('Failed to load stories: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Story>>> getStoriesByType(StoryType type) async {
    try {
      final remoteModels = await _remoteDataSource.getStoriesByType(type.name);
      final stories = remoteModels.map((model) => model.toEntity()).toList();
      return Right(stories);
    } catch (e) {
      return Left(NetworkFailure('Failed to load stories by type: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsViewed(String storyId) async {
    try {
      await _localDataSource.markAsViewed(storyId);
      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to mark story as viewed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getViewedStoryIds() async {
    try {
      final viewedIds = await _localDataSource.getViewedStoryIds();
      return Right(viewedIds);
    } catch (e) {
      return Left(CacheFailure('Failed to load viewed story IDs: $e'));
    }
  }
}
