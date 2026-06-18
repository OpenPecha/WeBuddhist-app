import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';

/// Domain interface for tasks repository.
abstract class TasksRepositoryInterface {
  Future<Either<Failure, List<PlanTasksModel>>> getTasksByPlanItemId(String planItemId);

  Future<Either<Failure, PlanTasksModel>> getTaskById(String id);
}
