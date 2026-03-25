import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';

/// Interceptor that retries failed requests.
///
/// This interceptor handles:
/// - 401 errors with token refresh (if refresh token is available)
/// - Network errors with exponential backoff
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._secureStorage,
    this._logger,
    this._authService,
  );

  final SecureStorage _secureStorage;
  final AppLogger _logger;
  final AuthService _authService;

  /// Maximum number of retries for network errors
  static const maxRetries = 3;

  /// Base delay for exponential backoff
  static const baseDelay = Duration(milliseconds: 1000);

  /// Currently refreshing token flag
  bool _isRefreshing = false;

  /// Requests waiting for token refresh
  final List<_RetryRequest> _refreshQueue = [];

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 - try to refresh token
    if (err.response?.statusCode == 401) {
      // Check if we have a refresh token
      final refreshToken = await _secureStorage.get(StorageKeys.refreshToken);
      if (refreshToken != null) {
        // If already refreshing, add to queue
        if (_isRefreshing) {
          _logger.debug('Adding request to refresh queue');
          _refreshQueue.add(_RetryRequest(err, handler));
          return;
        }

        // Start token refresh
        _isRefreshing = true;

        try {
          _logger.info('Attempting to refresh token');
          final newIdToken = await _authService.refreshIdToken();

          if (newIdToken != null) {
            // Update secure storage with new token
            await _secureStorage.set(StorageKeys.accessToken, newIdToken);

            _logger.info('Token refreshed successfully, retrying queued requests');

            // Retry all queued requests with new token
            for (final request in _refreshQueue) {
              final opts = request.error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newIdToken';
              try {
                final response = await Dio().fetch(opts);
                request.handler.resolve(response);
              } on DioException catch (e) {
                request.handler.next(e);
              }
            }
            _refreshQueue.clear();

            // Also retry the original request
            final originalOpts = err.requestOptions;
            originalOpts.headers['Authorization'] = 'Bearer $newIdToken';
            try {
              final response = await Dio().fetch(originalOpts);
              handler.resolve(response);
            } on DioException catch (e) {
              handler.next(e);
            }
          } else {
            _logger.warning('Token refresh returned null, clearing tokens');
            await _secureStorage.delete(StorageKeys.accessToken);
            await _secureStorage.delete(StorageKeys.refreshToken);
            _processQueue(error: err);
          }
        } catch (e) {
          _logger.error('Token refresh failed', e);
          await _secureStorage.delete(StorageKeys.accessToken);
          await _secureStorage.delete(StorageKeys.refreshToken);
          _processQueue(error: err);
        } finally {
          _isRefreshing = false;
        }
        return;
      }
    }

    // Retry network errors with exponential backoff
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retry_count'] as int? ?? 0;
      if (retryCount < maxRetries) {
        // Use bitwise left shift for 2^retryCount (^ is XOR in Dart, not power)
        final delay = baseDelay * (1 << retryCount);
        _logger.info(
          'Retrying request (${retryCount + 1}/$maxRetries) '
          'after ${delay.inMilliseconds}ms',
        );

        await Future.delayed(delay);

        // Update retry count
        err.requestOptions.extra['retry_count'] = retryCount + 1;

        try {
          // Clone and retry the request
          final response = await Dio().fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } on DioException catch (e) {
          // If retry also fails, let it continue through error handling
          handler.next(e);
          return;
        }
      }
    }

    handler.next(err);
  }

  /// Check if error should be retried
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  /// Process all queued requests after token refresh
  void _processQueue({required DioException error}) {
    for (final request in _refreshQueue) {
      request.handler.next(error);
    }
    _refreshQueue.clear();
  }
}

class _RetryRequest {
  _RetryRequest(this.error, this.handler);

  final DioException error;
  final ErrorInterceptorHandler handler;
}
