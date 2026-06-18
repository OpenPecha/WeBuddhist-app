import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plan_days_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/datasource/tasks_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/datasource/user_plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/repositories/plan_days_repository.dart';
import 'package:flutter_pecha/features/plans/data/repositories/plans_repository_impl.dart';
import 'package:flutter_pecha/features/plans/data/repositories/tasks_repository.dart';
import 'package:flutter_pecha/features/plans/data/repositories/user_plans_repository.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plan_days_repository.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plans_repository.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/tasks_repository.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/user_plans_repository.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plan_days_usecases.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plans_usecases.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/tasks_usecases.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/user_plans_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Repository Providers ==========

/// Provider for PlansRepository implementation (domain interface).
final plansDomainRepositoryProvider = Provider<PlansRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final datasource = PlansRemoteDatasource(dio: dio);
  return PlansRepositoryImpl(datasource: datasource);
});

/// Provider for UserPlansRepository implementation (domain interface).
final userPlansDomainRepositoryProvider =
    Provider<UserPlansRepositoryInterface>((ref) {
  final dio = ref.watch(dioProvider);
  return UserPlansRepository(
    userPlansRemoteDatasource: UserPlansRemoteDatasource(dio: dio),
  );
});

/// Provider for PlanDaysRepository implementation (domain interface).
final planDaysDomainRepositoryProvider =
    Provider<PlanDaysRepositoryInterface>((ref) {
  final dio = ref.watch(dioProvider);
  return PlanDaysRepository(
    planDaysRemoteDatasource: PlanDaysRemoteDatasource(dio: dio),
  );
});

/// Provider for TasksRepository implementation (domain interface).
final tasksDomainRepositoryProvider =
    Provider<TasksRepositoryInterface>((ref) {
  final dio = ref.watch(dioProvider);
  return TasksRepository(
    tasksRemoteDatasource: TasksRemoteDatasource(dio: dio),
  );
});

// ========== Plans Use Case Providers ==========

/// Provider for GetPlansUseCase.
final getPlansUseCaseProvider = Provider<GetPlansUseCase>((ref) {
  final repository = ref.watch(plansDomainRepositoryProvider);
  return GetPlansUseCase(repository);
});

/// Provider for GetPlanDetailUseCase.
final getPlanDetailUseCaseProvider = Provider<GetPlanDetailUseCase>((ref) {
  final repository = ref.watch(plansDomainRepositoryProvider);
  return GetPlanDetailUseCase(repository);
});

/// Provider for EnrollInPlanUseCase.
final enrollInPlanUseCaseProvider = Provider<EnrollInPlanUseCase>((ref) {
  final repository = ref.watch(plansDomainRepositoryProvider);
  return EnrollInPlanUseCase(repository);
});

/// Provider for UpdateProgressUseCase.
final updateProgressUseCaseProvider = Provider<UpdateProgressUseCase>((ref) {
  final repository = ref.watch(plansDomainRepositoryProvider);
  return UpdateProgressUseCase(repository);
});

/// Provider for SearchPlansUseCase.
final searchPlansUseCaseProvider = Provider<SearchPlansUseCase>((ref) {
  final repository = ref.watch(plansDomainRepositoryProvider);
  return SearchPlansUseCase(repository);
});

// ========== User Plans Use Case Providers ==========

/// Provider for GetUserPlansUseCase.
final getUserPlansUseCaseProvider = Provider<GetUserPlansUseCase>((ref) {
  return GetUserPlansUseCase(ref.watch(userPlansDomainRepositoryProvider));
});

/// Provider for SubscribeToPlanUseCase.
final subscribeToPlanUseCaseProvider = Provider<SubscribeToPlanUseCase>((ref) {
  return SubscribeToPlanUseCase(ref.watch(userPlansDomainRepositoryProvider));
});

/// Provider for UnsubscribeFromPlanUseCase.
final unsubscribeFromPlanUseCaseProvider =
    Provider<UnsubscribeFromPlanUseCase>((ref) {
  return UnsubscribeFromPlanUseCase(
    ref.watch(userPlansDomainRepositoryProvider),
  );
});

/// Provider for GetUserPlanProgressUseCase.
final getUserPlanProgressUseCaseProvider =
    Provider<GetUserPlanProgressUseCase>((ref) {
  return GetUserPlanProgressUseCase(
    ref.watch(userPlansDomainRepositoryProvider),
  );
});

/// Provider for GetUserPlanDayContentUseCase.
final getUserPlanDayContentUseCaseProvider =
    Provider<GetUserPlanDayContentUseCase>((ref) {
  return GetUserPlanDayContentUseCase(
    ref.watch(userPlansDomainRepositoryProvider),
  );
});

/// Provider for GetPlanDaysCompletionStatusUseCase.
final getPlanDaysCompletionStatusUseCaseProvider =
    Provider<GetPlanDaysCompletionStatusUseCase>((ref) {
  return GetPlanDaysCompletionStatusUseCase(
    ref.watch(userPlansDomainRepositoryProvider),
  );
});

/// Provider for CompleteTaskUseCase.
final completeTaskUseCaseProvider = Provider<CompleteTaskUseCase>((ref) {
  return CompleteTaskUseCase(ref.watch(userPlansDomainRepositoryProvider));
});

/// Provider for CompleteSubTaskUseCase.
final completeSubTaskUseCaseProvider = Provider<CompleteSubTaskUseCase>((ref) {
  return CompleteSubTaskUseCase(ref.watch(userPlansDomainRepositoryProvider));
});

/// Provider for DeleteTaskUseCase.
final deleteTaskUseCaseProvider = Provider<DeleteTaskUseCase>((ref) {
  return DeleteTaskUseCase(ref.watch(userPlansDomainRepositoryProvider));
});

// ========== Plan Days Use Case Providers ==========

/// Provider for GetPlanDaysUseCase.
final getPlanDaysUseCaseProvider = Provider<GetPlanDaysUseCase>((ref) {
  return GetPlanDaysUseCase(ref.watch(planDaysDomainRepositoryProvider));
});

/// Provider for GetDayContentUseCase.
final getDayContentUseCaseProvider = Provider<GetDayContentUseCase>((ref) {
  return GetDayContentUseCase(ref.watch(planDaysDomainRepositoryProvider));
});

// ========== Tasks Use Case Providers ==========

/// Provider for GetTasksByPlanItemIdUseCase.
final getTasksByPlanItemIdUseCaseProvider =
    Provider<GetTasksByPlanItemIdUseCase>((ref) {
  return GetTasksByPlanItemIdUseCase(ref.watch(tasksDomainRepositoryProvider));
});

/// Provider for GetTaskByIdUseCase.
final getTaskByIdUseCaseProvider = Provider<GetTaskByIdUseCase>((ref) {
  return GetTaskByIdUseCase(ref.watch(tasksDomainRepositoryProvider));
});
