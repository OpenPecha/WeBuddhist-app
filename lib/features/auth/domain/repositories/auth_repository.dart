import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';

/// Auth repository interface (Domain Layer)
///
/// Defines all authentication operations.
/// This abstraction allows easy swapping of auth providers (Auth0, Firebase, etc.)
abstract class AuthRepository {
  // ========== Initialization ==========

  /// Initialize auth (load config, setup provider)
  Future<void> initialize();

  // ========== Authentication Operations ==========

  /// Login with Google
  Future<Credentials?> loginWithGoogle();

  /// Login with Apple
  Future<Credentials?> loginWithApple();

  /// Logout (local - clears credentials from device)
  Future<void> localLogout();

  /// Check if user has valid credentials
  Future<bool> hasValidCredentials();

  /// Get current auth credentials
  Future<Credentials?> getCredentials();

  /// Check if ID token is expired
  bool isIdTokenExpired(String idToken);

  /// Get valid ID token (refreshes if expired)
  Future<String?> getValidIdToken();

  /// Refresh ID token
  Future<String?> refreshIdToken();

  // ========== Guest Mode Operations ==========

  /// Continue as guest mode
  Future<void> continueAsGuest();

  /// Check if in guest mode
  Future<bool> isGuestMode();

  /// Clear guest mode
  Future<void> clearGuestMode();

  // ========== User Data Operations ==========

  /// Get current user profile from backend
  Future<User?> getCurrentUser();
}

