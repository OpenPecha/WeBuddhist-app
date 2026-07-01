import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_local_datasource.dart';
import 'package:flutter_pecha/features/home/data/datasource/series_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';

class SeriesRepository implements SeriesRepositoryInterface {
  final SeriesRemoteDatasource remote;
  final HomeLocalDatasource local;

  SeriesRepository({required this.remote, required this.local});

  @override
  Future<Either<Failure, List<Series>>> getFeaturedSeries({
    required String language,
    int limit = 10,
  }) async {
    final cached = local.readFeaturedSeries(language, limit);
    if (cached != null) {
      unawaited(_refreshFeaturedSeries(language: language, limit: limit));
      return Right(cached.map((m) => m.toEntity(language: language)).toList());
    }

    try {
      final models = await remote.fetchFeaturedSeries(
        language: language,
        limit: limit,
      );
      await local.saveFeaturedSeries(language, limit, models);
      return Right(models.map((m) => m.toEntity(language: language)).toList());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to load featured series'));
    }
  }

  @override
  Stream<Either<Failure, List<Series>>> watchFeaturedSeries({
    required String language,
    int limit = 10,
  }) {
    return _watchList(
      key: local.featuredSeriesKey(language, limit),
      read:
          () =>
              local
                  .readFeaturedSeries(language, limit)
                  ?.map((m) => m.toEntity(language: language))
                  .toList(),
      refresh: () => _refreshFeaturedSeries(language: language, limit: limit),
      failureMessage: 'Failed to load featured series',
    );
  }

  @override
  Future<Either<Failure, List<Series>>> getSeriesList({
    required String language,
  }) async {
    final cached = local.readSeriesList(language);
    if (cached != null) {
      unawaited(_refreshSeriesList(language: language));
      return Right(cached.map((m) => m.toEntity(language: language)).toList());
    }

    try {
      final models = await remote.fetchSeriesList(language: language);
      await local.saveSeriesList(language, models);
      return Right(models.map((m) => m.toEntity(language: language)).toList());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to load series'));
    }
  }

  @override
  Stream<Either<Failure, List<Series>>> watchSeriesList({
    required String language,
  }) {
    return _watchList(
      key: local.seriesListKey(language),
      read:
          () =>
              local
                  .readSeriesList(language)
                  ?.map((m) => m.toEntity(language: language))
                  .toList(),
      refresh: () => _refreshSeriesList(language: language),
      failureMessage: 'Failed to load series',
    );
  }

  @override
  Future<Either<Failure, Series>> getSeriesById(
    String id, {
    required String language,
  }) async {
    final cached = local.readSeriesById(language, id);
    if (cached != null) {
      unawaited(_refreshSeriesById(id, language: language));
      return Right(cached.toEntity(language: language));
    }

    try {
      final model = await remote.fetchSeriesById(id, language: language);
      await local.saveSeriesById(language, model);
      return Right(model.toEntity(language: language));
    } catch (e) {
      return Left(_toFailure(e, 'Failed to load series'));
    }
  }

  @override
  Stream<Either<Failure, Series>> watchSeriesById(
    String id, {
    required String language,
  }) {
    return _watchSingle(
      key: local.seriesByIdKey(language, id),
      read:
          () =>
              local.readSeriesById(language, id)?.toEntity(language: language),
      refresh: () => _refreshSeriesById(id, language: language),
      failureMessage: 'Failed to load series',
    );
  }

  @override
  Future<Either<Failure, Unit>> enrollInSeries(
    String seriesId, {
    String? groupId,
  }) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    await local.enqueueEnrollment(userId, seriesId);
    try {
      await remote.enrollInSeries(seriesId, groupId: groupId);
      await local.removePendingEnrollment(userId, seriesId);
      return const Right(unit);
    } catch (e) {
      return const Right(unit);
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getUserSeriesEnrollments() async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final cached = local.readEnrollments(userId);
    if (cached != null) {
      unawaited(_refreshUserSeriesEnrollments(userId));
      return Right(cached);
    }

    try {
      final ids = await remote.fetchUserSeriesEnrollments();
      final withPending = {...ids, ...local.readPendingEnrollments(userId)};
      await local.saveEnrollments(userId, withPending);
      unawaited(flushPendingEnrollments());
      return Right(withPending);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to load user series enrollments'));
    }
  }

  @override
  Stream<Either<Failure, Set<String>>> watchUserSeriesEnrollments() async* {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      yield const Left(AuthenticationFailure('Not authenticated'));
      return;
    }

    yield* _watchSingle(
      key: local.enrollmentsKey(userId),
      read: () => local.readEnrollments(userId),
      refresh: () => _refreshUserSeriesEnrollments(userId),
      failureMessage: 'Failed to load user series enrollments',
    );
  }

  @override
  Future<void> flushPendingEnrollments() async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) return;

    final pending = local.readPendingEnrollments(userId);
    for (final seriesId in pending) {
      try {
        await remote.enrollInSeries(seriesId);
        await local.removePendingEnrollment(userId, seriesId);
      } catch (_) {
        return;
      }
    }
  }

  Future<void> _refreshFeaturedSeries({
    required String language,
    required int limit,
  }) async {
    final models = await remote.fetchFeaturedSeries(
      language: language,
      limit: limit,
    );
    await local.saveFeaturedSeries(language, limit, models);
  }

  Future<void> _refreshSeriesList({required String language}) async {
    final models = await remote.fetchSeriesList(language: language);
    await local.saveSeriesList(language, models);
  }

  Future<void> _refreshSeriesById(String id, {required String language}) async {
    final model = await remote.fetchSeriesById(id, language: language);
    await local.saveSeriesById(language, model);
  }

  Future<void> _refreshUserSeriesEnrollments(String userId) async {
    await flushPendingEnrollments();
    final ids = await remote.fetchUserSeriesEnrollments();
    await local.saveEnrollments(userId, {
      ...ids,
      ...local.readPendingEnrollments(userId),
    });
  }

  Stream<Either<Failure, T>> _watchSingle<T>({
    required String key,
    required T? Function() read,
    required Future<void> Function() refresh,
    required String failureMessage,
  }) async* {
    final cached = read();
    if (cached != null) yield Right(cached);

    try {
      await refresh();
      final refreshed = read();
      if (refreshed != null) yield Right(refreshed);
    } catch (e) {
      if (cached == null) yield Left(_toFailure(e, failureMessage));
    }

    await for (final _ in local.watchKey(key)) {
      final latest = read();
      if (latest != null) yield Right(latest);
    }
  }

  Stream<Either<Failure, List<T>>> _watchList<T>({
    required String key,
    required List<T>? Function() read,
    required Future<void> Function() refresh,
    required String failureMessage,
  }) {
    return _watchSingle<List<T>>(
      key: key,
      read: read,
      refresh: refresh,
      failureMessage: failureMessage,
    );
  }

  Failure _toFailure(Object error, String fallback) {
    if (error is ServerException) return ServerFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is AuthenticationException) {
      return AuthenticationFailure(error.message);
    }
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is RateLimitException) return RateLimitFailure(error.message);
    return UnknownFailure('$fallback: $error');
  }
}
