import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/cache/cache_service.dart';
import 'package:flutter_pecha/core/config/api_config.dart';
import 'package:flutter_pecha/core/network/ai_dio_client.dart';
import 'package:flutter_pecha/core/network/auth_service_token_provider.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/network/dio_client.dart';
import 'package:flutter_pecha/core/network/interceptors/interceptors.dart';
import 'package:flutter_pecha/core/network/network_info.dart';
import 'package:flutter_pecha/core/network/token_provider.dart';
import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/secure_storage_impl.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/config/ai_config.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';

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

/// Provider for AuthService (singleton)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

// ============ Token Providers ============

/// Provider for AuthService-based TokenProvider (main API and AI API)
final authTokenProvider = Provider<TokenProvider>((ref) {
  return AuthServiceTokenProvider(
    ref.watch(authServiceProvider),
    ref.watch(loggerProvider),
  );
});

// ============ Interceptors ============

/// Provider for AuthInterceptor (uses AuthService-based TokenProvider)
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(
    ref.watch(authTokenProvider),
    ref.watch(loggerProvider),
  );
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
  final logger = ref.watch(loggerProvider);
  final authService = ref.watch(authServiceProvider);

  return RetryInterceptor(
    logger,
    authService,
    // When token refresh fails, clear credentials to trigger re-authentication
    () async {
      try {
        await authService.localLogout();
        logger.info('Logged out due to expired token refresh');
      } catch (e) {
        logger.warning('Failed to logout after token refresh failure', e);
      }
    },
  );
});

// ============ Dio Client ============

/// Provider for main DioClient BaseOptions
final _dioBaseOptionsProvider = Provider<BaseOptions>((ref) {
  final config = ref.watch(apiConfigProvider);
  return BaseOptions(
    baseUrl: config.baseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
    sendTimeout: config.sendTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
});

/// Provider for DioClient
///
/// This is the main HTTP client for the app. It includes all interceptors
/// for auth, logging, error handling, caching, and retry logic.
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    options: ref.watch(_dioBaseOptionsProvider),
    authInterceptor: ref.watch(authInterceptorProvider),
    loggingInterceptor: ref.watch(loggingInterceptorProvider),
    errorInterceptor: ref.watch(errorInterceptorProvider),
    cacheInterceptor: ref.watch(cacheInterceptorProvider),
    retryInterceptor: ref.watch(retryInterceptorProvider),
  );
});

/// Provider for raw Dio instance (for datasources that need it directly)
final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).dio;
});

// ============ AI Dio Client ============

/// Provider for AI DioClient BaseOptions
final _aiDioBaseOptionsProvider = Provider<BaseOptions>((ref) {
  final aiUrl = dotenv.env['AI_URL'];
  if (aiUrl == null || aiUrl.isEmpty) {
    throw Exception('AI_URL not configured');
  }
  return BaseOptions(
    baseUrl: aiUrl,
    connectTimeout: AiConfig.connectionTimeout,
    receiveTimeout: AiConfig.connectionTimeout,
    sendTimeout: AiConfig.connectionTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
});

/// Provider for AiDioClient
///
/// This is a dedicated HTTP client for AI endpoints. It uses the AI_URL
/// base URL and automatically adds auth tokens via AuthService TokenProvider.
final aiDioClientProvider = Provider<AiDioClient>((ref) {
  return AiDioClient(
    options: ref.watch(_aiDioBaseOptionsProvider),
    interceptors: [
      ref.watch(authInterceptorProvider),
      ref.watch(loggingInterceptorProvider),
      ref.watch(errorInterceptorProvider),
    ],
  );
});

/// Provider for raw AI Dio instance (for AI datasources)
final aiDioProvider = Provider<Dio>((ref) {
  return ref.watch(aiDioClientProvider).dio;
});

// ============ Cache ============

/// Provider for CacheService (singleton)
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService.instance;
});
