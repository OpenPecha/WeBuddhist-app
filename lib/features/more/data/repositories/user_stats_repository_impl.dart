import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/more/data/datasource/user_stats_remote_datasource.dart';
import 'package:flutter_pecha/features/more/domain/entities/mantra_count.dart';
import 'package:flutter_pecha/features/more/domain/entities/series_day_completed.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/domain/repositories/user_stats_repository.dart';
import 'package:flutter_pecha/features/more/domain/usecases/get_mantra_counts_usecase.dart';
import 'package:flutter_pecha/features/more/domain/usecases/get_series_day_completed_usecase.dart';

class UserStatsRepositoryImpl implements UserStatsRepositoryInterface {
  final UserStatsRemoteDatasource remote;

  UserStatsRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, MantraCountPage>> getMantraCounts(
    GetMantraCountsParams params,
  ) async {
    try {
      final model = await remote.fetchMantraCounts(
        language: params.language,
        skip: params.skip,
        limit: params.limit,
      );
      return Right(model.toEntity());
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
      return Left(UnknownFailure('Failed to get mantra counts: $e'));
    }
  }

  @override
  Future<Either<Failure, SeriesDayCompletedPage>> getSeriesDayCompleted(
    GetSeriesDayCompletedParams params,
  ) async {
    try {
      final model = await remote.fetchSeriesDayCompleted(
        language: params.language,
        skip: params.skip,
        limit: params.limit,
      );
      return Right(model.toEntity());
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
      return Left(UnknownFailure('Failed to get series day completed: $e'));
    }
  }

  @override
  Future<Either<Failure, UserStats>> getUserStats() async {
    try {
      final model = await remote.fetchUserStats();
      return Right(model.toEntity());
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
      return Left(UnknownFailure('Failed to get user stats: $e'));
    }
  }
}
