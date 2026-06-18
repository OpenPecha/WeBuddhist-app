import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/datasource/user_plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/user_plans_repository.dart';

class UserPlansRepository implements UserPlansRepositoryInterface {
  final UserPlansRemoteDatasource userPlansRemoteDatasource;

  UserPlansRepository({required this.userPlansRemoteDatasource});

  @override
  Future<Either<Failure, UserPlanListResponseModel>> getUserPlans({
    required String language,
    int? skip,
    int? limit,
  }) async {
    try {
      final result = await userPlansRemoteDatasource.fetchUserPlans(
        language: language,
        skip: skip,
        limit: limit,
      );
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to fetch user plans'));
    }
  }

  /// Subscribe user to a plan
  @override
  Future<Either<Failure, bool>> subscribeToPlan(String planId) async {
    try {
      final result = await userPlansRemoteDatasource.subscribeToPlan(planId);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to subscribe to plan'));
    }
  }

  /// Get user plan progress details
  @override
  Future<Either<Failure, List<PlanProgressModel>>> getUserPlanProgressDetails(
    String planId,
  ) async {
    try {
      final result = await userPlansRemoteDatasource.getUserPlanProgressDetails(planId);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to get plan progress details'));
    }
  }

  /// Get user plan day content
  @override
  Future<Either<Failure, UserPlanDayDetailResponse>> getUserPlanDayContent(
    String planId,
    int dayNumber,
  ) async {
    try {
      final result = await userPlansRemoteDatasource.fetchUserPlanDayContent(
        planId,
        dayNumber,
      );
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to get plan day content'));
    }
  }

  /// Get completion status for all days in a plan using bulk endpoint
  /// This replaces the N+1 query pattern with a single API call
  @override
  Future<Either<Failure, Map<int, bool>>> getPlanDaysCompletionStatus(String planId) async {
    try {
      final result = await userPlansRemoteDatasource.fetchPlanDaysCompletionStatus(
        planId,
      );
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to get plan days completion status'));
    }
  }

  /// Mark a subtask as complete
  @override
  Future<Either<Failure, bool>> completeSubTask(String subTaskId) async {
    try {
      final result = await userPlansRemoteDatasource.completeSubTask(subTaskId);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to complete subtask'));
    }
  }

  /// Mark a task as complete
  @override
  Future<Either<Failure, bool>> completeTask(String taskId) async {
    try {
      final result = await userPlansRemoteDatasource.completeTask(taskId);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to complete task'));
    }
  }

  /// Delete/uncomplete a task
  @override
  Future<Either<Failure, bool>> deleteTask(String taskId) async {
    try {
      final result = await userPlansRemoteDatasource.deleteTask(taskId);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to delete task'));
    }
  }

  /// Unenroll user from a plan
  @override
  Future<Either<Failure, bool>> unenrollFromPlan(String planId) async {
    try {
      final result = await userPlansRemoteDatasource.unenrollFromPlan(planId);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to unenroll from plan'));
    }
  }
}
