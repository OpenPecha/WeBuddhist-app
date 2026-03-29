import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/user_plans_repository.dart';

/// Use case for getting user's enrolled plans with pagination.
class GetUserPlansUseCase {
  final UserPlansRepositoryInterface _repository;

  GetUserPlansUseCase(this._repository);

  Future<UserPlanListResponseModel> call(GetUserPlansParams params) async {
    if (params.language.isEmpty) {
      throw ArgumentError('Language cannot be empty');
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
class SubscribeToPlanUseCase {
  final UserPlansRepositoryInterface _repository;

  SubscribeToPlanUseCase(this._repository);

  Future<bool> call(String planId) async {
    if (planId.isEmpty) {
      throw ArgumentError('Plan ID cannot be empty');
    }
    return await _repository.subscribeToPlan(planId);
  }
}

/// Use case for unsubscribing from a plan.
class UnsubscribeFromPlanUseCase {
  final UserPlansRepositoryInterface _repository;

  UnsubscribeFromPlanUseCase(this._repository);

  Future<bool> call(String planId) async {
    if (planId.isEmpty) {
      throw ArgumentError('Plan ID cannot be empty');
    }
    return await _repository.unenrollFromPlan(planId);
  }
}

/// Use case for getting user plan progress details.
class GetUserPlanProgressUseCase {
  final UserPlansRepositoryInterface _repository;

  GetUserPlanProgressUseCase(this._repository);

  Future<List<PlanProgressModel>> call(String planId) async {
    if (planId.isEmpty) {
      throw ArgumentError('Plan ID cannot be empty');
    }
    return await _repository.getUserPlanProgressDetails(planId);
  }
}

/// Use case for getting user plan day content.
class GetUserPlanDayContentUseCase {
  final UserPlansRepositoryInterface _repository;

  GetUserPlanDayContentUseCase(this._repository);

  Future<UserPlanDayDetailResponse> call(PlanDayContentParams params) async {
    if (params.planId.isEmpty) {
      throw ArgumentError('Plan ID cannot be empty');
    }
    if (params.dayNumber < 1) {
      throw ArgumentError('Day number must be positive');
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
class GetPlanDaysCompletionStatusUseCase {
  final UserPlansRepositoryInterface _repository;

  GetPlanDaysCompletionStatusUseCase(this._repository);

  Future<Map<int, bool>> call(String planId) async {
    if (planId.isEmpty) {
      throw ArgumentError('Plan ID cannot be empty');
    }
    return await _repository.getPlanDaysCompletionStatus(planId);
  }
}

/// Use case for completing a task.
class CompleteTaskUseCase {
  final UserPlansRepositoryInterface _repository;

  CompleteTaskUseCase(this._repository);

  Future<bool> call(String taskId) async {
    if (taskId.isEmpty) {
      throw ArgumentError('Task ID cannot be empty');
    }
    return await _repository.completeTask(taskId);
  }
}

/// Use case for completing a subtask.
class CompleteSubTaskUseCase {
  final UserPlansRepositoryInterface _repository;

  CompleteSubTaskUseCase(this._repository);

  Future<bool> call(String subTaskId) async {
    if (subTaskId.isEmpty) {
      throw ArgumentError('Subtask ID cannot be empty');
    }
    return await _repository.completeSubTask(subTaskId);
  }
}

/// Use case for deleting/uncompleting a task.
class DeleteTaskUseCase {
  final UserPlansRepositoryInterface _repository;

  DeleteTaskUseCase(this._repository);

  Future<bool> call(String taskId) async {
    if (taskId.isEmpty) {
      throw ArgumentError('Task ID cannot be empty');
    }
    return await _repository.deleteTask(taskId);
  }
}
