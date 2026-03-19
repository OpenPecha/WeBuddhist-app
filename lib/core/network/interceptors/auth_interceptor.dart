import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';

/// Interceptor that adds authentication tokens to requests.
///
/// This interceptor checks if a request path is protected and adds
/// the Authorization header with the access token from secure storage.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._secureStorage);

  final SecureStorage _secureStorage;

  /// Paths that require authentication
  static const List<String> _protectedPaths = [
    // User profile
    '/api/v1/users/info',
    '/api/v1/users/upload',

    // User progress
    '/api/v1/users/me',
    '/api/v1/users/me/plans',
    '/api/v1/users/me/plans/',
    '/api/v1/users/me/tasks',
    '/api/v1/users/me/tasks/',
    '/api/v1/users/me/sub-tasks',
    '/api/v1/users/me/sub-tasks/',
    '/api/v1/users/me/task/',
    '/api/v1/users/me/plan/',

    // Recitations
    '/api/v1/users/me/recitations',

    // AI chat
    '/chats',
    '/threads',
    '/threads/',
  ];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token to protected routes
    if (_isProtectedRoute(options.path)) {
      final token = await _secureStorage.get(StorageKeys.accessToken);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  /// Check if a path is protected (requires authentication)
  bool _isProtectedRoute(String path) {
    return _protectedPaths.any(
      (protectedPath) => path.startsWith(protectedPath),
    );
  }
}
