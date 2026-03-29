import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';

/// Domain interface for tasks repository.
abstract class TasksRepositoryInterface {
  Future<List<PlanTasksModel>> getTasksByPlanItemId(String planItemId);

  Future<PlanTasksModel> getTaskById(String id);
}
