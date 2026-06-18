import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plan_days_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plan_days_repository.dart';

class PlanDaysRepository implements PlanDaysRepositoryInterface {
  final PlanDaysRemoteDatasource planDaysRemoteDatasource;

  PlanDaysRepository({required this.planDaysRemoteDatasource});

  @override
  Future<Either<Failure, List<PlanDaysModel>>> getPlanDaysByPlanId(String planId) async {
    try {
      final result = await planDaysRemoteDatasource.getPlanDaysByPlanId(planId);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to load plan days'));
    }
  }

  @override
  Future<Either<Failure, PlanDaysModel>> getDayContent(String planId, int dayNumber) async {
    try {
      final result = await planDaysRemoteDatasource.getDayContent(planId, dayNumber);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to load plan day content'));
    }
  }
}
