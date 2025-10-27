import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_pecha/features/plans/data/datasource/user_plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/repositories/user_plans_repository.dart';
import 'package:flutter_pecha/features/plans/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/models/response/plan_list_response_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userPlansRepositoryProvider = Provider<UserPlansRepository>((ref) {
  return UserPlansRepository(
    userPlansRemoteDatasource: UserPlansRemoteDatasource(
      client: ref.watch(apiClientProvider),
    ),
  );
});

final userPlansFutureProvider = FutureProvider<PlanListResponseModel>((ref) {
  return ref.watch(userPlansRepositoryProvider).getUserPlans();
});

final userPlanProgressDetailsFutureProvider =
    FutureProvider.family<List<PlanProgressModel>, String>((ref, planId) {
      return ref
          .watch(userPlansRepositoryProvider)
          .getUserPlanProgressDetails(planId);
    });

final userPlanSubscribeFutureProvider = FutureProvider.family<bool, String>((
  ref,
  planId,
) {
  return ref.watch(userPlansRepositoryProvider).subscribeToPlan(planId);
});
