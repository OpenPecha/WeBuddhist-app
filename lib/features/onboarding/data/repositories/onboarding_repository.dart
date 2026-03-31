import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/models/onboarding_preferences.dart';
import 'package:flutter_pecha/features/onboarding/domain/entities/onboarding_preferences.dart' as domain;
import 'package:flutter_pecha/features/onboarding/domain/repositories/onboarding_repository.dart' as domain_repo;

final _logger = AppLogger('OnboardingRepository');

/// Repository implementation for managing onboarding preferences
///
/// This implements the domain repository interface and aggregates
/// local and remote datasources, returning Either<Failure, T> results.
class OnboardingRepositoryImpl implements domain_repo.OnboardingRepository {
  const OnboardingRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
    required this.userNotifier,
    required this.localeNotifier,
  });

  final OnboardingLocalDatasource localDatasource;
  final OnboardingRemoteDatasource remoteDatasource;
  final UserNotifier userNotifier;
  final LocaleNotifier localeNotifier;

  @override
  Future<Either<Failure, bool>> isOnboardingCompleted() async {
    try {
      final result = await localDatasource.hasCompletedOnboarding();
      return Right(result);
    } catch (e) {
      return Left(CacheFailure('Failed to check onboarding status: $e'));
    }
  }

  @override
  Future<Either<Failure, domain.OnboardingPreferences?>> getPreferences() async {
    try {
      final model = await localDatasource.loadPreferences();
      if (model == null) {
        return const Right(null);
      }
      // Convert model to entity
      final entity = model.toEntity(
        userId: '', // userId will be set by the caller
        completedAt: DateTime.now(),
      );
      return Right(entity);
    } catch (e) {
      return Left(CacheFailure('Failed to load preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, domain.OnboardingPreferences>> savePreferences(
    domain.OnboardingPreferences preferences,
  ) async {
    try {
      // Convert entity to model
      final model = OnboardingPreferences.fromEntity(preferences);
      await localDatasource.savePreferences(model);
      return Right(preferences);
    } catch (e) {
      return Left(CacheFailure('Failed to save preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearPreferences() async {
    try {
      await localDatasource.clearPreferences();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to clear preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, List<domain.OnboardingStep>>> getOnboardingSteps() async {
    try {
      // For now, return default onboarding steps
      // In a full implementation, this might come from a remote config
      final steps = <domain.OnboardingStep>[
        const domain.OnboardingStep(
          stepNumber: 1,
          title: 'Welcome',
          description: 'Let\'s get you set up',
          isCompleted: false,
        ),
        const domain.OnboardingStep(
          stepNumber: 2,
          title: 'Language',
          description: 'Choose your preferred language',
          isCompleted: false,
        ),
      ];
      return Right(steps);
    } catch (e) {
      return Left(ServerFailure('Failed to get onboarding steps: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> completeOnboarding() async {
    try {
      // Apply language preference to app locale if set
      final prefsModel = await localDatasource.loadPreferences();
      if (prefsModel?.preferredLanguage != null) {
        try {
          await localeNotifier.setLocaleFromOnboardingPreference(
            prefsModel!.preferredLanguage,
          );
          _logger.debug('App locale set to: ${prefsModel.preferredLanguage}');
        } catch (e) {
          _logger.warning('Failed to set app locale', e);
          // Don't throw - continue with onboarding completion
        }
      }

      // Mark onboarding as complete
      await localDatasource.markOnboardingComplete();

      // Update user's onboarding status via UserNotifier
      try {
        await userNotifier.updateOnboardingStatus(true);
      } catch (e) {
        _logger.warning('Failed to update user onboarding status', e);
        // Don't throw - onboarding flag is still saved separately
      }
      _logger.info('Onboarding completed');

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to complete onboarding: $e'));
    }
  }
}

/// Legacy repository class for backward compatibility.
///
/// This class is deprecated and should not be used for new code.
/// Use OnboardingRepositoryImpl which implements the proper interface.
@Deprecated('Use OnboardingRepositoryImpl instead')
class OnboardingRepositoryLegacy {
  OnboardingRepositoryLegacy({
    required this.localDatasource,
    required this.remoteDatasource,
    required this.userNotifier,
    required this.localeNotifier,
  });

  final OnboardingLocalDatasource localDatasource;
  final OnboardingRemoteDatasource remoteDatasource;
  final UserNotifier userNotifier;
  final LocaleNotifier localeNotifier;

  /// Save preferences both locally and optionally remotely
  Future<void> savePreferences(
    OnboardingPreferences prefs, {
    bool saveRemote = true,
  }) async {
    // Always save locally first
    await localDatasource.savePreferences(prefs);
  }

  /// Load preferences from local storage
  Future<OnboardingPreferences?> loadPreferences() async {
    return await localDatasource.loadPreferences();
  }

  /// Complete onboarding: save preferences and mark as complete
  Future<void> completeOnboarding(OnboardingPreferences prefs) async {
    // Save preferences locally and remotely
    await savePreferences(prefs, saveRemote: true);

    // Apply language preference to app locale if provided
    if (prefs.preferredLanguage != null) {
      try {
        await localeNotifier.setLocaleFromOnboardingPreference(
          prefs.preferredLanguage,
        );
        _logger.debug('App locale set to: ${prefs.preferredLanguage}');
      } catch (e) {
        _logger.warning('Failed to set app locale', e);
        // Don't throw - continue with onboarding completion
      }
    }

    // Mark onboarding as complete
    await localDatasource.markOnboardingComplete();

    // Update user's onboarding status via UserNotifier
    try {
      await userNotifier.updateOnboardingStatus(true);
    } catch (e) {
      _logger.warning('Failed to update user onboarding status', e);
      // Don't throw - onboarding flag is still saved separately
    }
    _logger.info('Onboarding completed');
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    return await localDatasource.hasCompletedOnboarding();
  }

  /// Clear all preferences and completion status
  Future<void> clearPreferences() async {
    await localDatasource.clearPreferences();
  }
}
