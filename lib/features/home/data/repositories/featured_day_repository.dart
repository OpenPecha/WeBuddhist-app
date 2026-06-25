import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_local_datasource.dart';
import 'package:flutter_pecha/features/home/data/datasource/featured_day_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';
import 'package:flutter_pecha/features/plans/data/models/response/featured_day_response.dart';

class FeaturedDayRepository implements FeaturedDayRepositoryInterface {
  final FeaturedDayRemoteDatasource featuredDayRemoteDatasource;
  final HomeLocalDatasource local;

  FeaturedDayRepository({
    required this.featuredDayRemoteDatasource,
    required this.local,
  });

  @override
  Future<Either<Failure, FeaturedDayResponse>> getFeaturedDay({
    String? language,
  }) async {
    final lang = language ?? 'en';
    final cached = local.readFeaturedDay(lang);
    if (cached != null) {
      unawaited(_refresh(lang));
      return Right(cached);
    }

    try {
      final featuredDay = await featuredDayRemoteDatasource.fetchFeaturedDay(
        language: lang,
      );
      await local.saveFeaturedDay(lang, featuredDay);
      return Right(featuredDay);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to get featured day'));
    }
  }

  @override
  Stream<Either<Failure, FeaturedDayResponse>> watchFeaturedDay({
    String? language,
  }) async* {
    final lang = language ?? 'en';
    final key = local.featuredDayKey(lang);
    final cached = local.readFeaturedDay(lang);
    if (cached != null) yield Right(cached);

    try {
      await _refresh(lang);
      final refreshed = local.readFeaturedDay(lang);
      if (refreshed != null) yield Right(refreshed);
    } catch (e) {
      if (cached == null) {
        yield Left(_toFailure(e, 'Failed to get featured day'));
      }
    }

    await for (final _ in local.watchKey(key)) {
      final latest = local.readFeaturedDay(lang);
      if (latest != null) yield Right(latest);
    }
  }

  Future<void> _refresh(String language) async {
    final featuredDay = await featuredDayRemoteDatasource.fetchFeaturedDay(
      language: language,
    );
    await local.saveFeaturedDay(language, featuredDay);
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

  Failure _toFailure(Object error, String fallback) {
    if (error is ServerException) return ServerFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is AuthenticationException) {
      return AuthenticationFailure(error.message);
    }
    if (error is RateLimitException) return RateLimitFailure(error.message);
    return UnknownFailure('$fallback: $error');
  }
}
