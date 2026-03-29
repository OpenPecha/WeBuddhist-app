import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/tasks_repository.dart';

/// Use case for getting tasks by plan item ID.
class GetTasksByPlanItemIdUseCase {
  final TasksRepositoryInterface _repository;

  GetTasksByPlanItemIdUseCase(this._repository);

  Future<List<PlanTasksModel>> call(String planItemId) async {
    if (planItemId.isEmpty) {
      throw ArgumentError('Plan item ID cannot be empty');
    }
    return await _repository.getTasksByPlanItemId(planItemId);
  }
}

/// Use case for getting a task by its ID.
class GetTaskByIdUseCase {
  final TasksRepositoryInterface _repository;

  GetTaskByIdUseCase(this._repository);

  Future<PlanTasksModel> call(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('Task ID cannot be empty');
    }
    return await _repository.getTaskById(id);
  }
}
