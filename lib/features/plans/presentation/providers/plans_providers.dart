import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/plan.dart';
import '../../domain/usecases/plans_usecases.dart';
import 'use_case_providers.dart';
import 'plan_search_provider.dart';
import 'find_plans_paginated_provider.dart';

final _logger = AppLogger('PlansProviders');

// Get all plans provider
final plansFutureProvider = FutureProvider<Either<Failure, List<Plan>>>((ref) async {
  final languageCode = ref.watch(contentLanguageProvider);
  final getPlansUseCase = ref.watch(getPlansUseCaseProvider);

  return getPlansUseCase(GetPlansParams(
    language: languageCode,
  ));
});

final planByIdFutureProvider = FutureProvider.family<Either<Failure, Plan?>, String>((
  ref,
  id,
) async {
  final getPlanDetailUseCase = ref.watch(getPlanDetailUseCaseProvider);

  return getPlanDetailUseCase(GetPlanDetailParams(planId: id));
});

// Find plans with pagination provider
final findPlansPaginatedProvider =
    StateNotifierProvider<FindPlansNotifier, FindPlansState>((ref) {
      _logger.debug('🏗️ Creating FindPlansNotifier instance...');
      final getPlansUseCase = ref.watch(getPlansUseCaseProvider);
      final languageCode = ref.watch(contentLanguageProvider);
      _logger.debug('📝 Content language: $languageCode');
      final notifier = FindPlansNotifier(
        getPlansUseCase: getPlansUseCase,
        languageCode: languageCode,
      );
      _logger.debug('✅ FindPlansNotifier instance created');
      return notifier;
    });

// Plan search provider
final planSearchProvider =
    StateNotifierProvider<PlanSearchNotifier, PlanSearchState>((ref) {
      final getPlansUseCase = ref.watch(getPlansUseCaseProvider);
      final languageCode = ref.watch(contentLanguageProvider);
      return PlanSearchNotifier(
        getPlansUseCase: getPlansUseCase,
        languageCode: languageCode,
      );
    });
