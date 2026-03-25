import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/repositories/plans_repository_impl.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plans_repository.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plans_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Repository Providers ==========

/// Provider for PlansRepository implementation (domain interface).
final plansDomainRepositoryProvider = Provider<PlansRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final datasource = PlansRemoteDatasource(dio: dio);
  return PlansRepositoryImpl(datasource: datasource);
});

// ========== Use Case Providers ==========

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
