import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_pecha/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';

/// Auth repository implementation (Data Layer)
///
/// Wraps the working AuthService to provide repository interface.
/// This maintains all existing functionality while providing clean abstraction.
class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({
    required AuthService authService,
    required AuthRemoteDataSource remoteDataSource,
  })  : _authService = authService,
        _remoteDataSource = remoteDataSource;

  // ========== Initialization ==========

  @override
  Future<void> initialize() async {
    await _authService.initialize();
  }

  // ========== Authentication Operations ==========

  @override
  Future<Credentials?> loginWithGoogle() async {
    return await _authService.loginWithGoogle();
  }

  @override
  Future<Credentials?> loginWithApple() async {
    return await _authService.loginWithApple();
  }

  @override
  Future<void> localLogout() async {
    await _authService.localLogout();
  }

  @override
  Future<bool> hasValidCredentials() async {
    return await _authService.hasValidCredentials();
  }

  @override
  Future<Credentials?> getCredentials() async {
    return await _authService.getCredentials();
  }

  @override
  bool isIdTokenExpired(String idToken) {
    return _authService.isIdTokenExpired(idToken);
  }

  @override
  Future<String?> getValidIdToken() async {
    return await _authService.getValidIdToken();
  }

  @override
  Future<String?> refreshIdToken() async {
    return await _authService.refreshIdToken();
  }

  // ========== Guest Mode Operations ==========

  @override
  Future<void> continueAsGuest() async {
    await _authService.continueAsGuest();
  }

  @override
  Future<bool> isGuestMode() async {
    return await _authService.isGuestMode();
  }

  @override
  Future<void> clearGuestMode() async {
    await _authService.clearGuestMode();
  }

  // ========== User Data Operations ==========

  @override
  Future<User?> getCurrentUser() async {
    // Get valid ID token for the API request
    final idToken = await _authService.getValidIdToken();
    if (idToken == null) {
      return null;
    }

    final userModel = await _remoteDataSource.getCurrentUser(idToken);
    return userModel.toEntity();
  }
}
