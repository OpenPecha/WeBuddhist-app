// Riverpod provider and logic for authentication state.
import 'dart:convert';

import 'package:flutter_pecha/core/storage/special_plan_started_at_store.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/domain/entities/auth_credentials.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/clear_guest_mode_and_onboarding_usecase.dart';
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
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final InitializeAuthUseCase _initializeAuthUseCase;
  final HasValidCredentialsUseCase _hasValidCredentialsUseCase;
  final GetCredentialsUseCase _getCredentialsUseCase;
  final ContinueAsGuestUseCase _continueAsGuestUseCase;
  final IsGuestModeUseCase _isGuestModeUseCase;
  final ClearGuestModeUseCase _clearGuestModeUseCase;
  final LogoutUseCase _localLogoutUseCase;
  final ClearGuestModeAndOnboardingUseCase _clearGuestModeAndOnboardingUseCase;
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
    required ClearGuestModeAndOnboardingUseCase
    clearGuestModeAndOnboardingUseCase,
    required this.ref,
  }) : _loginUseCase = loginUseCase,
       _initializeAuthUseCase = initializeAuthUseCase,
       _hasValidCredentialsUseCase = hasValidCredentialsUseCase,
       _getCredentialsUseCase = getCredentialsUseCase,
       _continueAsGuestUseCase = continueAsGuestUseCase,
       _isGuestModeUseCase = isGuestModeUseCase,
       _clearGuestModeUseCase = clearGuestModeUseCase,
       _localLogoutUseCase = localLogoutUseCase,
       _clearGuestModeAndOnboardingUseCase = clearGuestModeAndOnboardingUseCase,
       super(const AuthState(isLoggedIn: false, isLoading: true)) {
    _restoreLoginState();
  }

  Future<void> _restoreLoginState() async {
    _logger.debug('Restoring login state');

    // Detect fresh install or reinstall.
    // iOS Keychain survives uninstall; SharedPreferences does not.
    // If SP has no install marker, stale keychain tokens may exist from a
    // previous install. Clear them so the user always sees the login screen
    // on a clean install rather than being silently auto-logged in.
    final isKnownInstall = await ref
        .read(localStorageServiceProvider)
        .get<bool>(StorageKeys.firstLaunch);
    if (isKnownInstall == null) {
      await _localLogoutUseCase(const NoParams());
      await ref
          .read(localStorageServiceProvider)
          .set(StorageKeys.firstLaunch, true);
      _logger.info('Fresh install detected — cleared stale keychain tokens');
    }

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
    final credentialsResult = await _hasValidCredentialsUseCase(
      const NoParams(),
    );
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

    // Extract result outside fold so we can await async operations below.
    // fpdart's fold() is synchronous and will not await returned Futures.
    AuthCredentials? credentials;
    credentialsResult.fold((failure) {
      _logger.error('Failed to get credentials: ${failure.message}');
    }, (creds) => credentials = creds);

    if (credentials == null || credentials!.idToken.isEmpty) {
      _logger.debug('Credentials check returned null or invalid credentials');
      _checkGuestMode();
      return;
    }

    // Store currentUserId BEFORE updating auth state so the route guard
    // can check the per-user onboarding key when the router refreshes.
    final userId = _extractUserIdFromToken(credentials!.idToken);
    if (userId != null) {
      await ref
          .read(localStorageServiceProvider)
          .set(StorageKeys.currentUserId, userId);
      _logger.debug('Restored currentUserId for onboarding tracking');
    }

    state = state.copyWith(
      isLoggedIn: true,
      isLoading: false,
      isGuest: false,
      errorMessage: null,
    );
    _logger.info('Login state restored');

    try {
      ref.read(userProvider.notifier).initializeUser();
    } catch (e) {
      _logger.warning('Could not initialize user data', e);
    }
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
    state = state.copyWith(isLoggedIn: false, isLoading: false, isGuest: false);
    _logger.info('No valid credentials or guest mode found, showing login');
  }

  Future<void> _handleAuthFailure() async {
    final logoutResult = await _localLogoutUseCase(const NoParams());
    logoutResult.fold(
      (failure) {
        _logger.warning(
          'Failed to clear credentials during logout: ${failure.message}',
        );
      },
      (_) {
        _logger.debug('Credentials cleared during failure handling');
      },
    );

    state = state.copyWith(isLoggedIn: false, isLoading: false, isGuest: false);
  }

  Future<void> login({String? connection}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final loginResult = await _loginUseCase(
      LoginParams(connection: connection),
    );
    loginResult.fold(
      (failure) {
        _logger.error('Login failed: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed: ${failure.message}',
        );
      },
      (credentials) {
        _handleSuccessfulLogin(credentials);
      },
    );
  }

  Future<void> _handleSuccessfulLogin(AuthCredentials credentials) async {
    // 1. Clear the guest mode flag from storage before the router fires.
    await _clearGuestMode();

    // 2. Persist the user's ID before updating auth state.
    //    The router refreshes the moment auth state changes, so currentUserId
    //    must already be in storage when the route guard checks onboarding.
    final userId = _extractUserIdFromToken(credentials.idToken);
    if (userId != null) {
      await ref
          .read(localStorageServiceProvider)
          .set(StorageKeys.currentUserId, userId);
      _logger.debug('Stored currentUserId for onboarding tracking');
    }

    // 3. Update auth state — triggers the router refresh.
    state = state.copyWith(
      isLoggedIn: true,
      isLoading: false,
      isGuest: false,
      errorMessage: null,
    );
    _logger.info('User authenticated');

    // 4. Fetch full user profile. Non-critical — routing is already correct.
    try {
      await ref.read(userProvider.notifier).initializeUser();
      _logger.info('User data fetched and saved locally');
    } catch (e) {
      _logger.warning('Failed to fetch user data: $e');
    }
  }

  /// Clears the guest mode flag from storage.
  /// Onboarding completion is intentionally NOT touched here — it is tracked
  /// per user ID and must survive login/logout/guest transitions.
  Future<void> _clearGuestMode() async {
    final result = await _clearGuestModeAndOnboardingUseCase(
      const ClearGuestModeAndOnboardingParams(wasGuest: false),
    );
    result.fold(
      (failure) =>
          _logger.warning('Failed to clear guest mode: ${failure.message}'),
      (_) => _logger.debug('Guest mode cleared'),
    );
  }

  /// Extracts the user ID (sub claim) from a JWT ID token without verification.
  /// Used only to identify the user for onboarding tracking — not for auth.
  static String? _extractUserIdFromToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      final claims = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
      return claims['sub'] as String?;
    } catch (_) {
      return null;
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

    // Clear user profile data and the stored user ID.
    // Onboarding completion is NOT cleared — it persists per user ID
    // so the user never sees onboarding again on re-login.
    await ref.read(userProvider.notifier).clearUser();
    await ref
        .read(localStorageServiceProvider)
        .remove(StorageKeys.currentUserId);

    // Reset special-plan day-N cache so a different user signing in does not
    // inherit the prior user's day index or "day 1 already shown" flag.
    await SpecialPlanStartedAtStore.clearAll();

    // Cancel any pending special-plan one-shot notifications so the next user
    // (or the same user after re-login) does not receive notifications keyed
    // off the previous session's startedAt.
    try {
      await RoutineNotificationService().cancelAllSpecialPlanSchedules();
    } catch (e) {
      _logger.warning('Failed to cancel special-plan schedules on logout: $e');
    }

    state = state.copyWith(isLoggedIn: false, isLoading: false, isGuest: false);
    _logger.info('User logged out, auth and user state cleared');
  }

  /// Completely clear all user data (account deletion or privacy reset).
  /// This is the only place where onboarding completion is reset.
  Future<void> clearAllUserData() async {
    try {
      await ref.read(userProvider.notifier).clearUser();

      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      await onboardingRepo.clearPreferences();

      _logger.info('All user data and onboarding preferences cleared');
    } catch (e) {
      _logger.warning('Failed to clear user data: $e');
    }
  }

  /// Reset onboarding status (for testing or manual reset).
  Future<void> resetOnboarding() async {
    try {
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      await onboardingRepo.clearPreferences();
      _logger.info('Onboarding reset — user will see onboarding on next login');
    } catch (e) {
      _logger.warning('Failed to reset onboarding: $e');
    }
  }
}
