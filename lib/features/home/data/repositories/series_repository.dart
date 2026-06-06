import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/series_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';

class SeriesRepository implements SeriesRepositoryInterface {
  final SeriesRemoteDatasource remote;

  SeriesRepository({required this.remote});

  @override
  Future<Either<Failure, List<Series>>> getSeriesList({
    required String language,
  }) async {
    try {
      final models = await remote.fetchSeriesList(language: language);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load series: $e'));
    }
  }

  @override
  Future<Either<Failure, Series>> getSeriesById(
    String id, {
    required String language,
  }) async {
    try {
      final model = await remote.fetchSeriesById(id, language: language);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load series: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> enrollInSeries(String seriesId) async {
    try {
      await remote.enrollInSeries(seriesId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to enroll in series: $e'));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getUserSeriesEnrollments() async {
    try {
      final ids = await remote.fetchUserSeriesEnrollments();
      return Right(ids);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load user series enrollments: $e'));
    }
  }
}
