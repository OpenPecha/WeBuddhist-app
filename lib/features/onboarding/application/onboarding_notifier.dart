import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_state.dart';
import 'package:flutter_pecha/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _logger = AppLogger('OnboardingNotifier');

/// Notifier for managing onboarding flow state.
///
/// Uses domain use cases for all data operations, following clean architecture.
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier({
    required LoadSavedPreferencesUseCase loadSavedPreferencesUseCase,
    required SaveOnboardingPreferencesUseCase saveOnboardingPreferencesUseCase,
    required CompleteOnboardingUseCase completeOnboardingUseCase,
    required ClearOnboardingPreferencesUseCase clearOnboardingPreferencesUseCase,
  })  : _loadSavedPreferencesUseCase = loadSavedPreferencesUseCase,
        _saveOnboardingPreferencesUseCase = saveOnboardingPreferencesUseCase,
        _completeOnboardingUseCase = completeOnboardingUseCase,
        _clearOnboardingPreferencesUseCase = clearOnboardingPreferencesUseCase,
        super(OnboardingState.initial()) {
    loadSavedPreferences();
  }

  final LoadSavedPreferencesUseCase _loadSavedPreferencesUseCase;
  final SaveOnboardingPreferencesUseCase _saveOnboardingPreferencesUseCase;
  final CompleteOnboardingUseCase _completeOnboardingUseCase;
  final ClearOnboardingPreferencesUseCase _clearOnboardingPreferencesUseCase;

  /// Load saved preferences from local storage on initialization.
  Future<void> loadSavedPreferences() async {
    try {
      final result = await _loadSavedPreferencesUseCase(const NoParams());
      result.fold(
        (failure) {
          _logger.error('Error loading saved preferences', failure);
        },
        (entity) {
          if (entity != null) {
            state = state.copyWithPreferences(entity);
            _logger.debug('Loaded saved preferences');
          }
        },
      );
    } catch (e) {
      _logger.error('Error loading saved preferences', e);
    }
  }

  /// Set preferred language and save locally.
  Future<void> setPreferredLanguage(String language) async {
    final updatedEntity = state.preferences.copyWith(primaryLanguage: language);
    state = state.copyWithPreferences(updatedEntity);
    await _savePreferences();
  }

  /// Set selected Buddhist paths and save locally.
  Future<void> setSelectedPaths(List<String> paths) async {
    final updatedEntity = state.preferences.copyWith(selectedPaths: paths);
    state = state.copyWithPreferences(updatedEntity);
    await _savePreferences();
  }

  /// Navigate to next page.
  void goToNextPage() {
    state = state.copyWithPage(state.currentPage + 1);
  }

  /// Navigate to previous page.
  void goToPreviousPage() {
    if (state.currentPage > 0) {
      state = state.copyWithPage(state.currentPage - 1);
    }
  }

  /// Save current preferences via use case.
  Future<void> _savePreferences() async {
    try {
      final result = await _saveOnboardingPreferencesUseCase(
        SavePreferencesParams(preferences: state.preferences),
      );
      result.fold(
        (failure) {
          _logger.error('Error saving preferences', failure);
          state = state.copyWithError(
            'Failed to save preferences: ${failure.message}',
          );
        },
        (_) {
          _logger.debug('Preferences saved successfully');
        },
      );
    } catch (e) {
      _logger.error('Error saving preferences', e);
      state = state.copyWithError('Failed to save preferences: $e');
    }
  }

  /// Submit preferences and complete onboarding.
  Future<void> submitPreferences() async {
    state = state.copyWithLoading(true);
    try {
      // Save preferences
      final saveResult = await _saveOnboardingPreferencesUseCase(
        SavePreferencesParams(preferences: state.preferences),
      );
      saveResult.fold(
        (failure) => _logger.error('Error saving preferences', failure),
        (_) => _logger.debug('Preferences saved successfully'),
      );

      // Complete onboarding
      final completeResult = await _completeOnboardingUseCase(const NoParams());
      completeResult.fold(
        (failure) => _logger.error('Error completing onboarding', failure),
        (_) => _logger.debug('Onboarding completed successfully'),
      );

      // TODO: Enable when API is ready — sync all preferences to backend
      // Add a SyncPreferencesToRemoteUseCase and call it here.

      state = state.copyWithLoading(false);
    } catch (e) {
      _logger.error('Error submitting preferences', e);
      state = state.copyWithLoading(false);
    }
  }

  /// Clear all preferences and reset state.
  Future<void> clearPreferences() async {
    try {
      final result = await _clearOnboardingPreferencesUseCase(const NoParams());
      result.fold(
        (failure) {
          _logger.error('Error clearing preferences', failure);
        },
        (_) {
          state = OnboardingState.initial();
          _logger.debug('Preferences cleared successfully');
        },
      );
    } catch (e) {
      _logger.error('Error clearing preferences', e);
    }
  }
}
