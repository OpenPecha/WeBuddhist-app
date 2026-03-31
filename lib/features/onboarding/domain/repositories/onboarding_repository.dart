import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/onboarding/domain/entities/onboarding_preferences.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Onboarding repository interface.
abstract class OnboardingRepository extends Repository {
  /// Get onboarding status.
  Future<Either<Failure, bool>> isOnboardingCompleted();

  /// Get onboarding preferences.
  Future<Either<Failure, OnboardingPreferences?>> getPreferences();

  /// Save onboarding preferences.
  Future<Either<Failure, OnboardingPreferences>> savePreferences(OnboardingPreferences preferences);

  /// Clear onboarding preferences.
  Future<Either<Failure, void>> clearPreferences();

  /// Get onboarding steps.
  Future<Either<Failure, List<OnboardingStep>>> getOnboardingSteps();

  /// Complete onboarding.
  Future<Either<Failure, void>> completeOnboarding();
}
