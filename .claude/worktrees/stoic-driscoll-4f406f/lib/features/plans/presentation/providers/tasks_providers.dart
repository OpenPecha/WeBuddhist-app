import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/tasks_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tasksByPlanItemIdFutureProvider =
    FutureProvider.family<Either<Failure, List<PlanTasksModel>>, String>((ref, planItemId) {
      final useCase = ref.watch(getTasksByPlanItemIdUseCaseProvider);
      return useCase(GetTasksByPlanItemIdParams(planItemId: planItemId));
    });

final taskByIdFutureProvider = FutureProvider.family<Either<Failure, PlanTasksModel>, String>((
  ref,
  id,
) {
  final useCase = ref.watch(getTaskByIdUseCaseProvider);
  return useCase(GetTaskByIdParams(id: id));
});
