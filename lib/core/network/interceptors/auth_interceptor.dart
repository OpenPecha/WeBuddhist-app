import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/config/protected_routes.dart';
import 'package:flutter_pecha/core/network/token_provider.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

/// Interceptor that adds authentication tokens to requests.
///
/// Uses a [TokenProvider] to retrieve tokens from the appropriate source,
/// eliminating the need for runtime type checks.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._tokenProvider,
    this._logger,
  );

  final TokenProvider _tokenProvider;
  final AppLogger _logger;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add request ID and start time for log correlation
    options.extra['requestId'] = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    options.extra['requestStartTime'] = DateTime.now();

    if (ProtectedRoutes.isProtected(options.path)) {
      final token = await _tokenProvider.getToken();

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        _logger.debug('[AuthInterceptor] Added auth header for ${options.method} ${options.path}');
      } else {
        _logger.warning('[AuthInterceptor] No auth token found for ${options.path}');
      }
    }

    handler.next(options);
  }
}
