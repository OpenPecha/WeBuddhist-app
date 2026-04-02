import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/models/onboarding_preferences.dart';
import 'package:flutter_pecha/features/onboarding/domain/entities/onboarding_preferences.dart' as domain;
import 'package:flutter_pecha/features/onboarding/domain/repositories/onboarding_repository.dart' as domain_repo;

final _logger = AppLogger('OnboardingRepository');

/// Repository implementation for managing onboarding preferences.
///
/// Implements the domain repository interface. Aggregates local and remote
/// datasources, returning Either&lt;Failure, T&gt; results.
class OnboardingRepositoryImpl implements domain_repo.OnboardingRepository {
  const OnboardingRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
  });

  final OnboardingLocalDatasource localDatasource;
  final OnboardingRemoteDatasource remoteDatasource;

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
      final entity = model.toEntity(
        userId: '',
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
      final model = OnboardingPreferences.fromEntity(preferences);
      // Always save locally first
      await localDatasource.savePreferences(model);

      // TODO: Enable when API is ready — sync to backend
      //await _syncToRemote(model);

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
      // Mark onboarding as complete in local storage
      await localDatasource.markOnboardingComplete();
      _logger.info('Onboarding completed');

      // TODO: Enable when API is ready — final sync to backend
      // final prefsModel = await localDatasource.loadPreferences();
      // if (prefsModel != null) {
      //   await _syncToRemote(prefsModel);
      // }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to complete onboarding: $e'));
    }
  }

  /// Sync preferences to backend.
  ///
  /// TODO: Uncomment when API is ready. The remote datasource is already
  /// wired up via Dio. Just call this method wherever sync is needed.
  // Future<void> _syncToRemote(OnboardingPreferences model) async {
  //   await remoteDatasource.saveOnboardingPreferences(model);
  //   _logger.info('Onboarding preferences synced to backend');
  // }
}
