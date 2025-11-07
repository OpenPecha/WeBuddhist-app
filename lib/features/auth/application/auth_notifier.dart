// Riverpod provider and logic for authentication state.
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/features/onboarding/data/providers/onboarding_datasource_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../auth_service.dart';
import 'package:flutter_pecha/core/services/user/user_service_provider.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final bool isGuest;
  final String? userId;
  final UserProfile? userProfile;
  final String? errorMessage; // Add error state

  const AuthState({
    required this.isLoggedIn,
    this.isGuest = false,
    this.userId,
    this.isLoading = false,
    this.userProfile,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userId,
    bool? isLoading,
    bool? isGuest,
    UserProfile? userProfile,
    String? errorMessage,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    userId: userId ?? this.userId,
    isLoading: isLoading ?? this.isLoading,
    isGuest: isGuest ?? this.isGuest,
    userProfile: userProfile ?? this.userProfile,
    errorMessage: errorMessage,
  );

  AuthState clearError() => copyWith(errorMessage: '');
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;
  final Ref ref;
  final Logger _logger = Logger('AuthNotifier');

  AuthNotifier({required this.authService, required this.ref})
    : super(const AuthState(isLoggedIn: false, isLoading: true)) {
    _restoreLoginState();
  }

  Future<void> _restoreLoginState() async {
    debugPrint('Restoring login state');
    try {
      await authService.initialize(); // Ensure config + Auth0 initialized

      // First check if we have any credentials at all
      final hasCredentials = await authService.hasValidCredentials();
      debugPrint('Checking if credentials are valid: $hasCredentials');

      if (hasCredentials) {
        final credentials =
            await authService.getCredentials(); // 5 minute buffer

        // Validate credentials were actually retrieved
        if (credentials != null && credentials.user.sub.isNotEmpty) {
          state = state.copyWith(
            isLoggedIn: true,
            userId: credentials.user.sub,
            isLoading: false,
            isGuest: false,
            userProfile: credentials.user,
            errorMessage: null,
          );
          debugPrint(
            'Login state restored for user: ${credentials.user.sub} auth isLoggedin ${state.isLoggedIn}',
          );

          // Check user has completed onboarding or not
          // Note: UserService may need initialization, but onboarding check
          // is handled by router redirect logic, so this is just for logging
          try {
            final userService = ref.read(userServiceProvider);
            final isOnboardingCompleted = userService.hasCompletedOnboarding;
            debugPrint('User has completed onboarding: $isOnboardingCompleted');
          } catch (e) {
            debugPrint('Could not check onboarding status: $e');
            // Non-critical, router will handle onboarding redirects
          }

          // Early return after successful credential restoration
          return;
        } else {
          debugPrint('Credentials check returned null or invalid user');
          // Fall through to check guest mode
        }
      }

      debugPrint('No valid credentials found, checking guest mode');

      // No credentials, check if user previously chose guest mode
      final isGuest = await authService.isGuestMode();

      if (isGuest) {
        // Restore guest mode
        state = state.copyWith(
          isLoggedIn: true,
          userId: 'guest',
          isLoading: false,
          isGuest: true,
          userProfile: null,
          errorMessage: null,
        );
        _logger.info('Guest mode restored from preferences');
        return;
      }

      // No credentials and not guest mode, user needs to log in
      state = state.copyWith(
        isLoggedIn: false,
        userId: null,
        isLoading: false,
        isGuest: false,
        userProfile: null,
      );
      _logger.info('No valid credentials or guest mode found, showing login');
    } on CredentialsManagerException catch (e) {
      _logger.severe('Credentials manager error during restore: ${e.message}');

      // Clear any stored credentials and require re-authentication
      await _handleAuthFailure();
    } catch (e) {
      _logger.severe('Failed to restore login state: $e');
      // Clear any stored credentials and require re-authentication
      await _handleAuthFailure();
    }
  }

  Future<void> _handleAuthFailure() async {
    try {
      await authService.localLogout();
    } catch (logoutError) {
      _logger.warning(
        'Failed to clear credentials during logout: $logoutError',
      );
    }

    state = state.copyWith(
      isLoggedIn: false,
      userId: null,
      isLoading: false,
      isGuest: false,
      userProfile: null,
    );
  }

  Future<void> login({String? connection}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      Credentials? credentials;

      switch (connection) {
        case 'google':
          credentials = await authService.loginWithGoogle();
          break;
        case 'apple':
          credentials = await authService.loginWithApple();
          break;
        default:
          throw Exception('Unsupported login method: $connection');
      }

      if (credentials != null) {
        // Clear guest mode when user authenticates
        await authService.clearGuestMode();

        state = state.copyWith(
          isLoggedIn: true,
          userId: credentials.user.sub,
          isLoading: false,
          isGuest: false,
          userProfile: credentials.user,
          errorMessage: null,
        );
        _logger.info('User authenticated, guest mode cleared');

        // Fetch and save user data from backend on first login
        try {
          final userService = ref.read(userServiceProvider);
          await userService.initializeUser();

          _logger.info('User data fetched and saved locally');
        } catch (e) {
          _logger.warning('Failed to fetch user data: $e');
          // Don't fail the login if user data fetch fails
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login was cancelled or failed',
        );
      }
    } catch (e) {
      debugPrint('Login failed: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
    }
  }

  // continue as guest
  Future<void> continueAsGuest() async {
    // Persist guest mode preference
    await authService.saveGuestMode();

    state = state.copyWith(
      isLoading: false,
      isLoggedIn: true,
      userId: 'guest',
      isGuest: true,
      userProfile: null,
    );
    _logger.info('Guest mode activated and persisted');
  }

  Future<void> logout() async {
    await authService.localLogout(); // This also clears guest mode

    // Note: We keep user data cached locally for faster re-login
    // This includes profile info but onboarding status is tracked separately
    // Only clear user data if you need to (e.g., account deletion, privacy reasons)

    state = state.copyWith(
      isLoggedIn: false,
      userId: null,
      isLoading: false,
      isGuest: false,
      userProfile: null,
    );

    // clear onboarding preferences
    final onboardingRepo = ref.read(onboardingRepositoryProvider);
    await onboardingRepo.clearPreferences();
    _logger.info('User logged out, all auth state cleared');
  }

  /// Completely clear all user data (use for account deletion or privacy reset)
  Future<void> clearAllUserData() async {
    try {
      final userService = ref.read(userServiceProvider);
      await userService.clearUser();
      _logger.info('All user data cleared');
    } catch (e) {
      _logger.warning('Failed to clear user data: $e');
    }
  }
}

// Helper classes for loading and error states
// class LoadingAuthNotifier extends AuthNotifier {
//   LoadingAuthNotifier()
//     : super(authService: AuthService(domain: 'temp', clientId: 'temp')) {
//     // Don't call _restoreLoginState() as this is just a temporary loading state
//     // The actual AuthNotifier will handle state restoration when config loads
//     state = const AuthState(isLoggedIn: false, isLoading: true);
//   }
// }

// class ErrorAuthNotifier extends AuthNotifier {
//   ErrorAuthNotifier(String errorMessage)
//     : super(authService: AuthService(domain: 'temp', clientId: 'temp')) {
//     state = AuthState(
//       isLoggedIn: false,
//       isLoading: false,
//       errorMessage: errorMessage,
//     );
//   }
// }

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = AuthService.instance; // Use singleton
  return AuthNotifier(authService: authService, ref: ref);
});
