import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plan_days_repository.dart';

/// Use case for getting plan days by plan ID.
class GetPlanDaysUseCase {
  final PlanDaysRepositoryInterface _repository;

  GetPlanDaysUseCase(this._repository);

  Future<List<PlanDaysModel>> call(String planId) async {
    if (planId.isEmpty) {
      throw ArgumentError('Plan ID cannot be empty');
    }
    return await _repository.getPlanDaysByPlanId(planId);
  }
}

/// Use case for getting a specific day's content.
class GetDayContentUseCase {
  final PlanDaysRepositoryInterface _repository;

  GetDayContentUseCase(this._repository);

  Future<PlanDaysModel> call(DayContentParams params) async {
    if (params.planId.isEmpty) {
      throw ArgumentError('Plan ID cannot be empty');
    }
    if (params.dayNumber < 1) {
      throw ArgumentError('Day number must be positive');
    }
    return await _repository.getDayContent(params.planId, params.dayNumber);
  }
}

class DayContentParams extends Equatable {
  final String planId;
  final int dayNumber;

  const DayContentParams({required this.planId, required this.dayNumber});

  @override
  List<Object?> get props => [planId, dayNumber];
}
