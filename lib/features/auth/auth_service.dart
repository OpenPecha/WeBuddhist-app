import 'dart:async';
import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_pecha/features/auth/application/config_service.dart';
import 'package:logging/logging.dart';

class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  late final Auth0 _auth0;
  final Logger _logger = Logger('AuthService');

  // Serialize concurrent refresh attempts
  Future<String?>? _ongoingIdTokenRefresh;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // load config from config service
    final config = ConfigService.instance;
    await config.loadConfig();

    // Initialize Auth0
    _auth0 = Auth0(config.auth0Domain!, config.auth0ClientId!);

    _isInitialized = true;
  }

  // Common login method
  Future<Credentials?> _loginWithConnection(
    String connection, [
    Map<String, String>? additionalParameters,
  ]) async {
    try {
      final parameters = {"connection": connection};
      if (additionalParameters != null) {
        parameters.addAll(additionalParameters);
      }

      final credentials = await _auth0
          .webAuthentication(scheme: 'org.pecha.app')
          .login(
            useHTTPS: true,
            parameters: parameters,
            scopes: {"openid", "profile", "email", "offline_access"},
          );

      // Store credentials in the credentials manager
      await _auth0.credentialsManager.storeCredentials(credentials);

      _logger.info('Login successful for connection: $connection');
      return credentials;
    } on WebAuthenticationException catch (e) {
      _logger.severe('WebAuth error for $connection: ${e.message}');
      if (e.code == 'a0.session.user_cancelled') {
        throw AuthException('Login was cancelled by user', code: e.code);
      }
      throw AuthException('Login failed: ${e.message}', code: e.code);
    } catch (e) {
      _logger.severe('Unexpected login error for $connection: $e');
      throw AuthException('An unexpected error occurred during login');
    }
  }

  Future<Credentials?> getCredentials() async =>
      await _auth0.credentialsManager.credentials(minTtl: 300);

  // Login with Google
  Future<Credentials?> loginWithGoogle() async {
    return _loginWithConnection('google-oauth2', {'prompt': 'select_account'});
  }

  // Login with Apple
  Future<Credentials?> loginWithApple() async {
    return _loginWithConnection('apple');
  }

  // Local logout - clears credentials from device only
  Future<void> localLogout() async {
    try {
      await _auth0.credentialsManager.clearCredentials();
    } catch (e) {
      _logger.severe('Logout failed: $e');
    }
  }

  // Global logout - clears credentials from device and server
  Future<void> globalLogout() async {
    try {
      await _auth0
          .webAuthentication(scheme: 'org.pecha.app')
          .logout(useHTTPS: true);
      await _auth0.credentialsManager.clearCredentials();
    } catch (e) {
      _logger.severe('Logout failed: $e');
    }
  }

  /// Decode and check if ID token is expired
  bool isIdTokenExpired(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return true;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      final exp = (claims['exp'] as num?)?.toInt();
      if (exp == null) return true;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

      // Consider token expired 2 minutes before actual expiry
      return DateTime.now().isAfter(
        expiryDate.subtract(const Duration(minutes: 2)),
      );
    } catch (e) {
      _logger.warning('Failed to parse idToken exp: $e');
      return true;
    }
  }

  /// Force refresh ID token using refresh token (internal, no concurrency control)
  Future<String?> _refreshIdTokenInternal() async {
    try {
      final storedCreds = await _auth0.credentialsManager.credentials();

      if (storedCreds.refreshToken == null) {
        _logger.severe('No refresh token available');
        throw AuthException("No refresh token available");
      }

      _logger.fine('Refreshing ID token using refresh token');
      final newCreds = await _auth0.api.renewCredentials(
        refreshToken: storedCreds.refreshToken!,
      );

      await _auth0.credentialsManager.storeCredentials(newCreds);
      _logger.info('ID token refreshed successfully');

      return newCreds.idToken;
    } on ApiException catch (e) {
      _logger.severe('Auth0 API error during token refresh: ${e.message}');

      throw AuthException('Token refresh failed: ${e.message}');
    } catch (e) {
      _logger.severe('Unexpected error during token refresh: $e');
      throw AuthException('Token refresh failed: $e');
    }
  }

  /// Public method to force refresh ID token with concurrency control
  Future<String?> refreshIdToken() async {
    // If a refresh is already in progress, wait for it
    if (_ongoingIdTokenRefresh != null) {
      _logger.fine('Waiting for ongoing ID token refresh');
      return await _ongoingIdTokenRefresh!;
    }

    // Start new refresh
    _logger.info('Starting new ID token refresh');
    _ongoingIdTokenRefresh = _refreshIdTokenInternal();

    try {
      final newToken = await _ongoingIdTokenRefresh!;
      return newToken;
    } finally {
      _ongoingIdTokenRefresh = null;
    }
  }

  /// Public method to always return a valid ID token with concurrency control
  Future<String?> getValidIdToken() async {
    // If a refresh is already in progress, wait for it
    final ongoing = _ongoingIdTokenRefresh;
    if (ongoing != null) {
      _logger.fine('Waiting for ongoing ID token refresh');
      await ongoing;
      // After waiting, get fresh credentials and return
      final creds = await _auth0.credentialsManager.credentials();
      return creds.idToken;
    }

    // Get current credentials
    final creds = await _auth0.credentialsManager.credentials();

    // Check if ID token is still valid after waiting
    if (!isIdTokenExpired(creds.idToken)) {
      _logger.fine('ID token is still valid');
      return creds.idToken;
    }

    // Token is expired, need to refresh
    // Double-check if another thread started refresh while we were checking
    if (_ongoingIdTokenRefresh != null) {
      _logger.fine('Another thread started refresh, waiting for completion');
      await _ongoingIdTokenRefresh!;
      final freshCreds = await _auth0.credentialsManager.credentials();
      return freshCreds.idToken;
    }

    // Start the refresh (we're the first thread to need it)
    _logger.info('ID token expired, starting refresh');
    _ongoingIdTokenRefresh = _refreshIdTokenInternal();

    try {
      final newToken = await _ongoingIdTokenRefresh!;
      return newToken;
    } finally {
      _ongoingIdTokenRefresh = null;
    }
  }

  /// Check if credentials exist and are valid
  Future<bool> hasValidCredentials() async {
    try {
      return await _auth0.credentialsManager.hasValidCredentials();
    } catch (e) {
      _logger.warning('Error checking valid credentials: $e');
      return false;
    }
  }
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message';
}
