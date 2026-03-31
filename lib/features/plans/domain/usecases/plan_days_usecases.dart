import 'package:fpdart/fpdart.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plan_days_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Use case for getting plan days by plan ID.
class GetPlanDaysUseCase extends UseCase<List<PlanDaysModel>, GetPlanDaysParams> {
  final PlanDaysRepositoryInterface _repository;

  GetPlanDaysUseCase(this._repository);

  @override
  Future<Either<Failure, List<PlanDaysModel>>> call(GetPlanDaysParams params) async {
    if (params.planId.isEmpty) {
      return const Left(ValidationFailure('Plan ID cannot be empty'));
    }
    return await _repository.getPlanDaysByPlanId(params.planId);
  }
}

class GetPlanDaysParams extends Equatable {
  final String planId;

  const GetPlanDaysParams({required this.planId});

  @override
  List<Object?> get props => [planId];
}

/// Use case for getting a specific day's content.
class GetDayContentUseCase extends UseCase<PlanDaysModel, DayContentParams> {
  final PlanDaysRepositoryInterface _repository;

  GetDayContentUseCase(this._repository);

  @override
  Future<Either<Failure, PlanDaysModel>> call(DayContentParams params) async {
    if (params.planId.isEmpty) {
      return const Left(ValidationFailure('Plan ID cannot be empty'));
    }
    if (params.dayNumber < 1) {
      return const Left(ValidationFailure('Day number must be positive'));
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
