import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plan_days_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_local_datasource.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plan_days_repository.dart';

class PlanDaysRepository implements PlanDaysRepositoryInterface {
  PlanDaysRepository({
    required this.planDaysRemoteDatasource,
    required this.local,
  });

  final PlanDaysRemoteDatasource planDaysRemoteDatasource;
  final PlansLocalDatasource local;

  @override
  Future<Either<Failure, List<PlanDaysModel>>> getPlanDaysByPlanId(
    String planId,
  ) async {
    final cached = local.readPlanDays(planId);
    if (cached != null) {
      unawaited(_refreshPlanDays(planId));
      return Right(cached);
    }

    return refreshPlanDaysByPlanId(planId);
  }

  @override
  Stream<Either<Failure, List<PlanDaysModel>>> watchPlanDaysByPlanId(
    String planId,
  ) async* {
    final key = local.planDaysKey(planId);
    List<PlanDaysModel>? read() => local.readPlanDays(planId);

    final cached = read();
    if (cached != null) yield Right(cached);

    try {
      await _refreshPlanDays(planId);
      final refreshed = read();
      if (refreshed != null) yield Right(refreshed);
    } catch (e) {
      if (cached == null) {
        yield Left(ExceptionMapper.map(e, context: 'Failed to load plan days'));
      }
    }

    await for (final _ in local.watchKey(key)) {
      final latest = read();
      if (latest != null) yield Right(latest);
    }
  }

  @override
  Future<Either<Failure, List<PlanDaysModel>>> refreshPlanDaysByPlanId(
    String planId,
  ) async {
    try {
      final result = await planDaysRemoteDatasource.getPlanDaysByPlanId(planId);
      await local.savePlanDays(planId, result);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to load plan days'));
    }
  }

  @override
  Future<Either<Failure, PlanDaysModel>> getDayContent(
    String planId,
    int dayNumber,
  ) async {
    final cached = local.readPlanDayContent(planId, dayNumber);
    if (cached != null) {
      unawaited(_refreshDayContent(planId, dayNumber));
      return Right(cached);
    }

    return refreshDayContent(planId, dayNumber);
  }

  @override
  Stream<Either<Failure, PlanDaysModel>> watchDayContent(
    String planId,
    int dayNumber,
  ) async* {
    final key = local.planDayContentKey(planId, dayNumber);
    PlanDaysModel? read() => local.readPlanDayContent(planId, dayNumber);

    final cached = read();
    if (cached != null) yield Right(cached);

    try {
      await _refreshDayContent(planId, dayNumber);
      final refreshed = read();
      if (refreshed != null) yield Right(refreshed);
    } catch (e) {
      if (cached == null) {
        yield Left(
          ExceptionMapper.map(e, context: 'Failed to load plan day content'),
        );
      }
    }

    await for (final _ in local.watchKey(key)) {
      final latest = read();
      if (latest != null) yield Right(latest);
    }
  }

  @override
  Future<Either<Failure, PlanDaysModel>> refreshDayContent(
    String planId,
    int dayNumber,
  ) async {
    try {
      final result = await planDaysRemoteDatasource.getDayContent(
        planId,
        dayNumber,
      );
      await local.savePlanDayContent(planId, dayNumber, result);
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to load plan day content'),
      );
    }
  }

  Future<void> _refreshPlanDays(String planId) async {
    final result = await planDaysRemoteDatasource.getPlanDaysByPlanId(planId);
    await local.savePlanDays(planId, result);
  }

  Future<void> _refreshDayContent(String planId, int dayNumber) async {
    final result = await planDaysRemoteDatasource.getDayContent(
      planId,
      dayNumber,
    );
    await local.savePlanDayContent(planId, dayNumber, result);
  }
}
