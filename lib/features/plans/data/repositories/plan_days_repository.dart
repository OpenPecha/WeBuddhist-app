import 'package:flutter_pecha/features/plans/data/datasource/plan_days_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plan_days_repository.dart';

class PlanDaysRepository implements PlanDaysRepositoryInterface {
  final PlanDaysRemoteDatasource planDaysRemoteDatasource;

  PlanDaysRepository({required this.planDaysRemoteDatasource});

  @override
  Future<List<PlanDaysModel>> getPlanDaysByPlanId(String planId) async {
    try {
      return await planDaysRemoteDatasource.getPlanDaysByPlanId(planId);
    } catch (e) {
      throw Exception('Failed to load plan days in repository: $e');
    }
  }

  @override
  Future<PlanDaysModel> getDayContent(String planId, int dayNumber) async {
    try {
      return await planDaysRemoteDatasource.getDayContent(planId, dayNumber);
    } catch (e) {
      throw Exception('Failed to load plan day content in repository: $e');
    }
  }
}
