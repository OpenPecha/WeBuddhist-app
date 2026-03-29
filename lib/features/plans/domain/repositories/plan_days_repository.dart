import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';

/// Domain interface for plan days repository.
abstract class PlanDaysRepositoryInterface {
  Future<List<PlanDaysModel>> getPlanDaysByPlanId(String planId);

  Future<PlanDaysModel> getDayContent(String planId, int dayNumber);
}
