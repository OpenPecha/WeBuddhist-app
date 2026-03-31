import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/entities/auth_credentials.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';

/// Auth repository interface (Domain Layer)
///
/// Defines all authentication operations.
/// This abstraction allows easy swapping of auth providers (Auth0, Firebase, etc.)
abstract class AuthRepository {
  // ========== Initialization ==========

  /// Initialize auth (load config, setup provider)
  Future<Either<Failure, void>> initialize();

  // ========== Authentication Operations ==========

  /// Login with Google
  Future<Either<Failure, AuthCredentials>> loginWithGoogle();

  /// Login with Apple
  Future<Either<Failure, AuthCredentials>> loginWithApple();

  /// Logout (local - clears credentials from device)
  Future<Either<Failure, void>> localLogout();

  /// Check if user has valid credentials
  Future<Either<Failure, bool>> hasValidCredentials();

  /// Get current auth credentials
  Future<Either<Failure, AuthCredentials>> getCredentials();

  /// Check if ID token is expired
  bool isIdTokenExpired(String idToken);

  /// Get valid ID token (refreshes if expired)
  Future<Either<Failure, String>> getValidIdToken();

  /// Refresh ID token
  Future<Either<Failure, String>> refreshIdToken();

  // ========== Guest Mode Operations ==========

  /// Continue as guest mode
  Future<Either<Failure, void>> continueAsGuest();

  /// Check if in guest mode
  Future<Either<Failure, bool>> isGuestMode();

  /// Clear guest mode
  Future<Either<Failure, void>> clearGuestMode();

  // ========== User Data Operations ==========

  /// Get current user profile from backend
  Future<Either<Failure, User>> getCurrentUser();
}
