import 'package:flutter_pecha/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Use Case Providers ==========

/// Provider for GetOnboardingStatusUseCase.
final getOnboardingStatusUseCaseProvider = Provider<GetOnboardingStatusUseCase>(
  (ref) {
    final repository = ref.watch(onboardingRepositoryProvider);
    return GetOnboardingStatusUseCase(repository);
  },
);

/// Provider for LoadSavedPreferencesUseCase.
final loadSavedPreferencesUseCaseProvider =
    Provider<LoadSavedPreferencesUseCase>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return LoadSavedPreferencesUseCase(repository);
});

/// Provider for SaveOnboardingPreferencesUseCase.
final saveOnboardingPreferencesUseCaseProvider =
    Provider<SaveOnboardingPreferencesUseCase>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return SaveOnboardingPreferencesUseCase(repository);
});

/// Provider for CompleteOnboardingUseCase.
final completeOnboardingUseCaseProvider = Provider<CompleteOnboardingUseCase>(
  (ref) {
    final repository = ref.watch(onboardingRepositoryProvider);
    return CompleteOnboardingUseCase(repository);
  },
);

/// Provider for ClearOnboardingPreferencesUseCase.
final clearOnboardingPreferencesUseCaseProvider =
    Provider<ClearOnboardingPreferencesUseCase>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return ClearOnboardingPreferencesUseCase(repository);
});
