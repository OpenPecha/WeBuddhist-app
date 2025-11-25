import 'dart:convert';
import 'package:flutter_pecha/core/constants/app_storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/onboarding/models/onboarding_preferences.dart';

/// Local datasource for onboarding preferences using SharedPreferences
class OnboardingLocalDatasource {
  const OnboardingLocalDatasource({required this.localStorageService});

  final LocalStorageService localStorageService;

  /// Save preferences to local storage
  Future<void> savePreferences(OnboardingPreferences prefs) async {
    final jsonString = json.encode(prefs.toJson());
    await localStorageService.set<String>(
      AppStorageKeys.onboardingPreferences,
      jsonString,
    );
  }

  /// Load preferences from local storage
  Future<OnboardingPreferences?> loadPreferences() async {
    final jsonString = await localStorageService.get<String>(
      AppStorageKeys.onboardingPreferences,
    );
    if (jsonString == null) return null;
    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return OnboardingPreferences.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Clear preferences from local storage
  Future<void> clearPreferences() async {
    await localStorageService.remove(AppStorageKeys.onboardingPreferences);
    await localStorageService.remove(AppStorageKeys.onboardingCompleted);
  }

  /// Check if onboarding has been completed
  Future<bool> hasCompletedOnboarding() async {
    final completed = await localStorageService.get<bool>(
      AppStorageKeys.onboardingCompleted,
    );
    return completed ?? false;
  }

  /// Mark onboarding as complete
  Future<void> markOnboardingComplete() async {
    await localStorageService.set<bool>(
      AppStorageKeys.onboardingCompleted,
      true,
    );
  }
}
