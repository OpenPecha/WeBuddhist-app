import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tasksByPlanItemIdFutureProvider =
    FutureProvider.family<List<PlanTasksModel>, String>((ref, planItemId) {
      final useCase = ref.watch(getTasksByPlanItemIdUseCaseProvider);
      return useCase(planItemId);
    });

final taskByIdFutureProvider = FutureProvider.family<PlanTasksModel, String>((
  ref,
  id,
) {
  final useCase = ref.watch(getTaskByIdUseCaseProvider);
  return useCase(id);
});
