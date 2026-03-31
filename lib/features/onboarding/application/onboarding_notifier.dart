import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_state.dart';
import 'package:flutter_pecha/features/onboarding/domain/repositories/onboarding_repository.dart' as domain_repo;
import 'package:flutter_pecha/features/onboarding/domain/entities/onboarding_preferences.dart' as domain;
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _logger = AppLogger('OnboardingNotifier');

/// Notifier for managing onboarding flow state
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._repository) : super(OnboardingState.initial()) {
    loadSavedPreferences();
  }

  final domain_repo.OnboardingRepository _repository;

  /// Load saved preferences from local storage on initialization
  Future<void> loadSavedPreferences() async {
    try {
      final result = await _repository.getPreferences();
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

  /// Set preferred language and save locally
  Future<void> setPreferredLanguage(String language) async {
    // Update the entity directly using copyWith
    final updatedEntity = state.preferences.copyWith(primaryLanguage: language);
    state = state.copyWithPreferences(updatedEntity);
    await savePreferencesLocally();
  }

  /// Navigate to next page
  void goToNextPage() {
    state = state.copyWithPage(state.currentPage + 1);
  }

  /// Navigate to previous page
  void goToPreviousPage() {
    if (state.currentPage > 0) {
      state = state.copyWithPage(state.currentPage - 1);
    }
  }

  /// Save preferences to local storage
  Future<void> savePreferencesLocally() async {
    try {
      final result = await _repository.savePreferences(state.preferences);
      result.fold(
        (failure) {
          _logger.error('Error saving preferences locally', failure);
          state = state.copyWithError('Failed to save preferences: ${failure.message}');
        },
        (_) {
          _logger.debug('Preferences saved successfully');
        },
      );
    } catch (e) {
      _logger.error('Error saving preferences locally', e);
      state = state.copyWithError('Failed to save preferences: $e');
    }
  }

  /// Submit preferences to local storage and mark onboarding complete
  Future<void> submitPreferences() async {
    state = state.copyWithLoading(true);
    try {
      // First save preferences
      final saveResult = await _repository.savePreferences(state.preferences);
      saveResult.fold(
        (failure) {
          _logger.error('Error saving preferences', failure);
        },
        (_) {
          _logger.debug('Preferences saved successfully');
        },
      );

      // Then complete onboarding
      final completeResult = await _repository.completeOnboarding();
      completeResult.fold(
        (failure) {
          _logger.error('Error completing onboarding', failure);
        },
        (_) {
          _logger.debug('Onboarding completed successfully');
        },
      );

      state = state.copyWithLoading(false);
    } catch (e) {
      _logger.error('Error submitting preferences', e);
      // Don't show error to user, preferences are saved locally
      state = state.copyWithLoading(false);
    }
  }

  /// Clear all preferences and reset state
  Future<void> clearPreferences() async {
    try {
      final result = await _repository.clearPreferences();
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
