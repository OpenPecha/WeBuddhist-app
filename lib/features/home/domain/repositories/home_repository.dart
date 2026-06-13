import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/features/plans/data/models/response/featured_day_response.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Featured day repository interface.
abstract class FeaturedDayRepositoryInterface extends Repository {
  Future<Either<Failure, FeaturedDayResponse>> getFeaturedDay({String? language});

  /// Convert FeaturedDayResponse tasks to List of FeaturedDayTask
  List<FeaturedDayTask> mapToFeaturedDayTasks(FeaturedDayResponse response);
}

/// Tags repository interface.
abstract class TagsRepositoryInterface extends Repository {
  Future<Either<Failure, List<String>>> getTags({required String language});
}

/// Verse of the Day repository interface.
abstract class VerseOfDayRepositoryInterface extends Repository {
  Future<Either<Failure, VerseOfDay>> getVerseOfDay({required String language});
}

/// Series repository interface.
abstract class SeriesRepositoryInterface extends Repository {
  Future<Either<Failure, List<Series>>> getSeriesList({required String language});
  Future<Either<Failure, Series>> getSeriesById(String id, {required String language});

  /// Enrolls the authenticated user in the given series.
  /// Backend auto-enrolls the user in all plans that belong to the series.
  Future<Either<Failure, Unit>> enrollInSeries(String seriesId);

  /// Returns the set of series IDs the authenticated user is enrolled in.
  /// Used to suppress the Enroll button for already-enrolled series.
  Future<Either<Failure, Set<String>>> getUserSeriesEnrollments();
}
