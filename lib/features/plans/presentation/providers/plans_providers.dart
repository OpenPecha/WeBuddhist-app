import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/plans_repository.dart';
import '../../data/datasource/plans_remote_datasource.dart';
import '../../data/models/plans_model.dart';
import 'plan_search_provider.dart';
import 'find_plans_paginated_provider.dart';

final _logger = AppLogger('PlansProviders');

// Repository provider
final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository(
    plansRemoteDatasource: PlansRemoteDatasource(
      dio: ref.watch(dioProvider),
    ),
  );
});

// Get all plans provider
final plansFutureProvider = FutureProvider<List<PlansModel>>((ref) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  return ref.watch(plansRepositoryProvider).getPlans(language: languageCode);
});

final planByIdFutureProvider = FutureProvider.family<PlansModel, String>((
  ref,
  id,
) {
  return ref.watch(plansRepositoryProvider).getPlanById(id);
});

// Find plans with pagination provider
final findPlansPaginatedProvider =
    StateNotifierProvider<FindPlansNotifier, FindPlansState>((ref) {
      _logger.debug('🏗️ Creating FindPlansNotifier instance...');
      final repository = ref.watch(plansRepositoryProvider);
      final locale = ref.watch(localeProvider);
      _logger.debug('📝 Locale: ${locale.languageCode}');
      final notifier = FindPlansNotifier(
        repository: repository,
        languageCode: locale.languageCode,
      );
      _logger.debug('✅ FindPlansNotifier instance created');
      return notifier;
    });

// Plan search provider
final planSearchProvider =
    StateNotifierProvider<PlanSearchNotifier, PlanSearchState>((ref) {
      final repository = ref.watch(plansRepositoryProvider);
      final locale = ref.watch(localeProvider);
      return PlanSearchNotifier(
        repository: repository,
        languageCode: locale.languageCode,
      );
    });
