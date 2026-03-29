import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/cache_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/error_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/logging_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/retry_interceptor.dart';

/// Dio HTTP client with interceptors.
///
/// This client wraps Dio with all necessary interceptors for:
/// - Authentication (adding auth tokens)
/// - Logging (request/response logging)
/// - Error handling (centralized error conversion)
/// - Caching (GET request caching)
/// - Retry (automatic retry on failure)
class DioClient {
  DioClient({
    required BaseOptions options,
    required AuthInterceptor authInterceptor,
    required LoggingInterceptor loggingInterceptor,
    required ErrorInterceptor errorInterceptor,
    required CacheInterceptor cacheInterceptor,
    required RetryInterceptor retryInterceptor,
  }) : _dio = Dio(options) {
    // Add interceptors in order
    // IMPORTANT: Order matters! Each interceptor processes the request/response in sequence
    _dio.interceptors.addAll([
      authInterceptor,      // 1. Add auth headers first
      cacheInterceptor,     // 2. Check cache for GET requests
      retryInterceptor,     // 3. Handle 401 token refresh & network retries
      errorInterceptor,     // 4. Convert DioExceptions to typed exceptions
      loggingInterceptor,   // 5. Log the FINAL friendly exception (not raw DioException)
    ]);

    // Configure retry interceptor with parent Dio's options for safe retries
    retryInterceptor.configure(_dio);
  }

  final Dio _dio;

  /// Get the underlying Dio instance
  Dio get dio => _dio;

  /// Send a request and return the response stream for SSE/Server-Sent Events.
  ///
  /// This is used for streaming responses like AI chat.
  /// The response type is set to stream, and the caller can iterate over the data.
  Stream<String> sendStreamedRequest(RequestOptions options) async* {
    options.responseType = ResponseType.stream;
    final response = await _dio.fetch(options);

    await for (final chunk in response.data.stream) {
      yield chunk;
    }
  }

  /// Close the client and release resources
  void close({bool force = false}) {
    _dio.close(force: force);
  }
}
