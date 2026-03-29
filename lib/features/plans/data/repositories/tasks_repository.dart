import 'package:flutter_pecha/features/plans/data/datasource/tasks_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/tasks_repository.dart';

class TasksRepository implements TasksRepositoryInterface {
  final TasksRemoteDatasource tasksRemoteDatasource;

  TasksRepository({required this.tasksRemoteDatasource});

  @override
  Future<List<PlanTasksModel>> getTasksByPlanItemId(String planItemId) async {
    try {
      return await tasksRemoteDatasource.getTasksByPlanItemId(planItemId);
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  @override
  Future<PlanTasksModel> getTaskById(String id) async {
    try {
      return await tasksRemoteDatasource.getTaskById(id);
    } catch (e) {
      throw Exception('Failed to load task: $e');
    }
  }
}
