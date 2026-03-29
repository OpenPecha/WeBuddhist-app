import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';

/// Centralized handler for DioExceptions.
///
/// Provides a single source of truth for mapping DioExceptions to
/// domain exceptions, eliminating duplicated error mapping across datasources.
class DioErrorHandler {
  DioErrorHandler._();

  /// Handle a [DioException] by mapping it to the appropriate domain exception
  /// and throwing it. This method never returns normally.
  ///
  /// If the DioException already wraps an [AppException] (set by ErrorInterceptor),
  /// that exception is rethrown directly. Otherwise, the error is mapped from scratch.
  static Never handleDioException(DioException e, String context) {
    // If ErrorInterceptor already mapped this, rethrow the domain exception
    if (e.error is AppException) {
      throw e.error as AppException;
    }

    // Map from scratch (for DioClients without ErrorInterceptor)
    throw _mapDioException(e, context);
  }

  /// Check that a response status code indicates success.
  /// Dio only delivers 2xx to onResponse, so this is mainly for edge cases
  /// where raw response handling is needed.
  static void ensureSuccessStatusCode(int? statusCode, String context) {
    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      throw ServerException('$context: unexpected status $statusCode');
    }
  }

  static AppException _mapDioException(DioException e, String context) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Connection timeout');

      case DioExceptionType.connectionError:
        return const NetworkException('No internet connection');

      case DioExceptionType.badResponse:
        return _mapBadResponse(e.response?.statusCode, context);

      case DioExceptionType.cancel:
        return const NetworkException('Request cancelled');

      case DioExceptionType.unknown:
        final message = e.message?.toLowerCase() ?? '';
        if (message.contains('socket') ||
            message.contains('network') ||
            message.contains('connection')) {
          return const NetworkException('Network error');
        }
        return NetworkException('$context: ${e.message}');

      case DioExceptionType.badCertificate:
        return const NetworkException('Invalid SSL certificate');
    }
  }

  static AppException _mapBadResponse(int? statusCode, String context) {
    switch (statusCode) {
      case 400:
        return ValidationException('$context: bad request');
      case 401:
        return const AuthenticationException('Unauthorized');
      case 403:
        return const AuthorizationException('Forbidden');
      case 404:
        return const NotFoundException('Resource not found');
      case 409:
        return ValidationException('$context: conflict');
      case 429:
        return const RateLimitException('Too many requests');
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException('$context: server error ($statusCode)');
      default:
        return ServerException('$context: HTTP $statusCode');
    }
  }
}
