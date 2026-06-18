import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/featured_day_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';
import 'package:flutter_pecha/features/plans/data/models/response/featured_day_response.dart';

class FeaturedDayRepository implements FeaturedDayRepositoryInterface {
  final FeaturedDayRemoteDatasource featuredDayRemoteDatasource;

  FeaturedDayRepository({required this.featuredDayRemoteDatasource});

  @override
  Future<Either<Failure, FeaturedDayResponse>> getFeaturedDay({String? language}) async {
    try {
      final featuredDay = await featuredDayRemoteDatasource.fetchFeaturedDay(
        language: language,
      );
      return Right(featuredDay);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get featured day: $e'));
    }
  }

  /// Convert FeaturedDayResponse tasks to List of FeaturedDayTask
  @override
  List<FeaturedDayTask> mapToFeaturedDayTasks(FeaturedDayResponse response) {
    return response.tasks.map((task) {
      return FeaturedDayTask(
        id: task.id,
        title: task.title,
        estimatedTime: task.estimatedTime,
        displayOrder: task.displayOrder,
        subtasks: task.subtasks,
      );
    }).toList();
  }
}
