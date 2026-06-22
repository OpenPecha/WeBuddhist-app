import 'dart:async';
import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/application/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  late final Auth0 _auth0;
  final _logger = AppLogger('AuthService');

  bool _isInitialized = false;

  /// Minimum lifetime (seconds) a token must have left before we proactively
  /// renew it through the credentials manager. Matches the 2-minute buffer in
  /// [isJwtExpired].
  static const int _kMinTokenTtlSeconds = 120;

  // SharedPreferences key for guest mode
  static const String _guestModeKey = 'is_guest_mode';

  /// Single-flight guard so concurrent proactive/reactive callers share one
  /// in-flight renewal instead of each hitting the credentials manager.
  Future<Credentials>? _inflightCredentials;

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
          .webAuthentication(scheme: ConfigService.instance.auth0Scheme ?? 'org.pecha.app')
          .login(
            useHTTPS: defaultTargetPlatform != TargetPlatform.macOS,
            // Requesting the API audience yields a verifiable JWT access token
            // (instead of an opaque /userinfo token). This access token — not
            // the ID token — is the bearer we send to our backend.
            audience: ConfigService.instance.auth0Audience,
            parameters: parameters,
            scopes: {"openid", "profile", "email", "offline_access"},
          );

      // Store credentials in the credentials manager
      await _auth0.credentialsManager.storeCredentials(credentials);
      _logger.info('Credentials stored successfully');

      // VERIFY STORAGE IMMEDIATELY AFTER STORING
      final verified = await _auth0.credentialsManager.hasValidCredentials();
      _logger.debug('Verification after store: $verified');

      _logger.info('Login successful for connection: $connection');
      return credentials;
    } on WebAuthenticationException catch (e) {
      _logger.warning('WebAuth error for $connection: ${e.message}');
      if (e.code == 'a0.session.user_cancelled') {
        throw AuthException('Login was cancelled by user', code: e.code);
      }
      throw AuthException('Login failed: ${e.message}', code: e.code);
    } catch (e) {
      _logger.error('Unexpected login error for $connection', e);
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
      await clearGuestMode(); // Also clear guest mode on logout
      _logger.info('Local logout successful');
    } catch (e) {
      _logger.error('Logout failed', e);
    }
  }

  // Global logout - clears credentials from device and server
  Future<void> globalLogout() async {
    try {
      await _auth0
          .webAuthentication(scheme: ConfigService.instance.auth0Scheme ?? 'org.pecha.app')
          .logout(useHTTPS: defaultTargetPlatform != TargetPlatform.macOS);
      await _auth0.credentialsManager.clearCredentials();
      _logger.info('Global logout successful');
    } catch (e) {
      _logger.error('Logout failed', e);
    }
  }

  /// Decode a JWT and report whether it is expired (or within [bufferSeconds]
  /// of expiry). Returns true on any parse failure (treat as expired).
  ///
  /// Token-agnostic: works for both access and ID tokens.
  bool isJwtExpired(String jwt, {int bufferSeconds = _kMinTokenTtlSeconds}) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      final exp = (claims['exp'] as num?)?.toInt();
      if (exp == null) return true;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

      return DateTime.now().isAfter(
        expiryDate.subtract(Duration(seconds: bufferSeconds)),
      );
    } catch (e) {
      _logger.warning('Failed to parse jwt exp: $e');
      return true;
    }
  }

  /// Decode and check if an ID token is expired. Retained for ID-token
  /// (identity) call sites; delegates to the token-agnostic [isJwtExpired].
  bool isIdTokenExpired(String idToken) => isJwtExpired(idToken);

  /// Seconds of remaining lifetime for [jwt]; 0 if expired/unparseable.
  int jwtRemainingTtlSeconds(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return 0;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      final exp = (claims['exp'] as num?)?.toInt();
      if (exp == null) return 0;
      final secs = exp - (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      return secs > 0 ? secs : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Returns valid credentials, renewing via the credentials manager when the
  /// access token is within [_kMinTokenTtlSeconds] of expiry. All concurrent
  /// callers (proactive + reactive, across both Dio clients) share one
  /// in-flight renewal.
  ///
  /// The credentials manager is the **single** refresh path: it serializes its
  /// own renewals and stores the rotated refresh token atomically, so a
  /// single-use refresh token can never be consumed by two racing callers.
  /// Do not call `_auth0.api.renewCredentials` directly anywhere.
  Future<Credentials> _validCredentials({bool force = false}) {
    if (_inflightCredentials != null) return _inflightCredentials!;
    final future = _fetchCredentials(force: force)
        .whenComplete(() => _inflightCredentials = null);
    _inflightCredentials = future;
    return future;
  }

  Future<Credentials> _fetchCredentials({required bool force}) async {
    // To FORCE a renewal we ask for more TTL than the current access token can
    // possibly have left, which obliges the manager to renew. This keeps the
    // credentials manager as the single, rotation-safe refresh path (there is
    // no `forceRefresh` flag on `credentials()` in auth0_flutter 1.14.0).
    var minTtl = _kMinTokenTtlSeconds;
    if (force) {
      final current = await _auth0.credentialsManager.credentials();
      final remaining = jwtRemainingTtlSeconds(current.accessToken);
      minTtl = remaining + _kMinTokenTtlSeconds; // > remaining ⇒ forced renew
    }
    return _auth0.credentialsManager.credentials(minTtl: minTtl);
  }

  /// API bearer. Proactive renewal happens inside the credentials manager when
  /// the access token is within [_kMinTokenTtlSeconds] of expiry.
  Future<String?> getValidAccessToken() async {
    final creds = await _validCredentials();
    return creds.accessToken;
  }

  /// Reactive 401 path: force a renewal and return a fresh access token.
  Future<String?> forceRefreshAccessToken() async {
    final creds = await _validCredentials(force: true);
    return creds.accessToken;
  }

  /// Identity only (client-side). Profile claims (email/name/sub) live in the
  /// ID token. Used at login/restore for identity — NEVER as an API bearer.
  Future<String?> getIdTokenForIdentity() async {
    final creds = await _validCredentials();
    return creds.idToken;
  }

  /// Whether [error] from a credentials operation means the session is truly
  /// gone and the user must sign in again — as opposed to a transient/offline
  /// failure we should tolerate (keep the user signed in and renew later).
  ///
  /// Only a missing credential or a missing refresh token is treated as
  /// permanent. `RENEW_FAILED` is treated as transient: at app open it is
  /// almost always a connectivity problem, and wiping a valid session for that
  /// is the bug we are fixing.
  static bool isSessionPermanentlyLost(Object error) {
    return error is CredentialsManagerException &&
        (error.isNoCredentialsFound || error.isNoRefreshTokenFound);
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

  // Guest Mode Persistence Methods

  /// Save guest mode preference to SharedPreferences
  Future<void> saveGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, true);
      _logger.info('Guest mode saved to preferences');
    } catch (e) {
      _logger.warning('Failed to save guest mode: $e');
    }
  }

  /// Check if user previously chose guest mode
  Future<bool> isGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(_guestModeKey) ?? false;
      return isGuest;
    } catch (e) {
      _logger.warning('Failed to check guest mode: $e');
      return false;
    }
  }

  /// Clear guest mode state (called when user logs in or logs out)
  Future<void> clearGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestModeKey);
      _logger.info('Guest mode cleared from preferences');
    } catch (e) {
      _logger.warning('Failed to clear guest mode: $e');
    }
  }

  /// Continue as guest mode
  Future<void> continueAsGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, true);
      _logger.info('Guest mode saved to preferences');
    } catch (e) {
      _logger.warning('Failed to save guest mode: $e');
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
