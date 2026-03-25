import 'package:flutter_pecha/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:flutter_pecha/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Repository Providers ==========

/// Provider for OnboardingRepository implementation (domain interface).
final onboardingDomainRepositoryProvider = Provider<OnboardingRepositoryImpl>((ref) {
  final localDatasource = ref.watch(onboardingLocalDatasourceProvider);
  final remoteDatasource = ref.watch(onboardingRemoteDatasourceProvider);
  final userNotifier = ref.watch(userProvider.notifier);
  final localeNotifier = ref.watch(localeProvider.notifier);
  return OnboardingRepositoryImpl(
    localDatasource: localDatasource,
    remoteDatasource: remoteDatasource,
    userNotifier: userNotifier,
    localeNotifier: localeNotifier,
  );
});

// ========== Use Case Providers ==========

/// Provider for GetOnboardingStatusUseCase.
final getOnboardingStatusUseCaseProvider = Provider<GetOnboardingStatusUseCase>((ref) {
  final repository = ref.watch(onboardingDomainRepositoryProvider);
  return GetOnboardingStatusUseCase(repository);
});

/// Provider for SaveOnboardingPreferencesUseCase.
final saveOnboardingPreferencesUseCaseProvider = Provider<SaveOnboardingPreferencesUseCase>((ref) {
  final repository = ref.watch(onboardingDomainRepositoryProvider);
  return SaveOnboardingPreferencesUseCase(repository);
});

/// Provider for CompleteOnboardingUseCase.
final completeOnboardingUseCaseProvider = Provider<CompleteOnboardingUseCase>((ref) {
  final repository = ref.watch(onboardingDomainRepositoryProvider);
  return CompleteOnboardingUseCase(repository);
});
