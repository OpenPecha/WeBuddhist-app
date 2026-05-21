import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
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

/// Series repository interface.
abstract class SeriesRepositoryInterface extends Repository {
  Future<Either<Failure, List<Series>>> getSeriesList({required String language});
  Future<Either<Failure, Series>> getSeriesById(String id, {required String language});
}
