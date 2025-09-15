// lib/core/network/authenticated_http_client.dart
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:logging/logging.dart';

class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Auth0 auth0;
  final Logger _logger = Logger('AuthenticatedHttpClient');

  String? _cachedToken;
  DateTime? _tokenExpiry;

  AuthenticatedHttpClient._internal(this._inner, this.auth0);

  static AuthenticatedHttpClient? _instance;

  factory AuthenticatedHttpClient(http.Client inner, Auth0 auth0) {
    _instance ??= AuthenticatedHttpClient._internal(inner, auth0);
    return _instance!;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add auth header for protected endpoints
    if (_needsAuthentication(request.url.path)) {
      final token = await _getValidToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await _inner.send(request);

    // Handle 401 Unauthorized - token might be expired
    if (response.statusCode == 401) {
      _logger.warning('401 Unauthorized - clearing cached token');
      _cachedToken = null;
      _tokenExpiry = null;
    }

    return response;
  }

  Future<String?> _getValidToken() async {
    try {
      // Return cached token if still valid
      if (_cachedToken != null &&
          _tokenExpiry != null &&
          DateTime.now().isBefore(
            _tokenExpiry!.subtract(Duration(minutes: 5)),
          )) {
        return _cachedToken;
      }

      // Fetch new token
      final credentials = await auth0.credentialsManager.credentials();
      _cachedToken = credentials.accessToken;

      // Parse JWT to get expiry (simplified - you might want a proper JWT parser)
      _tokenExpiry = DateTime.now().add(Duration(hours: 1)); // Default 1 hour

      return _cachedToken;
    } catch (e) {
      _logger.severe('Failed to get access token: $e');
      return null;
    }
  }

  bool _needsAuthentication(String path) {
    // Define which endpoints need authentication
    final protectedPaths = [
      '/users/me',
      '/users/me/plans',
      // any path that starts with /users/me/plans/
      '/users/me/plans/*',
    ];

    return protectedPaths.any(
      (protectedPath) => path.startsWith(protectedPath),
    );
  }

  void clearToken() {
    _cachedToken = null;
    _tokenExpiry = null;
  }
}
