import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_local_datasource.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/domain/entities/author.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan_day.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan_progress.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plans_repository.dart';

final _logger = AppLogger('PlansRepositoryImpl');

/// Repository implementation for managing plans.
///
/// Reads local Hive data first, refreshes from remote in the background,
/// and returns Either<Failure, T> results.
class PlansRepositoryImpl implements PlansRepository {
  PlansRepositoryImpl({
    required PlansRemoteDatasource datasource,
    required PlansLocalDatasource local,
  }) : _datasource = datasource,
       _local = local;

  final PlansRemoteDatasource _datasource;
  final PlansLocalDatasource _local;

  @override
  Future<Either<Failure, List<Plan>>> getPlans({
    required String language,
    String? search,
    String? tag,
    int? skip,
    int? limit,
  }) async {
    final cached = _local.readPlans(
      language: language,
      skip: skip ?? 0,
      limit: limit ?? 20,
      tag: tag,
      search: search,
    );
    if (cached != null) {
      unawaited(
        _refreshPlans(
          language: language,
          search: search,
          tag: tag,
          skip: skip,
          limit: limit,
        ),
      );
      return Right(cached.map((m) => m.toEntity()).toList());
    }

    try {
      final models = await _datasource.fetchPlans(
        queryParams: PlansQueryParams(
          language: language,
          search: search,
          tag: tag,
          skip: skip,
          limit: limit,
        ),
      );
      await _local.savePlans(
        language: language,
        skip: skip ?? 0,
        limit: limit ?? 20,
        tag: tag,
        search: search,
        plans: models,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      _logger.error('Failed to get plans', e);
      return Left(ExceptionMapper.map(e, context: 'getPlans'));
    }
  }

  @override
  Future<Either<Failure, Plan?>> getPlan(String id) async {
    if (id.isEmpty) {
      return const Left(ValidationFailure('Plan ID cannot be empty'));
    }

    final cached = _local.readPlanById(id);
    if (cached != null) {
      unawaited(_refreshPlan(id));
      return Right(cached.toEntity());
    }

    return refreshPlan(id);
  }

  @override
  Stream<Either<Failure, Plan?>> watchPlan(String id) async* {
    if (id.isEmpty) {
      yield const Left(ValidationFailure('Plan ID cannot be empty'));
      return;
    }

    final key = _local.planByIdKey(id);
    Plan? read() => _local.readPlanById(id)?.toEntity();

    final cached = read();
    if (cached != null) yield Right(cached);

    try {
      await _refreshPlan(id);
      final refreshed = read();
      if (refreshed != null) yield Right(refreshed);
    } catch (e) {
      if (cached == null) {
        yield Left(ExceptionMapper.map(e, context: 'getPlan'));
      }
    }

    await for (final _ in _local.watchKey(key)) {
      final latest = read();
      if (latest != null) yield Right(latest);
    }
  }

  @override
  Future<Either<Failure, Plan?>> refreshPlan(String id) async {
    if (id.isEmpty) {
      return const Left(ValidationFailure('Plan ID cannot be empty'));
    }

    try {
      final model = await _datasource.getPlanById(id);
      await _local.savePlanById(model);
      return Right(model.toEntity());
    } catch (e) {
      _logger.error('Failed to get plan $id', e);
      return Left(ExceptionMapper.map(e, context: 'getPlan'));
    }
  }

  @override
  Future<Either<Failure, List<Plan>>> getPlansByTags(List<String> tags) async {
    try {
      if (tags.isEmpty) {
        return const Right([]);
      }
      return getPlans(language: 'en', tag: tags.first);
    } catch (e) {
      _logger.error('Failed to get plans by tags', e);
      return Left(ExceptionMapper.map(e, context: 'getPlansByTags'));
    }
  }

  @override
  Future<Either<Failure, List<Plan>>> searchPlans(String query) async {
    try {
      if (query.isEmpty) {
        return const Left(ValidationFailure('Search query cannot be empty'));
      }
      return getPlans(language: 'en', search: query);
    } catch (e) {
      _logger.error('Failed to search plans', e);
      return Left(ExceptionMapper.map(e, context: 'searchPlans'));
    }
  }

  @override
  Future<Either<Failure, List<Plan>>> getPlansByAuthor(String authorId) async {
    try {
      final result = await getPlans(language: 'en');
      return result.map(
        (plans) => plans.where((plan) => plan.authorId == authorId).toList(),
      );
    } catch (e) {
      _logger.error('Failed to get plans by author', e);
      return Left(ExceptionMapper.map(e, context: 'getPlansByAuthor'));
    }
  }

  @override
  Future<Either<Failure, Author?>> getAuthor(String authorId) async {
    try {
      return const Right(null);
    } catch (e) {
      _logger.error('Failed to get author', e);
      return Left(ExceptionMapper.map(e, context: 'getAuthor'));
    }
  }

  @override
  Future<Either<Failure, PlanProgress?>> getUserPlanProgress(
    String planId,
  ) async {
    try {
      return const Right(null);
    } catch (e) {
      _logger.error('Failed to get user plan progress', e);
      return Left(ExceptionMapper.map(e, context: 'getUserPlanProgress'));
    }
  }

  @override
  Future<Either<Failure, PlanProgress>> enrollInPlan(String planId) async {
    try {
      return Left(ServerFailure('Enrollment not yet implemented'));
    } catch (e) {
      _logger.error('Failed to enroll in plan', e);
      return Left(ExceptionMapper.map(e, context: 'enrollInPlan'));
    }
  }

  @override
  Future<Either<Failure, PlanProgress>> updateProgress(
    String planId,
    int dayNumber,
    String? taskId,
  ) async {
    try {
      return Left(ServerFailure('Progress update not yet implemented'));
    } catch (e) {
      _logger.error('Failed to update progress', e);
      return Left(ExceptionMapper.map(e, context: 'updateProgress'));
    }
  }

  @override
  Future<Either<Failure, void>> unenrollFromPlan(String planId) async {
    try {
      return const Right(null);
    } catch (e) {
      _logger.error('Failed to unenroll from plan', e);
      return Left(ExceptionMapper.map(e, context: 'unenrollFromPlan'));
    }
  }

  @override
  Future<Either<Failure, PlanDay?>> getPlanDay(
    String planId,
    int dayNumber,
  ) async {
    try {
      return const Right(null);
    } catch (e) {
      _logger.error('Failed to get plan day', e);
      return Left(ExceptionMapper.map(e, context: 'getPlanDay'));
    }
  }

  Future<void> _refreshPlans({
    required String language,
    String? search,
    String? tag,
    int? skip,
    int? limit,
  }) async {
    final models = await _datasource.fetchPlans(
      queryParams: PlansQueryParams(
        language: language,
        search: search,
        tag: tag,
        skip: skip,
        limit: limit,
      ),
    );
    await _local.savePlans(
      language: language,
      skip: skip ?? 0,
      limit: limit ?? 20,
      tag: tag,
      search: search,
      plans: models,
    );
  }

  Future<void> _refreshPlan(String id) async {
    final model = await _datasource.getPlanById(id);
    await _local.savePlanById(model);
  }
}
