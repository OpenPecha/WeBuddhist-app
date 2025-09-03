import 'package:flutter_pecha/features/plans/data/datasource/plan_items_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/models/plan_items_model.dart';

class PlanItemsRepository {
  final PlanItemsRemoteDatasource planItemsRemoteDatasource;

  PlanItemsRepository({required this.planItemsRemoteDatasource});

  Future<List<PlanItemsModel>> getPlanItemsByPlanId(String planId) async {
    try {
      return await planItemsRemoteDatasource.getPlanItemsByPlanId(planId);
    } catch (e) {
      throw Exception('Failed to load plan items: $e');
    }
  }
}
