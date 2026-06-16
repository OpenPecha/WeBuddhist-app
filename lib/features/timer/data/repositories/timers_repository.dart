import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/timer/data/datasource/timers_remote_datasource.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/domain/repositories/timers_repository.dart';

class TimersRepository implements TimersRepositoryInterface {
  TimersRepository({required this.remote});

  final TimersRemoteDatasource remote;

  @override
  Future<Either<Failure, void>> stopUserTimer({
    required String timerId,
    required int durationMs,
  }) async {
    try {
      await remote.stopUserTimer(timerId: timerId, durationMs: durationMs);
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to stop timer: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PresetTimer>>> getPresetTimers({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final timers = await remote.fetchPresetTimers(skip: skip, limit: limit);
      return Right(timers.map((t) => t.toEntity()).toList());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get preset timers: $e'));
    }
  }
}
