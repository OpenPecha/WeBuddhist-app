import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/constants/app_storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/application/user_state.dart';
import 'package:flutter_pecha/features/auth/data/providers/auth_providers.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UserNotifier manages user state and provides reactive user data to the app
///
/// This is the single source of truth for user profile data.
/// Follows industry best practices:
/// - Separation of concerns (Auth != User Profile)
/// - Single source of truth
/// - Reactive state management
/// - Proper error handling
class UserNotifier extends StateNotifier<UserState> {
  final AuthRepository _authRepository;
  final LocalStorageService _localStorageService;

  UserNotifier({
    required AuthRepository authRepository,
    required LocalStorageService localStorageService,
  }) : _authRepository = authRepository,
       _localStorageService = localStorageService,
       super(const UserState.initial());

  /// Initialize user data from API or local cache
  /// Call this after successful authentication
  Future<void> initializeUser() async {
    try {
      debugPrint('🔄 [UserNotifier] Initializing user data...');
      state = const UserState.loading();

      // Try to fetch from API first
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        debugPrint(
          '✅ [UserNotifier] User data loaded from API: ${user.displayName}',
        );

        // Preserve local onboarding status (backend doesn't store this)
        final localOnboardingCompleted =
            await _localStorageService.get<bool>(
              AppStorageKeys.onboardingCompleted,
            ) ??
            false;

        // Update user with local onboarding status
        final userWithLocalOnboarding = user.copyWith(
          onboardingCompleted: localOnboardingCompleted,
        );

        state = UserState.loaded(userWithLocalOnboarding);

        // Cache locally for offline access
        await _cacheUserLocally(userWithLocalOnboarding);

        debugPrint(
          '📋 [UserNotifier] Preserved local onboarding status: $localOnboardingCompleted',
        );
      } else {
        // Fallback to local cache
        debugPrint('⚠️ [UserNotifier] No user from API, trying local cache...');
        await _loadFromLocalCache();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [UserNotifier] Error initializing user: $e');
      debugPrint('Stack trace: $stackTrace');

      // Try local cache on error
      try {
        await _loadFromLocalCache();
      } catch (cacheError) {
        state = UserState.error('Failed to load user data: ${e.toString()}');
      }
    }
  }

  /// Refresh user data from API
  Future<void> refreshUser() async {
    try {
      debugPrint('🔄 [UserNotifier] Refreshing user data...');

      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        debugPrint('✅ [UserNotifier] User data refreshed: ${user.displayName}');

        // Preserve local onboarding status (backend doesn't store this)
        final localOnboardingCompleted =
            await _localStorageService.get<bool>(
              AppStorageKeys.onboardingCompleted,
            ) ??
            false;

        // Update user with local onboarding status
        final userWithLocalOnboarding = user.copyWith(
          onboardingCompleted: localOnboardingCompleted,
        );

        state = UserState.loaded(userWithLocalOnboarding);
        await _cacheUserLocally(userWithLocalOnboarding);

        debugPrint(
          '📋 [UserNotifier] Preserved local onboarding status: $localOnboardingCompleted',
        );
      }
    } catch (e) {
      debugPrint('❌ [UserNotifier] Error refreshing user: $e');
      // Keep current state on refresh error
      state = state.copyWith(errorMessage: 'Failed to refresh user data');
    }
  }

  /// Update user data (optimistic update + API sync)
  Future<void> updateUser(User updatedUser) async {
    try {
      debugPrint('🔄 [UserNotifier] Updating user data...');

      // Optimistic update
      state = UserState.loaded(updatedUser);

      // Cache locally
      await _cacheUserLocally(updatedUser);

      // Sync onboarding status separately to local storage
      await _localStorageService.set(
        AppStorageKeys.onboardingCompleted,
        updatedUser.onboardingCompleted,
      );

      debugPrint(
        '✅ [UserNotifier] User data updated: ${updatedUser.displayName}',
      );
    } catch (e) {
      debugPrint('❌ [UserNotifier] Error updating user: $e');
      state = state.copyWith(errorMessage: 'Failed to update user data');
    }
  }

  /// Update onboarding status
  Future<void> updateOnboardingStatus(bool completed) async {
    try {
      debugPrint('🔄 [UserNotifier] Updating onboarding status: $completed');

      // Update local storage first (primary source of truth)
      await _localStorageService.set(
        AppStorageKeys.onboardingCompleted,
        completed,
      );

      // Update user object if it exists
      if (state.user != null) {
        final updatedUser = state.user!.copyWith(
          onboardingCompleted: completed,
        );
        state = UserState.loaded(updatedUser);
        await _cacheUserLocally(updatedUser);
      }

      debugPrint('✅ [UserNotifier] Onboarding status updated: $completed');
    } catch (e) {
      debugPrint('❌ [UserNotifier] Error updating onboarding status: $e');
    }
  }

  /// Clear user data (on logout)
  Future<void> clearUser() async {
    try {
      debugPrint('🗑️ [UserNotifier] Clearing user data...');

      state = const UserState.initial();

      // Clear local cache
      await _localStorageService.clearUserData();

      debugPrint('✅ [UserNotifier] User data cleared');
    } catch (e) {
      debugPrint('❌ [UserNotifier] Error clearing user: $e');
    }
  }

  /// Load user from local cache
  Future<void> _loadFromLocalCache() async {
    final localUserData = await _localStorageService.getUserData();

    if (localUserData != null) {
      final user = User.fromJson(localUserData);
      debugPrint(
        '📱 [UserNotifier] Loaded user from cache: ${user.displayName}',
      );
      state = UserState.loaded(user);
    } else {
      debugPrint('⚠️ [UserNotifier] No user data in cache');
      state = const UserState.error('No user data available');
    }
  }

  /// Cache user data locally
  Future<void> _cacheUserLocally(User user) async {
    await _localStorageService.setUserData(user.toJson());
  }
}

/// Provider for UserNotifier
/// This is the main provider for accessing user state throughout the app
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final localStorageService = ref.watch(localStorageServiceProvider);

  return UserNotifier(
    authRepository: authRepository,
    localStorageService: localStorageService,
  );
});
