import 'dart:convert';

import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/onboarding/data/models/onboarding_preferences.dart';

final _logger = AppLogger('OnboardingLocalDatasource');

/// Local datasource for onboarding preferences using SharedPreferences.
class OnboardingLocalDatasource {
  OnboardingLocalDatasource({required LocalStorageService localStorageService})
      : _localStorageService = localStorageService;

  final LocalStorageService _localStorageService;

  /// Save preferences to local storage.
  Future<void> savePreferences(OnboardingPreferences prefs) async {
    final jsonString = json.encode(prefs.toJson());
    await _localStorageService.set<String>(
      StorageKeys.onboardingPreferences,
      jsonString,
    );
    _logger.debug('Preferences saved');
  }

  /// Load preferences from local storage.
  Future<OnboardingPreferences?> loadPreferences() async {
    final jsonString = await _localStorageService.get<String>(
      StorageKeys.onboardingPreferences,
    );
    if (jsonString == null) return null;

    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return OnboardingPreferences.fromJson(jsonMap);
    } catch (e) {
      _logger.error('Failed to parse saved preferences', e);
      return null;
    }
  }

  /// Clears all onboarding data for the current user.
  /// Only called on account deletion — never on logout or guest transitions.
  Future<void> clearPreferences() async {
    await _localStorageService.remove(StorageKeys.onboardingPreferences);
    await _localStorageService.remove(StorageKeys.onboardingCompleted);

    final userId = await _localStorageService.get<String>(
      StorageKeys.currentUserId,
    );
    if (userId != null && userId.isNotEmpty) {
      await _localStorageService.remove(
        StorageKeys.onboardingCompletedForUser(userId),
      );
    }
    _logger.info('Onboarding data cleared');
  }

  /// Returns true if the current user has already completed onboarding.
  ///
  /// Checks the per-user key first (keyed by [StorageKeys.currentUserId]).
  /// Falls back to the legacy device-level key and migrates it on first read,
  /// so existing users are not asked to repeat onboarding after an update.
  Future<bool> hasCompletedOnboarding() async {
    final userId = await _localStorageService.get<String>(
      StorageKeys.currentUserId,
    );

    if (userId != null && userId.isNotEmpty) {
      final userKey = StorageKeys.onboardingCompletedForUser(userId);
      final perUserValue = await _localStorageService.get<bool>(userKey);

      if (perUserValue != null) return perUserValue;

      // One-time migration: promote the legacy device-level flag to the
      // per-user key so existing users are not shown onboarding again.
      // The legacy key is cleared after migration so it cannot be
      // incorrectly adopted by a different user logging in later.
      final legacy = await _localStorageService.get<bool>(
        StorageKeys.onboardingCompleted,
      );
      if (legacy == true) {
        await _localStorageService.set(userKey, true);
        await _localStorageService.remove(StorageKeys.onboardingCompleted);
        _logger.info('Migrated onboarding completion to per-user key');
        return true;
      }
      return false;
    }

    // Fallback: no user ID in storage (safe default, should not occur
    // after a normal login flow).
    return await _localStorageService.get<bool>(
          StorageKeys.onboardingCompleted,
        ) ??
        false;
  }

  /// Marks onboarding as complete for the current user.
  ///
  /// Writes to the per-user key when a user ID is available (primary path).
  /// Only falls back to the legacy device-level key when no user ID exists,
  /// to avoid the legacy key being reused as a false positive for other users.
  Future<void> markOnboardingComplete() async {
    final userId = await _localStorageService.get<String>(
      StorageKeys.currentUserId,
    );

    if (userId != null && userId.isNotEmpty) {
      await _localStorageService.set(
        StorageKeys.onboardingCompletedForUser(userId),
        true,
      );
    } else {
      // Only write the legacy device-level key when no user ID is available.
      // With per-user tracking active the legacy key is not needed and would
      // cause false positives for other users via the migration path.
      await _localStorageService.set<bool>(
          StorageKeys.onboardingCompleted, true);
    }
    _logger.info(
      'Onboarding marked complete${userId != null ? " for $userId" : ""}',
    );
  }
}
