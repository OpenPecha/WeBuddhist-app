// Riverpod provider and logic for authentication state.
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/clear_guest_mode_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/continue_as_guest_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/get_credentials_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/has_valid_credentials_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/initialize_auth_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/is_guest_mode_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Authentication state
///
/// Handles ONLY authentication concerns:
/// - Login/logout status
/// - Guest mode
/// - Auth loading states
/// - Auth errors
///
/// User profile data is now managed by UserNotifier (userProvider)
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final bool isGuest;
  final String? errorMessage;

  const AuthState({
    required this.isLoggedIn,
    this.isGuest = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    bool? isGuest,
    String? errorMessage,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    isLoading: isLoading ?? this.isLoading,
    isGuest: isGuest ?? this.isGuest,
    errorMessage: errorMessage,
  );

  AuthState clearError() => copyWith(errorMessage: '');
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final InitializeAuthUseCase _initializeAuthUseCase;
  final HasValidCredentialsUseCase _hasValidCredentialsUseCase;
  final GetCredentialsUseCase _getCredentialsUseCase;
  final ContinueAsGuestUseCase _continueAsGuestUseCase;
  final IsGuestModeUseCase _isGuestModeUseCase;
  final ClearGuestModeUseCase _clearGuestModeUseCase;
  final LogoutUseCase _localLogoutUseCase;
  final Ref ref;
  final _logger = AppLogger('AuthNotifier');

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required InitializeAuthUseCase initializeAuthUseCase,
    required HasValidCredentialsUseCase hasValidCredentialsUseCase,
    required GetCredentialsUseCase getCredentialsUseCase,
    required ContinueAsGuestUseCase continueAsGuestUseCase,
    required IsGuestModeUseCase isGuestModeUseCase,
    required ClearGuestModeUseCase clearGuestModeUseCase,
    required LogoutUseCase localLogoutUseCase,
    required this.ref,
  })  : _loginUseCase = loginUseCase,
        _initializeAuthUseCase = initializeAuthUseCase,
        _hasValidCredentialsUseCase = hasValidCredentialsUseCase,
        _getCredentialsUseCase = getCredentialsUseCase,
        _continueAsGuestUseCase = continueAsGuestUseCase,
        _isGuestModeUseCase = isGuestModeUseCase,
        _clearGuestModeUseCase = clearGuestModeUseCase,
        _localLogoutUseCase = localLogoutUseCase,
        super(const AuthState(isLoggedIn: false, isLoading: true)) {
    _restoreLoginState();
  }

  Future<void> _restoreLoginState() async {
    _logger.debug('Restoring login state');

    // Initialize auth
    final initResult = await _initializeAuthUseCase(const NoParams());
    initResult.fold(
      (failure) {
        _logger.error('Failed to initialize auth: ${failure.message}');
      },
      (_) {
        _logger.debug('Auth initialized successfully');
      },
    );

    // Check if we have any credentials at all
    final credentialsResult = await _hasValidCredentialsUseCase(const NoParams());
    credentialsResult.fold(
      (failure) {
        _logger.error('Failed to check credentials: ${failure.message}');
        // Fall through to check guest mode
      },
      (hasCredentials) {
        _logger.debug('Credentials valid: $hasCredentials');

        if (hasCredentials) {
          _restoreCredentials();
        } else {
          _checkGuestMode();
        }
      },
    );
  }

  Future<void> _restoreCredentials() async {
    final credentialsResult = await _getCredentialsUseCase(const NoParams());
    credentialsResult.fold(
      (failure) {
        _logger.error('Failed to get credentials: ${failure.message}');
        _checkGuestMode();
      },
      (credentials) {
        // Validate credentials were actually retrieved
        if (credentials != null && credentials.user.sub.isNotEmpty) {
          state = state.copyWith(
            isLoggedIn: true,
            isLoading: false,
            isGuest: false,
            errorMessage: null,
          );
          _logger.info('Login state restored for user: ${credentials.user.sub}');

          // Initialize user data
          try {
            ref.read(userProvider.notifier).initializeUser();
          } catch (e) {
            _logger.warning('Could not initialize user data', e);
            // Non-critical, user can still use the app
          }
        } else {
          _logger.debug('Credentials check returned null or invalid user');
          _checkGuestMode();
        }
      },
    );
  }

  Future<void> _checkGuestMode() async {
    _logger.debug('No valid credentials found, checking guest mode');

    final guestModeResult = await _isGuestModeUseCase(const NoParams());
    guestModeResult.fold(
      (failure) {
        _logger.error('Failed to check guest mode: ${failure.message}');
        _setLoggedOutState();
      },
      (isGuest) {
        if (isGuest) {
          // Restore guest mode
          state = state.copyWith(
            isLoggedIn: true,
            isLoading: false,
            isGuest: true,
            errorMessage: null,
          );
          _logger.info('Guest mode restored from preferences');
        } else {
          // No credentials and not guest mode, user needs to log in
          _setLoggedOutState();
        }
      },
    );
  }

  void _setLoggedOutState() {
    state = state.copyWith(
      isLoggedIn: false,
      isLoading: false,
      isGuest: false,
    );
    _logger.info('No valid credentials or guest mode found, showing login');
  }

  Future<void> _handleAuthFailure() async {
    final logoutResult = await _localLogoutUseCase(const NoParams());
    logoutResult.fold(
      (failure) {
        _logger.warning('Failed to clear credentials during logout: ${failure.message}');
      },
      (_) {
        _logger.debug('Credentials cleared during failure handling');
      },
    );

    state = state.copyWith(
      isLoggedIn: false,
      isLoading: false,
      isGuest: false,
    );
  }

  Future<void> login({String? connection}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final loginResult = await _loginUseCase(LoginParams(connection: connection));
    loginResult.fold(
      (failure) {
        _logger.error('Login failed: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed: ${failure.message}',
        );
      },
      (credentials) {
        if (credentials != null) {
          _handleSuccessfulLogin(credentials);
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Login was cancelled or failed',
          );
        }
      },
    );
  }

  Future<void> _handleSuccessfulLogin(Credentials credentials) async {
    // Check if user was previously in guest mode
    final guestModeResult = await _isGuestModeUseCase(const NoParams());
    guestModeResult.fold(
      (failure) {
        _logger.warning('Failed to check guest mode: ${failure.message}');
      },
      (wasPreviouslyGuest) {
        final wasGuest = state.isGuest || wasPreviouslyGuest;

        // Clear guest mode when user authenticates
        _clearGuestModeAndOnboarding(wasGuest);
      },
    );

    state = state.copyWith(
      isLoggedIn: true,
      isLoading: false,
      isGuest: false,
      errorMessage: null,
    );
    _logger.info('User authenticated, guest mode cleared');

    // Fetch and save user data from backend on first login
    try {
      await ref.read(userProvider.notifier).initializeUser();
      _logger.info('User data fetched and saved locally');
    } catch (e) {
      _logger.warning('Failed to fetch user data: $e');
      // Don't fail the login if user data fetch fails
    }
  }

  Future<void> _clearGuestModeAndOnboarding(bool wasGuest) async {
    final clearGuestResult = await _clearGuestModeUseCase(const NoParams());
    clearGuestResult.fold(
      (failure) {
        _logger.warning('Failed to clear guest mode: ${failure.message}');
      },
      (_) {
        _logger.debug('Guest mode cleared');
      },
    );

    // If user was a guest, clear onboarding completion so they see onboarding
    if (wasGuest) {
      try {
        final onboardingRepo = ref.read(onboardingRepositoryProvider);
        await onboardingRepo.clearPreferences();
        _logger.info('Guest converted to authenticated user, onboarding reset');
      } catch (e) {
        _logger.warning('Failed to clear guest onboarding', e);
      }
    }
  }

  // continue as guest
  Future<void> continueAsGuest() async {
    // Persist guest mode preference
    final guestResult = await _continueAsGuestUseCase(const NoParams());
    guestResult.fold(
      (failure) {
        _logger.error('Failed to continue as guest: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to continue as guest: ${failure.message}',
        );
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          isGuest: true,
        );
        _logger.info('Guest mode activated and persisted');
      },
    );
  }

  Future<void> logout() async {
    final logoutResult = await _localLogoutUseCase(const NoParams());
    logoutResult.fold(
      (failure) {
        _logger.error('Failed to logout: ${failure.message}');
        state = state.copyWith(
          errorMessage: 'Failed to logout: ${failure.message}',
        );
      },
      (_) {
        _logger.debug('Logout successful');
      },
    );

    // Clear user data on logout
    await ref.read(userProvider.notifier).clearUser();

    state = state.copyWith(
      isLoggedIn: false,
      isLoading: false,
      isGuest: false,
    );

    _logger.info('User logged out, auth and user state cleared');
  }

  /// Completely clear all user data (use for account deletion or privacy reset)
  Future<void> clearAllUserData() async {
    try {
      await ref.read(userProvider.notifier).clearUser();

      // Also clear onboarding preferences for complete reset
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      await onboardingRepo.clearPreferences();

      _logger.info('All user data and onboarding preferences cleared');
    } catch (e) {
      _logger.warning('Failed to clear user data: $e');
    }
  }

  /// Reset onboarding status (for testing or manual reset)
  /// This allows a user to go through onboarding again
  Future<void> resetOnboarding() async {
    try {
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      await onboardingRepo.clearPreferences();
      _logger.info('Onboarding status reset - user will see onboarding on next navigation');
    } catch (e) {
      _logger.warning('Failed to reset onboarding: $e');
    }
  }
}
