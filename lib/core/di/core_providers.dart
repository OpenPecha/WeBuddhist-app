import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/cache/cache_service.dart';
import 'package:flutter_pecha/core/config/api_config.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/network/dio_client.dart';
import 'package:flutter_pecha/core/network/interceptors/interceptors.dart';
import 'package:flutter_pecha/core/network/network_info.dart';
import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/secure_storage_impl.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

// ============ Logger ============

/// Provider for AppLogger
final loggerProvider = Provider<AppLogger>((ref) => AppLogger('DI'));

// ============ Storage ============

/// Provider for secure storage (tokens, sensitive data)
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorageImpl();
});

/// Provider for general storage (preferences, settings)
final storageServiceProvider = Provider<StorageService>((ref) {
  return SharedPreferencesService.instance;
});

// ============ Network ============

/// Provider for ApiConfig
final apiConfigProvider = Provider<ApiConfig>((ref) => ApiConfig.current);

/// Provider for ConnectivityService (singleton)
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Provider for NetworkInfo interface
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return ref.watch(connectivityServiceProvider);
});

// ============ Interceptors ============

/// Provider for AuthInterceptor
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(ref.watch(secureStorageProvider));
});

/// Provider for LoggingInterceptor
final loggingInterceptorProvider = Provider<LoggingInterceptor>((ref) {
  return LoggingInterceptor(ref.watch(loggerProvider));
});

/// Provider for ErrorInterceptor
final errorInterceptorProvider = Provider<ErrorInterceptor>((ref) {
  return ErrorInterceptor(ref.watch(loggerProvider));
});

/// Provider for CacheInterceptor
final cacheInterceptorProvider = Provider<CacheInterceptor>((ref) {
  return CacheInterceptor(ref.watch(loggerProvider));
});

/// Provider for RetryInterceptor
final retryInterceptorProvider = Provider<RetryInterceptor>((ref) {
  return RetryInterceptor(
    ref.watch(secureStorageProvider),
    ref.watch(loggerProvider),
  );
});

// ============ Dio Client ============

/// Provider for DioClient
///
/// This is the main HTTP client for the app. It includes all interceptors
/// for auth, logging, error handling, caching, and retry logic.
final dioClientProvider = Provider<DioClient>((ref) {
  final config = ref.watch(apiConfigProvider);

  return DioClient(
    config: config,
    authInterceptor: ref.watch(authInterceptorProvider),
    loggingInterceptor: ref.watch(loggingInterceptorProvider),
    errorInterceptor: ref.watch(errorInterceptorProvider),
    cacheInterceptor: ref.watch(cacheInterceptorProvider),
    retryInterceptor: ref.watch(retryInterceptorProvider),
  );
});

// ============ Cache ============

/// Provider for CacheService (singleton)
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService.instance;
});
