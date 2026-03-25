import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/error_interceptor.dart';
import 'package:flutter_pecha/core/network/interceptors/logging_interceptor.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/config/ai_config.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';

/// Dio client specifically configured for AI API endpoints.
///
/// This client:
/// - Uses the AI_URL base URL
/// - Automatically adds auth tokens via AuthInterceptor
/// - Has AI-specific timeouts and retry logic
/// - Follows clean architecture (infrastructure layer)
class AiDioClient {
  AiDioClient(this._authService, this._logger) {
    _initDio();
  }

  final AuthService _authService;
  final AppLogger _logger;
  late final Dio _dio;

  /// Get the Dio instance for use in datasources
  Dio get dio => _dio;

  void _initDio() {
    final aiUrl = dotenv.env['AI_URL'];
    if (aiUrl == null || aiUrl.isEmpty) {
      _logger.error('AI_URL not configured in .env');
      throw Exception('AI_URL not configured');
    }

    _dio = Dio(BaseOptions(
      baseUrl: aiUrl,
      connectTimeout: AiConfig.connectionTimeout,
      receiveTimeout: AiConfig.connectionTimeout,
      sendTimeout: AiConfig.connectionTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors in order
    _dio.interceptors.addAll([
      // 1. Logging (for debugging)
      LoggingInterceptor(_logger),
      // 2. Auth (adds Bearer token automatically)
      AuthInterceptor(_authService, _logger),
      // 3. Error handling (converts to domain exceptions)
      ErrorInterceptor(_logger),
    ]);

    _logger.info('AI Dio client initialized with baseUrl: $aiUrl');
  }
}
