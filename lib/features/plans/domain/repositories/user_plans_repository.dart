import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';

/// Domain interface for user plans repository.
abstract class UserPlansRepositoryInterface {
  Future<UserPlanListResponseModel> getUserPlans({
    required String language,
    int? skip,
    int? limit,
  });

  Future<bool> subscribeToPlan(String planId);

  Future<List<PlanProgressModel>> getUserPlanProgressDetails(String planId);

  Future<UserPlanDayDetailResponse> getUserPlanDayContent(
    String planId,
    int dayNumber,
  );

  Future<Map<int, bool>> getPlanDaysCompletionStatus(String planId);

  Future<bool> completeSubTask(String subTaskId);

  Future<bool> completeTask(String taskId);

  Future<bool> deleteTask(String taskId);

  Future<bool> unenrollFromPlan(String planId);
}
