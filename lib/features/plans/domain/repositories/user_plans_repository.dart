import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';

/// Domain interface for user plans repository.
abstract class UserPlansRepositoryInterface {
  Future<Either<Failure, UserPlanListResponseModel>> getUserPlans({
    required String language,
    int? skip,
    int? limit,
    String? seriesId,
  });

  Stream<Either<Failure, UserPlanListResponseModel>> watchUserPlans({
    required String language,
    int? skip,
    int? limit,
    String? seriesId,
  });

  Future<Either<Failure, UserPlanListResponseModel>> refreshUserPlans({
    required String language,
    int? skip,
    int? limit,
    String? seriesId,
  });

  Future<Either<Failure, bool>> subscribeToPlan(String planId);

  Future<Either<Failure, List<PlanProgressModel>>> getUserPlanProgressDetails(
    String planId,
  );

  Stream<Either<Failure, List<PlanProgressModel>>> watchUserPlanProgressDetails(
    String planId,
  );

  Future<Either<Failure, UserPlanDayDetailResponse>> getUserPlanDayContent(
    String planId,
    int dayNumber,
  );

  Stream<Either<Failure, UserPlanDayDetailResponse>> watchUserPlanDayContent(
    String planId,
    int dayNumber,
  );

  Future<Either<Failure, UserPlanDayDetailResponse>> refreshUserPlanDayContent(
    String planId,
    int dayNumber,
  );

  Future<Either<Failure, Map<int, bool>>> getPlanDaysCompletionStatus(
    String planId,
  );

  Stream<Either<Failure, Map<int, bool>>> watchPlanDaysCompletionStatus(
    String planId,
  );

  Future<Either<Failure, Map<int, bool>>> refreshPlanDaysCompletionStatus(
    String planId,
  );

  Future<Either<Failure, bool>> completeSubTask(String subTaskId);

  Future<Either<Failure, bool>> completeTask(String taskId);

  Future<Either<Failure, bool>> deleteTask(String taskId);

  Future<Either<Failure, bool>> unenrollFromPlan(String planId);

  Future<void> flushPendingPlanActions();
}
