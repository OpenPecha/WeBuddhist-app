import 'package:flutter_pecha/core/network/http_client_provider.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plan_days_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/repositories/plan_days_repository.dart';
import 'package:flutter_pecha/features/plans/models/plan_days_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final planDaysRepositoryProvider = Provider<PlanDaysRepository>((ref) {
  return PlanDaysRepository(
    planDaysRemoteDatasource: PlanDaysRemoteDatasource(client: ref.watch(httpClientProvider)),
  );
});

// Get all plan items by plan id provider
final planDaysByPlanIdFutureProvider =
    FutureProvider.family<List<PlanDaysModel>, String>((ref, planId) {
      return ref.watch(planDaysRepositoryProvider).getPlanDaysByPlanId(planId);
    });

// // Get plan item by id provider
// final planItemByIdFutureProvider =
//     FutureProvider.family<PlanItemsModel, String>((ref, id) {
//       return ref.watch(planItemsRepositoryProvider).getPlanItemById(id);
//     });
