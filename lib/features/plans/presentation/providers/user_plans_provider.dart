import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/user_plans_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/my_plans_paginated_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userPlansFutureProvider = FutureProvider<Either<Failure, UserPlanListResponseModel>>((
  ref,
) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  final useCase = ref.watch(getUserPlansUseCaseProvider);
  return useCase(GetUserPlansParams(language: languageCode));
});

final userPlanProgressDetailsFutureProvider =
    FutureProvider.autoDispose.family<Either<Failure, List<PlanProgressModel>>, String>((
      ref,
      planId,
    ) {
      final useCase = ref.watch(getUserPlanProgressUseCaseProvider);
      return useCase(GetUserPlanProgressParams(planId: planId));
    });

final userPlanSubscribeFutureProvider =
    FutureProvider.autoDispose.family<Either<Failure, bool>, String>((
      ref,
      planId,
    ) {
      final useCase = ref.watch(subscribeToPlanUseCaseProvider);
      return useCase(SubscribeToPlanParams(planId: planId));
    });

final userPlanUnsubscribeFutureProvider =
    FutureProvider.autoDispose.family<Either<Failure, bool>, String>((ref, planId) {
      final useCase = ref.watch(unsubscribeFromPlanUseCaseProvider);
      return useCase(UnsubscribeFromPlanParams(planId: planId));
    });

final completeTaskFutureProvider = FutureProvider.autoDispose.family<Either<Failure, bool>, String>((
  ref,
  taskId,
) {
  final useCase = ref.watch(completeTaskUseCaseProvider);
  return useCase(CompleteTaskParams(taskId: taskId));
});

final deleteTaskFutureProvider = FutureProvider.autoDispose.family<Either<Failure, bool>, String>((
  ref,
  taskId,
) {
  final useCase = ref.watch(deleteTaskUseCaseProvider);
  return useCase(DeleteTaskParams(taskId: taskId));
});

final completeSubTaskFutureProvider = FutureProvider.autoDispose.family<Either<Failure, bool>, String>((
  ref,
  subTaskId,
) {
  final useCase = ref.watch(completeSubTaskUseCaseProvider);
  return useCase(CompleteSubTaskParams(subTaskId: subTaskId));
});

// My plans with pagination provider
final myPlansPaginatedProvider =
    StateNotifierProvider<MyPlansNotifier, MyPlansState>((ref) {
      final repository = ref.watch(userPlansDomainRepositoryProvider);
      final locale = ref.watch(localeProvider);
      return MyPlansNotifier(
        repository: repository,
        languageCode: locale.languageCode,
      );
    });

// User plan day content provider
final userPlanDayContentFutureProvider =
    FutureProvider.autoDispose
        .family<Either<Failure, UserPlanDayDetailResponse>, PlanDaysParams>((
      ref,
      params,
    ) {
      final useCase = ref.watch(getUserPlanDayContentUseCaseProvider);
      return useCase(PlanDayContentParams(
        planId: params.planId,
        dayNumber: params.dayNumber,
      ));
    });

/// Provider that fetches completion status for all days in a plan using bulk endpoint
/// Returns Either<Failure, Map> where key is dayNumber and value is isCompleted status
///
/// This uses a single API call instead of N separate calls (N+1 problem fixed)
final userPlanDaysCompletionStatusProvider =
    FutureProvider.autoDispose.family<Either<Failure, Map<int, bool>>, String>((ref, planId) {
      final useCase = ref.watch(getPlanDaysCompletionStatusUseCaseProvider);
      return useCase(GetPlanDaysCompletionStatusParams(planId: planId));
    });
