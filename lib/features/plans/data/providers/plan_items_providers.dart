import 'package:flutter_pecha/features/plans/data/datasource/plan_items_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/repositories/plan_items_repository.dart';
import 'package:flutter_pecha/features/plans/models/plan_items_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Repository provider
final planItemsRepositoryProvider = Provider<PlanItemsRepository>((ref) {
  return PlanItemsRepository(
    planItemsRemoteDatasource: PlanItemsRemoteDatasource(client: http.Client()),
  );
});

// Get all plan items by plan id provider
final planItemsByPlanIdFutureProvider =
    FutureProvider.family<List<PlanItemsModel>, String>((ref, planId) {
      return ref
          .watch(planItemsRepositoryProvider)
          .getPlanItemsByPlanId(planId);
    });

// // Get plan item by id provider
// final planItemByIdFutureProvider =
//     FutureProvider.family<PlanItemsModel, String>((ref, id) {
//       return ref.watch(planItemsRepositoryProvider).getPlanItemById(id);
//     });
