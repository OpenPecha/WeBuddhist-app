import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/services/user/user_service.dart';
import 'package:flutter_pecha/features/onboarding/data/onboarding_local_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/models/onboarding_preferences.dart';

/// Repository for managing onboarding preferences
/// Aggregates local and remote datasources
class OnboardingRepository {
  const OnboardingRepository({
    required this.localDatasource,
    required this.remoteDatasource,
    required this.userService,
    required this.localeNotifier,
  });

  final OnboardingLocalDatasource localDatasource;
  final OnboardingRemoteDatasource remoteDatasource;
  final UserService userService;
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
        debugPrint('✅ App locale set to: ${prefs.preferredLanguage}');
      } catch (e) {
        debugPrint('⚠️ Failed to set app locale: $e');
        // Don't throw - continue with onboarding completion
      }
    }

    // Mark onboarding as complete
    await localDatasource.markOnboardingComplete();

    try {
      final currentUser = userService.currentUser;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(onboardingCompleted: true);
        await userService.updateUser(updatedUser);
        debugPrint('✅ User data updated: onboardingCompleted = true');
      } else {
        debugPrint('⚠️ No current user found to update onboarding status');
      }
    } catch (e) {
      debugPrint('❌ Failed to update user onboarding status: $e');
      // Don't throw - onboarding flag is still saved separately
    }
    debugPrint('✅ Onboarding completed and marked');
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
