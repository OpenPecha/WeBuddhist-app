import 'package:flutter_pecha/features/plans/data/datasource/user_plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/models/response/plan_list_response_model.dart';

class UserPlansRepository {
  final UserPlansRemoteDatasource userPlansRemoteDatasource;

  UserPlansRepository({required this.userPlansRemoteDatasource});

  Future<PlanListResponseModel> getUserPlans() async {
    return await userPlansRemoteDatasource.getUserPlansByUserId();
  }

  Future<bool> subscribeToPlan(String planId) async {
    return await userPlansRemoteDatasource.subscribeToPlan(planId);
  }

  Future<List<PlanProgressModel>> getUserPlanProgressDetails(
    String planId,
  ) async {
    return await userPlansRemoteDatasource.getUserPlanProgressDetails(planId);
  }
}
