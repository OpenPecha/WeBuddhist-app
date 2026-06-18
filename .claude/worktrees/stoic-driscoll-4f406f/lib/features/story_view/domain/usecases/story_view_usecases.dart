import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/story_view/domain/entities/story.dart';
import 'package:flutter_pecha/features/story_view/domain/repositories/story_view_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Get stories use case.
class GetStoriesUseCase extends UseCase<List<Story>, NoParams> {
  final StoryViewRepository _repository;

  GetStoriesUseCase(this._repository);

  @override
  Future<Either<Failure, List<Story>>> call(NoParams params) async {
    return await _repository.getStories();
  }
}

/// Get stories by type use case.
class GetStoriesByTypeUseCase extends UseCase<List<Story>, GetStoriesByTypeParams> {
  final StoryViewRepository _repository;

  GetStoriesByTypeUseCase(this._repository);

  @override
  Future<Either<Failure, List<Story>>> call(GetStoriesByTypeParams params) async {
    return await _repository.getStoriesByType(params.type);
  }
}

class GetStoriesByTypeParams {
  final StoryType type;
  const GetStoriesByTypeParams({required this.type});
}

/// Mark story as viewed use case.
class MarkStoryAsViewedUseCase extends UseCase<void, MarkStoryAsViewedParams> {
  final StoryViewRepository _repository;

  MarkStoryAsViewedUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(MarkStoryAsViewedParams params) async {
    if (params.storyId.isEmpty) {
      return const Left(ValidationFailure('Story ID cannot be empty'));
    }
    return await _repository.markAsViewed(params.storyId);
  }
}

class MarkStoryAsViewedParams {
  final String storyId;
  const MarkStoryAsViewedParams({required this.storyId});
}

/// Get viewed story IDs use case.
class GetViewedStoryIdsUseCase extends UseCase<List<String>, NoParams> {
  final StoryViewRepository _repository;

  GetViewedStoryIdsUseCase(this._repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    return await _repository.getViewedStoryIds();
  }
}

