import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_pecha/features/plans/data/datasource/tasks_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/repositories/tasks_repository.dart';
import 'package:flutter_pecha/features/plans/models/plan_tasks_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository(
    tasksRemoteDatasource: TasksRemoteDatasource(
      client: ref.watch(apiClientProvider),
    ),
  );
});

final tasksByPlanItemIdFutureProvider =
    FutureProvider.family<List<PlanTasksModel>, String>((ref, planItemId) {
      return ref
          .watch(tasksRepositoryProvider)
          .getTasksByPlanItemId(planItemId);
    });

final taskByIdFutureProvider = FutureProvider.family<PlanTasksModel, String>((
  ref,
  id,
) {
  return ref.watch(tasksRepositoryProvider).getTaskById(id);
});
