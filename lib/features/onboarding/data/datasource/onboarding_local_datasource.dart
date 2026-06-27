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

  /// Clears locally cached onboarding preferences.
  /// Only called on account deletion — never on logout or guest transitions.
  Future<void> clearPreferences() async {
    await _localStorageService.remove(StorageKeys.onboardingPreferences);
    _logger.info('Onboarding preferences cleared');
  }
}
