import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_pecha/features/plans/data/datasource/user_plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/repositories/user_plans_repository.dart';
import 'package:flutter_pecha/features/plans/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/models/response/plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/my_plans_paginated_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userPlansRepositoryProvider = Provider<UserPlansRepository>((ref) {
  return UserPlansRepository(
    userPlansRemoteDatasource: UserPlansRemoteDatasource(
      client: ref.watch(apiClientProvider),
    ),
  );
});

final userPlansFutureProvider = FutureProvider<PlanListResponseModel>((ref) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  return ref
      .watch(userPlansRepositoryProvider)
      .getUserPlans(language: languageCode);
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

// Upgrade: my plans provider
final myPlansProvider = FutureProvider<PlanListResponseModel>((ref) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  return ref
      .watch(userPlansRepositoryProvider)
      .getUserPlans(language: languageCode);
});

// My plans with pagination provider
final myPlansPaginatedProvider =
    StateNotifierProvider<MyPlansNotifier, MyPlansState>((ref) {
      final repository = ref.watch(userPlansRepositoryProvider);
      final locale = ref.watch(localeProvider);
      return MyPlansNotifier(
        repository: repository,
        languageCode: locale.languageCode,
      );
    });
