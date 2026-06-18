import 'package:fpdart/fpdart.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/tasks_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Use case for getting tasks by plan item ID.
class GetTasksByPlanItemIdUseCase extends UseCase<List<PlanTasksModel>, GetTasksByPlanItemIdParams> {
  final TasksRepositoryInterface _repository;

  GetTasksByPlanItemIdUseCase(this._repository);

  @override
  Future<Either<Failure, List<PlanTasksModel>>> call(GetTasksByPlanItemIdParams params) async {
    if (params.planItemId.isEmpty) {
      return const Left(ValidationFailure('Plan item ID cannot be empty'));
    }
    return await _repository.getTasksByPlanItemId(params.planItemId);
  }
}

class GetTasksByPlanItemIdParams extends Equatable {
  final String planItemId;

  const GetTasksByPlanItemIdParams({required this.planItemId});

  @override
  List<Object?> get props => [planItemId];
}

/// Use case for getting a task by its ID.
class GetTaskByIdUseCase extends UseCase<PlanTasksModel, GetTaskByIdParams> {
  final TasksRepositoryInterface _repository;

  GetTaskByIdUseCase(this._repository);

  @override
  Future<Either<Failure, PlanTasksModel>> call(GetTaskByIdParams params) async {
    if (params.id.isEmpty) {
      return const Left(ValidationFailure('Task ID cannot be empty'));
    }
    return await _repository.getTaskById(params.id);
  }
}

class GetTaskByIdParams extends Equatable {
  final String id;

  const GetTaskByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}
