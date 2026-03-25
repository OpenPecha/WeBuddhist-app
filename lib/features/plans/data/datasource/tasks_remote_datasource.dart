import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';

class TasksRemoteDatasource {
  final Dio dio;

  TasksRemoteDatasource({required this.dio});

  // Get tasks by plan item ID
  Future<List<PlanTasksModel>> getTasksByPlanItemId(String planItemId) async {
    try {
      final response = await dio.get('/plan-items/$planItemId/tasks');
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data as List<dynamic>;
        return jsonData.map((json) => PlanTasksModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  // Get task by ID
  Future<PlanTasksModel> getTaskById(String id) async {
    try {
      final response = await dio.get('/tasks/$id');
      if (response.statusCode == 200) {
        return PlanTasksModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load task: $e');
    }
  }

  // Update task
  Future<PlanTasksModel> updateTask(String id, PlanTasksModel task) async {
    try {
      final response = await dio.put(
        '/tasks/$id',
        data: task.toJson(),
      );
      if (response.statusCode == 200) {
        return PlanTasksModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }
}
