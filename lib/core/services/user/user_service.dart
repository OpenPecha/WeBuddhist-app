import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';

/// Service to manage user data and state
class UserService {
  final AuthRepository _authRepository;
  final LocalStorageService _localStorageService;

  User? _currentUser;
  bool _isInitialized = false;

  UserService({
    required AuthRepository authRepository,
    required LocalStorageService localStorageService,
  }) : _authRepository = authRepository,
       _localStorageService = localStorageService;

  /// Get current user (from memory or API)
  User? get currentUser => _currentUser;

  /// Check if user service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize user service by fetching user data from API
  Future<User?> initializeUser() async {
    try {
      debugPrint('🔄 Initializing user service...');

      // Fetch user data from API
      debugPrint('📡 Fetching user data from API...');
      final user = await _authRepository.getCurrentUser();
      debugPrint('User :::::: $user');

      if (user != null) {
        _currentUser = user;
        debugPrint(
          '✅ User data loaded: ${user.firstName} (${user.onboardingCompleted})',
        );

        // Cache user data locally for offline access
        await _localStorageService.setUserData(user.toJson());
      } else {
        debugPrint('❌ Failed to fetch user data from API');
        _currentUser = null;
      }

      _isInitialized = true;
      return _currentUser;
    } catch (e) {
      debugPrint('❌ Error initializing user service: $e');

      // Fallback to local data if API fails
      try {
        final localUserData = await _localStorageService.getUserData();
        if (localUserData != null) {
          _currentUser = User.fromJson(localUserData);
          debugPrint('📱 Using cached user data: ${_currentUser?.firstName}');
        }
      } catch (localError) {
        debugPrint('❌ Failed to load local user data: $localError');
        _currentUser = null;
      }

      _isInitialized = true;
      return _currentUser;
    }
  }

  /// Refresh user data from API
  Future<User?> refreshUser() async {
    try {
      debugPrint('🔄 Refreshing user data...');
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        _currentUser = user;
        await _localStorageService.setUserData(user.toJson());
        debugPrint('✅ User data refreshed: ${user.firstName}');
      }

      return _currentUser;
    } catch (e) {
      debugPrint('❌ Error refreshing user data: $e');
      return _currentUser;
    }
  }

  /// Update user data
  Future<void> updateUser(User user) async {
    _currentUser = user;
    debugPrint('User Service: Updating user data: ${user.toJson()}');
    await _localStorageService.setUserData(user.toJson());
    debugPrint('✅ User data updated: ${user.firstName}');
  }

  /// Clear user data
  Future<void> clearUser() async {
    _currentUser = null;
    await _localStorageService.clearUserData();
    debugPrint('🗑️ User data cleared');
  }

  /// Check if user has completed onboarding
  bool get hasCompletedOnboarding => _currentUser?.onboardingCompleted ?? false;
}
