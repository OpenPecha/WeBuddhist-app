import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/story_view/domain/entities/story.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Story view repository interface.
abstract class StoryViewRepository extends Repository {
  /// Get all active stories.
  Future<Either<Failure, List<Story>>> getStories();

  /// Get stories by type.
  Future<Either<Failure, List<Story>>> getStoriesByType(StoryType type);

  /// Mark story as viewed.
  Future<Either<Failure, void>> markAsViewed(String storyId);

  /// Get viewed story IDs.
  Future<Either<Failure, List<String>>> getViewedStoryIds();
}
