import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/network/interceptors/retry_interceptor.dart';

/// Dio client specifically configured for AI API endpoints.
///
/// This client receives its configuration and interceptors via DI,
/// following the same pattern as [DioClient].
class AiDioClient {
  AiDioClient({
    required BaseOptions options,
    required List<Interceptor> interceptors,
    RetryInterceptor? retryInterceptor,
  }) : _dio = Dio(options) {
    _dio.interceptors.addAll(interceptors);

    // Bind the retry interceptor's internal retry-Dio to this client's
    // BaseOptions so 401 refresh + replay target the AI base URL.
    retryInterceptor?.configure(_dio);
  }

  final Dio _dio;

  /// Get the Dio instance for use in datasources
  Dio get dio => _dio;
}
