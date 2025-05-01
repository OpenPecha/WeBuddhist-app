// Riverpod provider and logic for authentication state.
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_service.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? userId;

  const AuthState({
    required this.isLoggedIn,
    this.userId,
    this.isLoading = false,
  });

  AuthState copyWith({bool? isLoggedIn, String? userId, bool? isLoading}) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        userId: userId ?? this.userId,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoggedIn: false, isLoading: true)) {
    _restoreLoginState();
  }

  Future<void> _restoreLoginState() async {
    final authService = AuthService();
    try {
      final hasValid =
          await authService.auth0.credentialsManager.hasValidCredentials();
      if (hasValid) {
        final credentials =
            await authService.auth0.credentialsManager.credentials();
        state = state.copyWith(
          isLoggedIn: true,
          userId: credentials.user.sub,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoggedIn: false,
          userId: null,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoggedIn: false, userId: null, isLoading: false);
    }
  }

  Future<void> login({String? connection}) async {
    state = state.copyWith(isLoading: true);
    final authService = AuthService();
    Credentials? credentials;
    if (connection == 'google') {
      credentials = await authService.loginWithGoogle();
    } else if (connection == 'facebook') {
      credentials = await authService.loginWithFacebook();
    } else if (connection == 'apple') {
      credentials = await authService.loginWithApple();
    }
    if (credentials != null) {
      state = state.copyWith(
        isLoggedIn: true,
        userId: credentials.user.sub,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  // continue as guest
  Future<void> continueAsGuest() async {
    state = state.copyWith(isLoading: false, isLoggedIn: true, userId: 'guest');
  }

  Future<void> logout() async {
    final authService = AuthService();
    await authService.quickLogout();
    state = state.copyWith(isLoggedIn: false, userId: null, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
