import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';

/// Domain interface for plan days repository.
abstract class PlanDaysRepositoryInterface {
  Future<Either<Failure, List<PlanDaysModel>>> getPlanDaysByPlanId(String planId);

  Future<Either<Failure, PlanDaysModel>> getDayContent(String planId, int dayNumber);
}
