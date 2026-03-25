import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/config/protected_routes.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';

/// Interceptor that adds authentication tokens to requests.
///
/// This interceptor checks if a request path is protected and adds
/// the Authorization header with the access token from the appropriate source:
/// - For main API endpoints: uses SecureStorage
/// - For AI endpoints: uses AuthService (Auth0 credentials manager)
class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._tokenSource,
    this._logger,
  );

  final dynamic _tokenSource; // Can be SecureStorage or AuthService
  final AppLogger _logger;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token to protected routes
    if (ProtectedRoutes.isProtected(options.path)) {
      String? token;

      // Get token from the appropriate source
      if (_tokenSource is AuthService) {
        // For AI endpoints - use AuthService
        token = await (_tokenSource as AuthService).getValidIdToken();
        if (token != null) {
          _logger.debug('[AuthInterceptor] Added AI auth token for ${options.method} ${options.path}');
        }
      } else if (_tokenSource is SecureStorage) {
        // For main API endpoints - use SecureStorage
        token = await (_tokenSource as SecureStorage).get(StorageKeys.accessToken);
      }

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        _logger.warning('[AuthInterceptor] No auth token found for ${options.path}');
      }
    }

    handler.next(options);
  }
}
