import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/config/api_config.dart';
import 'package:flutter_pecha/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/cache_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/error_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/logging_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/retry_interceptor.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

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
    required ApiConfig config,
    required AuthInterceptor authInterceptor,
    required LoggingInterceptor loggingInterceptor,
    required ErrorInterceptor errorInterceptor,
    required CacheInterceptor cacheInterceptor,
    required RetryInterceptor retryInterceptor,
  }) : _dio = Dio(BaseOptions(
    baseUrl: config.baseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
    sendTimeout: config.sendTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  )) {
    // Add interceptors in order
    _dio.interceptors.addAll([
      authInterceptor,      // 1. Add auth headers
      loggingInterceptor,   // 2. Log requests/responses
      cacheInterceptor,     // 3. Check cache for GET
      errorInterceptor,     // 4. Handle errors centrally
      retryInterceptor,     // 5. Retry failed requests
    ]);
  }

  final Dio _dio;

  /// Get the underlying Dio instance
  Dio get dio => _dio;

  /// Close the client and release resources
  void close({bool force = false}) {
    _dio.close(force: force);
  }
}

/// Factory for creating DioClient with all dependencies
class DioClientFactory {
  DioClientFactory({
    required SecureStorage secureStorage,
    required AppLogger logger,
    ApiConfig? config,
  }) : _secureStorage = secureStorage,
       _logger = logger,
       _config = config ?? ApiConfig.current;

  final SecureStorage _secureStorage;
  final AppLogger _logger;
  final ApiConfig _config;

  late final AuthInterceptor _authInterceptor = AuthInterceptor(_secureStorage);
  late final LoggingInterceptor _loggingInterceptor = LoggingInterceptor(_logger);
  late final ErrorInterceptor _errorInterceptor = ErrorInterceptor(_logger);
  late final CacheInterceptor _cacheInterceptor = CacheInterceptor(_logger);
  late final RetryInterceptor _retryInterceptor = RetryInterceptor(_secureStorage, _logger);

  /// Create the DioClient instance
  DioClient create() {
    return DioClient(
      config: _config,
      authInterceptor: _authInterceptor,
      loggingInterceptor: _loggingInterceptor,
      errorInterceptor: _errorInterceptor,
      cacheInterceptor: _cacheInterceptor,
      retryInterceptor: _retryInterceptor,
    );
  }
}
