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
