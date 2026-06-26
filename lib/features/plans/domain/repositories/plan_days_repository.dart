import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';

/// Domain interface for plan days repository.
abstract class PlanDaysRepositoryInterface {
  Future<Either<Failure, List<PlanDaysModel>>> getPlanDaysByPlanId(
    String planId,
  );

  Stream<Either<Failure, List<PlanDaysModel>>> watchPlanDaysByPlanId(
    String planId,
  );

  Future<Either<Failure, List<PlanDaysModel>>> refreshPlanDaysByPlanId(
    String planId,
  );

  Future<Either<Failure, PlanDaysModel>> getDayContent(
    String planId,
    int dayNumber,
  );

  Stream<Either<Failure, PlanDaysModel>> watchDayContent(
    String planId,
    int dayNumber,
  );

  Future<Either<Failure, PlanDaysModel>> refreshDayContent(
    String planId,
    int dayNumber,
  );
}
