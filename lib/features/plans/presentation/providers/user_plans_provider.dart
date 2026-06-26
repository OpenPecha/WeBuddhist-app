import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/user_plans_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/my_plans_paginated_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userPlansFutureProvider =
    StreamProvider<Either<Failure, UserPlanListResponseModel>>((ref) {
      final auth = ref.watch(authProvider);
      if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
        return Stream.value(
          const Left(AuthenticationFailure('Not authenticated')),
        );
      }

      final languageCode = ref.watch(contentLanguageProvider);
      final repository = ref.watch(userPlansDomainRepositoryProvider);
      return repository.watchUserPlans(language: languageCode);
    });

final userPlanProgressDetailsFutureProvider = StreamProvider.autoDispose
    .family<Either<Failure, List<PlanProgressModel>>, String>((ref, planId) {
      final auth = ref.watch(authProvider);
      if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
        return Stream.value(
          const Left(AuthenticationFailure('Not authenticated')),
        );
      }

      final repository = ref.watch(userPlansDomainRepositoryProvider);
      return repository.watchUserPlanProgressDetails(planId);
    });

final userPlanSubscribeFutureProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, String>((ref, planId) {
      final useCase = ref.watch(subscribeToPlanUseCaseProvider);
      return useCase(SubscribeToPlanParams(planId: planId));
    });

final userPlanUnsubscribeFutureProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, String>((ref, planId) {
      final useCase = ref.watch(unsubscribeFromPlanUseCaseProvider);
      return useCase(UnsubscribeFromPlanParams(planId: planId));
    });

final completeTaskFutureProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, String>((ref, taskId) {
      final useCase = ref.watch(completeTaskUseCaseProvider);
      return useCase(CompleteTaskParams(taskId: taskId));
    });

final deleteTaskFutureProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, String>((ref, taskId) {
      final useCase = ref.watch(deleteTaskUseCaseProvider);
      return useCase(DeleteTaskParams(taskId: taskId));
    });

final completeSubTaskFutureProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, String>((ref, subTaskId) {
      final useCase = ref.watch(completeSubTaskUseCaseProvider);
      return useCase(CompleteSubTaskParams(subTaskId: subTaskId));
    });

// My plans with pagination provider
final myPlansPaginatedProvider =
    StateNotifierProvider<MyPlansNotifier, MyPlansState>((ref) {
      final repository = ref.watch(userPlansDomainRepositoryProvider);
      final languageCode = ref.watch(contentLanguageProvider);
      return MyPlansNotifier(
        repository: repository,
        languageCode: languageCode,
        local: ref.watch(plansLocalDatasourceProvider),
      );
    });

// User plan day content provider
final userPlanDayContentFutureProvider = StreamProvider.autoDispose.family<
  Either<Failure, UserPlanDayDetailResponse>,
  PlanDaysParams
>((ref, params) {
  final auth = ref.watch(authProvider);
  if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
    return Stream.value(const Left(AuthenticationFailure('Not authenticated')));
  }

  final repository = ref.watch(userPlansDomainRepositoryProvider);
  return repository.watchUserPlanDayContent(
    params.planId,
    params.dayNumber,
  );
});

/// Provider that watches completion status for all days in a plan.
/// Returns Either<Failure, Map> where key is dayNumber and value is isCompleted.
final userPlanDaysCompletionStatusProvider = StreamProvider.autoDispose
    .family<Either<Failure, Map<int, bool>>, String>((ref, planId) {
      final auth = ref.watch(authProvider);
      if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
        return Stream.value(
          const Left(AuthenticationFailure('Not authenticated')),
        );
      }

      final repository = ref.watch(userPlansDomainRepositoryProvider);
      return repository.watchPlanDaysCompletionStatus(planId);
    });
