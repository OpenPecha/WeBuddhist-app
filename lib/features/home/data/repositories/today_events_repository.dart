import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/today_events_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/entities/today_event.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';

class TodayEventsRepository implements TodayEventsRepositoryInterface {
  final TodayEventsRemoteDatasource remote;

  TodayEventsRepository({required this.remote});

  @override
  Future<Either<Failure, List<TodayEvent>>> getTodayEvents({
    required String language,
  }) async {
    try {
      final models = await remote.fetchTodayEvents(language: language);
      return Right(models.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get today events: $e'));
    }
  }
}
