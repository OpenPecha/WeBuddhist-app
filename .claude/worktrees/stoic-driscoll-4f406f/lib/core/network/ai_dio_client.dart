import 'package:dio/dio.dart';

/// Dio client specifically configured for AI API endpoints.
///
/// This client receives its configuration and interceptors via DI,
/// following the same pattern as [DioClient].
class AiDioClient {
  AiDioClient({
    required BaseOptions options,
    required List<Interceptor> interceptors,
  }) : _dio = Dio(options) {
    _dio.interceptors.addAll(interceptors);
  }

  final Dio _dio;

  /// Get the Dio instance for use in datasources
  Dio get dio => _dio;
}
