import 'dart:async';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class ApiClient extends http.BaseClient {
  final AuthService _authService;
  final http.Client _inner = http.Client();
  final Logger _logger = Logger('AuthenticatedHttpClient');

  ApiClient(this._authService);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_isProtectedRoute(request.url.path)) {
      final token = await _authService.getValidIdToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        _logger.fine(
          'Added auth token for ${request.method} ${request.url.path}',
        );
      }
    }
    request.headers['Content-Type'] = 'application/json';
    final response = await _inner.send(request);

    // Handle 401 by refreshing token and retrying once
    if (response.statusCode == 401 && _isProtectedRoute(request.url.path)) {
      try {
        _logger.info('Received 401, attempting to refresh token and retry');

        // Clone the original request for retry
        final newRequest = _cloneRequest(request);

        // Force refresh the token
        final newToken = await _authService.getValidIdToken();
        if (newToken != null) {
          // Add the new token to the cloned request
          newRequest.headers['Authorization'] = 'Bearer $newToken';
          _logger.info('Retrying request with refreshed token');
          return await _inner.send(newRequest);
        }
      } catch (e) {
        // Refresh failed, return original response
        _logger.warning('Token refresh failed on 401: $e');
      }
    }

    return response;
  }

  // Helper method to clone a request
  http.BaseRequest _cloneRequest(http.BaseRequest request) {
    http.BaseRequest newRequest;

    if (request is http.Request) {
      newRequest =
          http.Request(request.method, request.url)
            ..encoding = request.encoding
            ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      newRequest =
          http.MultipartRequest(request.method, request.url)
            ..fields.addAll(request.fields)
            ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw Exception('Cannot retry streamed requests');
    } else {
      throw Exception('Unknown request type');
    }

    newRequest.headers.addAll(request.headers);
    return newRequest;
  }

  bool _isProtectedRoute(String path) {
    // Define which endpoints need authentication
    final protectedPaths = ['/api/v1/users/me', '/api/v1/users/me/plans'];

    return protectedPaths.any(
      (protectedPath) => path.startsWith(protectedPath),
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiClient(authService);
});
