import 'package:flutter_pecha/features/plans/data/datasource/tasks_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/models/tasks_model.dart';

class TasksRepository {
  final TasksRemoteDatasource tasksRemoteDatasource;

  TasksRepository({required this.tasksRemoteDatasource});

  Future<List<TasksModel>> getTasksByPlanItemId(String planItemId) async {
    try {
      return await tasksRemoteDatasource.getTasksByPlanItemId(planItemId);
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<TasksModel> getTaskById(String id) async {
    try {
      return await tasksRemoteDatasource.getTaskById(id);
    } catch (e) {
      throw Exception('Failed to load task: $e');
    }
  }
}
