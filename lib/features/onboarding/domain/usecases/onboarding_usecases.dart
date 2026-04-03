import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/onboarding/domain/entities/onboarding_preferences.dart';
import 'package:flutter_pecha/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Get onboarding status use case.
class GetOnboardingStatusUseCase extends UseCase<bool, NoParams> {
  final OnboardingRepository _repository;

  GetOnboardingStatusUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await _repository.isOnboardingCompleted();
  }
}

/// Load saved preferences use case.
class LoadSavedPreferencesUseCase
    extends UseCase<OnboardingPreferences?, NoParams> {
  final OnboardingRepository _repository;

  LoadSavedPreferencesUseCase(this._repository);

  @override
  Future<Either<Failure, OnboardingPreferences?>> call(NoParams params) async {
    return await _repository.getPreferences();
  }
}

/// Save onboarding preferences use case.
class SaveOnboardingPreferencesUseCase
    extends UseCase<OnboardingPreferences, SavePreferencesParams> {
  final OnboardingRepository _repository;

  SaveOnboardingPreferencesUseCase(this._repository);

  @override
  Future<Either<Failure, OnboardingPreferences>> call(
    SavePreferencesParams params,
  ) async {
    return await _repository.savePreferences(params.preferences);
  }
}

class SavePreferencesParams {
  final OnboardingPreferences preferences;
  const SavePreferencesParams({required this.preferences});
}

/// Complete onboarding use case.
class CompleteOnboardingUseCase extends UseCase<void, NoParams> {
  final OnboardingRepository _repository;

  CompleteOnboardingUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await _repository.completeOnboarding();
  }
}

/// Clear onboarding preferences use case.
class ClearOnboardingPreferencesUseCase extends UseCase<void, NoParams> {
  final OnboardingRepository _repository;

  ClearOnboardingPreferencesUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await _repository.clearPreferences();
  }
}
