import 'package:fpdart/fpdart.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/user_plans_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Use case for getting user's enrolled plans with pagination.
class GetUserPlansUseCase extends UseCase<UserPlanListResponseModel, GetUserPlansParams> {
  final UserPlansRepositoryInterface _repository;

  GetUserPlansUseCase(this._repository);

  @override
  Future<Either<Failure, UserPlanListResponseModel>> call(GetUserPlansParams params) async {
    if (params.language.isEmpty) {
      return const Left(ValidationFailure('Language cannot be empty'));
    }
    return await _repository.getUserPlans(
      language: params.language,
      skip: params.skip,
      limit: params.limit,
    );
  }
}

class GetUserPlansParams extends Equatable {
  final String language;
  final int? skip;
  final int? limit;

  const GetUserPlansParams({
    required this.language,
    this.skip,
    this.limit,
  });

  @override
  List<Object?> get props => [language, skip, limit];
}

/// Use case for subscribing to a plan.
class SubscribeToPlanUseCase extends UseCase<bool, SubscribeToPlanParams> {
  final UserPlansRepositoryInterface _repository;

  SubscribeToPlanUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(SubscribeToPlanParams params) async {
    if (params.planId.isEmpty) {
      return const Left(ValidationFailure('Plan ID cannot be empty'));
    }
    return await _repository.subscribeToPlan(params.planId);
  }
}

class SubscribeToPlanParams extends Equatable {
  final String planId;

  const SubscribeToPlanParams({required this.planId});

  @override
  List<Object?> get props => [planId];
}

/// Use case for unsubscribing from a plan.
class UnsubscribeFromPlanUseCase extends UseCase<bool, UnsubscribeFromPlanParams> {
  final UserPlansRepositoryInterface _repository;

  UnsubscribeFromPlanUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(UnsubscribeFromPlanParams params) async {
    if (params.planId.isEmpty) {
      return const Left(ValidationFailure('Plan ID cannot be empty'));
    }
    return await _repository.unenrollFromPlan(params.planId);
  }
}

class UnsubscribeFromPlanParams extends Equatable {
  final String planId;

  const UnsubscribeFromPlanParams({required this.planId});

  @override
  List<Object?> get props => [planId];
}

/// Use case for getting user plan progress details.
class GetUserPlanProgressUseCase extends UseCase<List<PlanProgressModel>, GetUserPlanProgressParams> {
  final UserPlansRepositoryInterface _repository;

  GetUserPlanProgressUseCase(this._repository);

  @override
  Future<Either<Failure, List<PlanProgressModel>>> call(GetUserPlanProgressParams params) async {
    if (params.planId.isEmpty) {
      return const Left(ValidationFailure('Plan ID cannot be empty'));
    }
    return await _repository.getUserPlanProgressDetails(params.planId);
  }
}

class GetUserPlanProgressParams extends Equatable {
  final String planId;

  const GetUserPlanProgressParams({required this.planId});

  @override
  List<Object?> get props => [planId];
}

/// Use case for getting user plan day content.
class GetUserPlanDayContentUseCase extends UseCase<UserPlanDayDetailResponse, PlanDayContentParams> {
  final UserPlansRepositoryInterface _repository;

  GetUserPlanDayContentUseCase(this._repository);

  @override
  Future<Either<Failure, UserPlanDayDetailResponse>> call(PlanDayContentParams params) async {
    if (params.planId.isEmpty) {
      return const Left(ValidationFailure('Plan ID cannot be empty'));
    }
    if (params.dayNumber < 1) {
      return const Left(ValidationFailure('Day number must be positive'));
    }
    return await _repository.getUserPlanDayContent(
      params.planId,
      params.dayNumber,
    );
  }
}

class PlanDayContentParams extends Equatable {
  final String planId;
  final int dayNumber;

  const PlanDayContentParams({
    required this.planId,
    required this.dayNumber,
  });

  @override
  List<Object?> get props => [planId, dayNumber];
}

/// Use case for getting plan days completion status.
class GetPlanDaysCompletionStatusUseCase extends UseCase<Map<int, bool>, GetPlanDaysCompletionStatusParams> {
  final UserPlansRepositoryInterface _repository;

  GetPlanDaysCompletionStatusUseCase(this._repository);

  @override
  Future<Either<Failure, Map<int, bool>>> call(GetPlanDaysCompletionStatusParams params) async {
    if (params.planId.isEmpty) {
      return const Left(ValidationFailure('Plan ID cannot be empty'));
    }
    return await _repository.getPlanDaysCompletionStatus(params.planId);
  }
}

class GetPlanDaysCompletionStatusParams extends Equatable {
  final String planId;

  const GetPlanDaysCompletionStatusParams({required this.planId});

  @override
  List<Object?> get props => [planId];
}

/// Use case for completing a task.
class CompleteTaskUseCase extends UseCase<bool, CompleteTaskParams> {
  final UserPlansRepositoryInterface _repository;

  CompleteTaskUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(CompleteTaskParams params) async {
    if (params.taskId.isEmpty) {
      return const Left(ValidationFailure('Task ID cannot be empty'));
    }
    return await _repository.completeTask(params.taskId);
  }
}

class CompleteTaskParams extends Equatable {
  final String taskId;

  const CompleteTaskParams({required this.taskId});

  @override
  List<Object?> get props => [taskId];
}

/// Use case for completing a subtask.
class CompleteSubTaskUseCase extends UseCase<bool, CompleteSubTaskParams> {
  final UserPlansRepositoryInterface _repository;

  CompleteSubTaskUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(CompleteSubTaskParams params) async {
    if (params.subTaskId.isEmpty) {
      return const Left(ValidationFailure('Subtask ID cannot be empty'));
    }
    return await _repository.completeSubTask(params.subTaskId);
  }
}

class CompleteSubTaskParams extends Equatable {
  final String subTaskId;

  const CompleteSubTaskParams({required this.subTaskId});

  @override
  List<Object?> get props => [subTaskId];
}

/// Use case for deleting/uncompleting a task.
class DeleteTaskUseCase extends UseCase<bool, DeleteTaskParams> {
  final UserPlansRepositoryInterface _repository;

  DeleteTaskUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(DeleteTaskParams params) async {
    if (params.taskId.isEmpty) {
      return const Left(ValidationFailure('Task ID cannot be empty'));
    }
    return await _repository.deleteTask(params.taskId);
  }
}

class DeleteTaskParams extends Equatable {
  final String taskId;

  const DeleteTaskParams({required this.taskId});

  @override
  List<Object?> get props => [taskId];
}
