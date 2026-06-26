import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_local_datasource.dart';
import 'package:flutter_pecha/features/plans/data/datasource/user_plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/user_plans_repository.dart';

class UserPlansRepository implements UserPlansRepositoryInterface {
  UserPlansRepository({
    required this.userPlansRemoteDatasource,
    required this.local,
  });

  final UserPlansRemoteDatasource userPlansRemoteDatasource;
  final PlansLocalDatasource local;

  @override
  Future<Either<Failure, UserPlanListResponseModel>> getUserPlans({
    required String language,
    int? skip,
    int? limit,
    String? seriesId,
  }) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final cached = local.readUserPlans(
      userId: userId,
      language: language,
      skip: skip,
      limit: limit,
      seriesId: seriesId,
    );
    if (cached != null) {
      unawaited(
        _refreshUserPlans(
          userId: userId,
          language: language,
          skip: skip,
          limit: limit,
          seriesId: seriesId,
        ),
      );
      return Right(cached);
    }

    return refreshUserPlans(
      language: language,
      skip: skip,
      limit: limit,
      seriesId: seriesId,
    );
  }

  @override
  Stream<Either<Failure, UserPlanListResponseModel>> watchUserPlans({
    required String language,
    int? skip,
    int? limit,
    String? seriesId,
  }) async* {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      yield const Left(AuthenticationFailure('Not authenticated'));
      return;
    }

    final key = local.userPlansKey(
      userId: userId,
      language: language,
      skip: skip,
      limit: limit,
      seriesId: seriesId,
    );
    UserPlanListResponseModel? read() => local.readUserPlans(
      userId: userId,
      language: language,
      skip: skip,
      limit: limit,
      seriesId: seriesId,
    );

    yield* _watchSingle(
      key: key,
      read: read,
      refresh:
          () => _refreshUserPlans(
            userId: userId,
            language: language,
            skip: skip,
            limit: limit,
            seriesId: seriesId,
          ),
      failureMessage: 'Failed to fetch user plans',
    );
  }

  @override
  Future<Either<Failure, UserPlanListResponseModel>> refreshUserPlans({
    required String language,
    int? skip,
    int? limit,
    String? seriesId,
  }) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    try {
      await flushPendingPlanActions();
      final result = await userPlansRemoteDatasource.fetchUserPlans(
        language: language,
        skip: skip,
        limit: limit,
        seriesId: seriesId,
      );
      await local.saveUserPlans(
        userId: userId,
        language: language,
        skip: skip,
        limit: limit,
        seriesId: seriesId,
        response: result,
      );
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to fetch user plans'));
    }
  }

  @override
  Future<Either<Failure, bool>> subscribeToPlan(String planId) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    await local.enqueueAction(
      userId,
      type: PendingPlanActionType.subscribe,
      payload: {'planId': planId},
    );
    try {
      final result = await userPlansRemoteDatasource.subscribeToPlan(planId);
      await _removePendingAction(userId, PendingPlanActionType.subscribe, {
        'planId': planId,
      });
      return Right(result);
    } catch (e) {
      return const Right(true);
    }
  }

  @override
  Future<Either<Failure, List<PlanProgressModel>>> getUserPlanProgressDetails(
    String planId,
  ) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final cached = local.readPlanProgress(userId, planId);
    if (cached != null) {
      unawaited(_refreshPlanProgress(userId, planId));
      return Right(cached);
    }

    try {
      final result = await userPlansRemoteDatasource.getUserPlanProgressDetails(
        planId,
      );
      await local.savePlanProgress(userId, planId, result);
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to get plan progress details'),
      );
    }
  }

  @override
  Stream<Either<Failure, List<PlanProgressModel>>> watchUserPlanProgressDetails(
    String planId,
  ) async* {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      yield const Left(AuthenticationFailure('Not authenticated'));
      return;
    }

    yield* _watchSingle(
      key: local.planProgressKey(userId, planId),
      read: () => local.readPlanProgress(userId, planId),
      refresh: () => _refreshPlanProgress(userId, planId),
      failureMessage: 'Failed to get plan progress details',
    );
  }

  @override
  Future<Either<Failure, UserPlanDayDetailResponse>> getUserPlanDayContent(
    String planId,
    int dayNumber,
  ) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final cached = local.readUserPlanDay(userId, planId, dayNumber);
    if (cached != null) {
      unawaited(_refreshUserPlanDay(userId, planId, dayNumber));
      return Right(cached);
    }

    return refreshUserPlanDayContent(planId, dayNumber);
  }

  @override
  Stream<Either<Failure, UserPlanDayDetailResponse>> watchUserPlanDayContent(
    String planId,
    int dayNumber,
  ) async* {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      yield const Left(AuthenticationFailure('Not authenticated'));
      return;
    }

    yield* _watchSingle(
      key: local.userPlanDayKey(userId, planId, dayNumber),
      read: () => local.readUserPlanDay(userId, planId, dayNumber),
      refresh: () => _refreshUserPlanDay(userId, planId, dayNumber),
      failureMessage: 'Failed to get plan day content',
    );
  }

  @override
  Future<Either<Failure, UserPlanDayDetailResponse>> refreshUserPlanDayContent(
    String planId,
    int dayNumber,
  ) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    try {
      final result = await userPlansRemoteDatasource.fetchUserPlanDayContent(
        planId,
        dayNumber,
      );
      await local.saveUserPlanDay(userId, planId, dayNumber, result);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to get plan day content'));
    }
  }

  @override
  Future<Either<Failure, Map<int, bool>>> getPlanDaysCompletionStatus(
    String planId,
  ) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final cached = local.readCompletionStatus(userId, planId);
    if (cached != null) {
      unawaited(_refreshCompletionStatus(userId, planId));
      return Right(cached);
    }

    return refreshPlanDaysCompletionStatus(planId);
  }

  @override
  Stream<Either<Failure, Map<int, bool>>> watchPlanDaysCompletionStatus(
    String planId,
  ) async* {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      yield const Left(AuthenticationFailure('Not authenticated'));
      return;
    }

    yield* _watchSingle(
      key: local.completionStatusKey(userId, planId),
      read: () => local.readCompletionStatus(userId, planId),
      refresh: () => _refreshCompletionStatus(userId, planId),
      failureMessage: 'Failed to get plan days completion status',
    );
  }

  @override
  Future<Either<Failure, Map<int, bool>>> refreshPlanDaysCompletionStatus(
    String planId,
  ) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    try {
      final result = await userPlansRemoteDatasource.fetchPlanDaysCompletionStatus(
        planId,
      );
      await local.saveCompletionStatus(userId, planId, result);
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to get plan days completion status'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> completeSubTask(String subTaskId) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    await local.enqueueAction(
      userId,
      type: PendingPlanActionType.completeSubTask,
      payload: {'subTaskId': subTaskId},
    );
    try {
      final result = await userPlansRemoteDatasource.completeSubTask(subTaskId);
      await _removePendingAction(
        userId,
        PendingPlanActionType.completeSubTask,
        {'subTaskId': subTaskId},
      );
      return Right(result);
    } catch (e) {
      return const Right(true);
    }
  }

  @override
  Future<Either<Failure, bool>> completeTask(String taskId) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    await local.enqueueAction(
      userId,
      type: PendingPlanActionType.completeTask,
      payload: {'taskId': taskId},
    );
    try {
      final result = await userPlansRemoteDatasource.completeTask(taskId);
      await _removePendingAction(
        userId,
        PendingPlanActionType.completeTask,
        {'taskId': taskId},
      );
      return Right(result);
    } catch (e) {
      return const Right(true);
    }
  }

  @override
  Future<Either<Failure, bool>> deleteTask(String taskId) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    await local.enqueueAction(
      userId,
      type: PendingPlanActionType.deleteTask,
      payload: {'taskId': taskId},
    );
    try {
      final result = await userPlansRemoteDatasource.deleteTask(taskId);
      await _removePendingAction(
        userId,
        PendingPlanActionType.deleteTask,
        {'taskId': taskId},
      );
      return Right(result);
    } catch (e) {
      return const Right(true);
    }
  }

  @override
  Future<Either<Failure, bool>> unenrollFromPlan(String planId) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    await local.enqueueAction(
      userId,
      type: PendingPlanActionType.unsubscribe,
      payload: {'planId': planId},
    );
    try {
      final result = await userPlansRemoteDatasource.unenrollFromPlan(planId);
      await _removePendingAction(
        userId,
        PendingPlanActionType.unsubscribe,
        {'planId': planId},
      );
      return Right(result);
    } catch (e) {
      return const Right(true);
    }
  }

  @override
  Future<void> flushPendingPlanActions() async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) return;

    final pending = local.readPendingActions(userId);
    for (final action in pending) {
      try {
        switch (action.type) {
          case PendingPlanActionType.subscribe:
            await userPlansRemoteDatasource.subscribeToPlan(
              action.payload['planId'] as String,
            );
          case PendingPlanActionType.unsubscribe:
            await userPlansRemoteDatasource.unenrollFromPlan(
              action.payload['planId'] as String,
            );
          case PendingPlanActionType.completeTask:
            await userPlansRemoteDatasource.completeTask(
              action.payload['taskId'] as String,
            );
          case PendingPlanActionType.completeSubTask:
            await userPlansRemoteDatasource.completeSubTask(
              action.payload['subTaskId'] as String,
            );
          case PendingPlanActionType.deleteTask:
            await userPlansRemoteDatasource.deleteTask(
              action.payload['taskId'] as String,
            );
        }
        await local.removePendingAction(userId, action.id);
      } catch (_) {
        return;
      }
    }
  }

  Future<void> _refreshUserPlans({
    required String userId,
    required String language,
    int? skip,
    int? limit,
    String? seriesId,
  }) async {
    await flushPendingPlanActions();
    final result = await userPlansRemoteDatasource.fetchUserPlans(
      language: language,
      skip: skip,
      limit: limit,
      seriesId: seriesId,
    );
    await local.saveUserPlans(
      userId: userId,
      language: language,
      skip: skip,
      limit: limit,
      seriesId: seriesId,
      response: result,
    );
  }

  Future<void> _refreshPlanProgress(String userId, String planId) async {
    final result = await userPlansRemoteDatasource.getUserPlanProgressDetails(
      planId,
    );
    await local.savePlanProgress(userId, planId, result);
  }

  Future<void> _refreshUserPlanDay(
    String userId,
    String planId,
    int dayNumber,
  ) async {
    final result = await userPlansRemoteDatasource.fetchUserPlanDayContent(
      planId,
      dayNumber,
    );
    await local.saveUserPlanDay(userId, planId, dayNumber, result);
  }

  Future<void> _refreshCompletionStatus(String userId, String planId) async {
    final result = await userPlansRemoteDatasource.fetchPlanDaysCompletionStatus(
      planId,
    );
    await local.saveCompletionStatus(userId, planId, result);
  }

  Future<void> _removePendingAction(
    String userId,
    PendingPlanActionType type,
    Map<String, dynamic> payload,
  ) async {
    final pending = local.readPendingActions(userId);
    for (final action in pending) {
      if (action.type == type && _mapsEqual(action.payload, payload)) {
        await local.removePendingAction(userId, action.id);
      }
    }
  }

  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
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
      if (cached == null) {
        yield Left(_toFailure(e, failureMessage));
      }
    }

    await for (final _ in local.watchKey(key)) {
      final latest = read();
      if (latest != null) yield Right(latest);
    }
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
