import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/data/models/user_model.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('UserNotifier');

/// UserNotifier manages user state and provides reactive user data to app
///
/// This is single source of truth for user profile data.
/// Follows industry best practices:
/// - Separation of concerns (Auth != User Profile)
/// - Single source of truth
/// - Reactive state management
/// - Proper error handling
class UserNotifier extends StateNotifier<UserState> {
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LocalStorageService _localStorageService;

  UserNotifier({
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required LocalStorageService localStorageService,
  }) : _getCurrentUserUseCase = getCurrentUserUseCase,
       _localStorageService = localStorageService,
       super(const UserState.initial());

  /// Initialize user data from API or local cache
  /// Call this after successful authentication
  Future<void> initializeUser() async {
    _logger.debug('Initializing user data');
    state = const UserState.loading();

    final userResult = await _getCurrentUserUseCase(const NoParams());

    // First, get the onboarding status separately
    final localOnboardingCompleted =
        await _localStorageService.getOnboardingCompleted();

    userResult.fold(
      (failure) {
        _logger.error('Error getting user from API: ${failure.message}');
        // Try local cache on error
        _loadFromLocalCache();
      },
      (user) {
        _logger.info('User data loaded from API: ${user.displayName}');

        // Update user with local onboarding status
        final userWithLocalOnboarding = user.copyWith(
          onboardingCompleted: localOnboardingCompleted,
        );

        state = UserState.loaded(userWithLocalOnboarding);

        // Cache locally for offline access
        _cacheUserLocally(userWithLocalOnboarding);
      },
    );
  }

  /// Refresh user data from API
  Future<void> refreshUser() async {
    final userResult = await _getCurrentUserUseCase(const NoParams());

    // First, get the onboarding status separately
    final localOnboardingCompleted =
        await _localStorageService.getOnboardingCompleted();

    userResult.fold(
      (failure) {
        _logger.error('Error refreshing user: ${failure.message}');
        // Keep current state on refresh error
        state = state.copyWith(errorMessage: 'Failed to refresh user data');
      },
      (user) {
        _logger.debug('User data refreshed: ${user.displayName}');

        // Update user with local onboarding status
        final userWithLocalOnboarding = user.copyWith(
          onboardingCompleted: localOnboardingCompleted,
        );

        state = UserState.loaded(userWithLocalOnboarding);
        _cacheUserLocally(userWithLocalOnboarding);
      },
    );
  }

  /// Update user data (optimistic update + API sync)
  Future<void> updateUser(User updatedUser) async {
    try {
      // Optimistic update
      state = UserState.loaded(updatedUser);

      // Cache locally
      await _cacheUserLocally(updatedUser);

      // Sync onboarding status separately to local storage
      await _localStorageService.set(
        StorageKeys.onboardingCompleted,
        updatedUser.onboardingCompleted,
      );

      _logger.debug('User data updated: ${updatedUser.displayName}');
    } catch (e) {
      _logger.error('Error updating user', e);
      state = state.copyWith(errorMessage: 'Failed to update user data');
    }
  }

  /// Update onboarding status
  Future<void> updateOnboardingStatus(bool completed) async {
    try {
      // Update local storage first (primary source of truth)
      await _localStorageService.set(
        StorageKeys.onboardingCompleted,
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

      _logger.debug('Onboarding status updated: $completed');
    } catch (e) {
      _logger.error('Error updating onboarding status', e);
    }
  }

  /// Clear user data (on logout)
  Future<void> clearUser() async {
    try {
      state = const UserState.initial();

      // Clear local cache
      await _localStorageService.clearUserData();

      _logger.info('User data cleared');
    } catch (e) {
      _logger.error('Error clearing user', e);
    }
  }

  /// Load user from local cache
  Future<void> _loadFromLocalCache() async {
    try {
      final localUserData = await _localStorageService.getUserData();

      if (localUserData != null) {
        final userModel = UserModel.fromJson(localUserData);
        final user = userModel.toEntity();
        _logger.debug('Loaded user from cache: ${user.displayName}');
        state = UserState.loaded(user);
      } else {
        _logger.debug('No user data in cache');
        state = const UserState.error('No user data available');
      }
    } catch (e) {
      _logger.error('Error loading user from cache', e);
      state = const UserState.error('Failed to load user data from cache');
    }
  }

  /// Cache user data locally
  Future<void> _cacheUserLocally(User user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await _localStorageService.setUserData(userModel.toJson());
    } catch (e) {
      _logger.error('Error caching user data', e);
    }
  }
}
