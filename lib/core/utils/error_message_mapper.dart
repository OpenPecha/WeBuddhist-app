import 'dart:async';
import 'dart:io';
import 'package:flutter_pecha/core/error/failures.dart';

/// Maps technical errors and exceptions to user-friendly messages.
///
/// This utility provides a centralized way to convert technical error messages,
/// exceptions, and failures into human-readable text suitable for displaying
/// to end users.
///
/// Usage:
/// ```dart
/// try {
///   await someOperation();
/// } catch (e) {
///   final friendlyMessage = ErrorMessageMapper.getDisplayMessage(e);
///   showSnackBar(friendlyMessage);
/// }
/// ```
class ErrorMessageMapper {
  ErrorMessageMapper._(); // Private constructor to prevent instantiation

  /// Converts any error object into a user-friendly display message.
  ///
  /// Handles:
  /// - [Failure] objects (from core/error/failures.dart)
  /// - Common exceptions (SocketException, TimeoutException, etc.)
  /// - HTTP status codes
  /// - Generic errors
  ///
  /// [error] - The error object to convert
  /// [context] - Optional context for more specific messages (e.g., 'chat', 'thread')
  ///
  /// Returns a user-friendly error message string
  static String getDisplayMessage(dynamic error, {String? context}) {
    // Handle null errors
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    // Handle Failure objects (from core/error/failures.dart)
    if (error is Failure) {
      return _getFailureMessage(error, context: context);
    }

    // Handle common exceptions
    if (error is TimeoutException) {
      return _getTimeoutMessage(error, context: context);
    }

    if (error is SocketException) {
      return _getNetworkMessage(error, context: context);
    }

    if (error is FormatException) {
      return 'Invalid data format. Please try again.';
    }

    if (error is HttpException) {
      return _getHttpMessage(error, context: context);
    }

    // Parse error string for common patterns
    final errorString = error.toString().toLowerCase();
    return _parseErrorString(errorString, context: context);
  }

  /// Gets a user-friendly message for Failure objects
  static String _getFailureMessage(Failure failure, {String? context}) {
    return switch (failure) {
      NetworkFailure() => _getContextualMessage(
        'Unable to connect. Please check your internet connection.',
        context,
      ),
      ServerFailure() => _getContextualMessage(
        'Service temporarily unavailable. Please try again later.',
        context,
      ),
      CacheFailure() => _getContextualMessage(
        'Unable to load saved data. Please try again.',
        context,
      ),
      ValidationFailure() =>
        failure.message.isNotEmpty
            ? failure.message
            : 'Invalid input. Please check and try again.',
      AuthenticationFailure() => 'Session expired. Please sign in again.',
      AuthorizationFailure() =>
        'You don\'t have permission to perform this action.',
      NotFoundFailure() => _getContextualMessage(
        'Content not found. It may have been removed.',
        context,
      ),
      RateLimitFailure() =>
        failure.message.isNotEmpty
            ? failure.message
            : 'Too many requests. Please wait a moment and try again.',
      UnknownFailure() => _getContextualMessage(
        'Something went wrong. Please try again.',
        context,
      ),
      _ => _getContextualMessage(
        'Something went wrong. Please try again.',
        context,
      ),
    };
  }

  /// Gets a user-friendly message for timeout exceptions
  static String _getTimeoutMessage(TimeoutException error, {String? context}) {
    // Check if it's a connection timeout or response timeout
    final message = error.message?.toLowerCase() ?? '';

    if (message.contains('connection')) {
      return _getContextualMessage(
        'Connection timed out. Please check your internet connection.',
        context,
      );
    }

    if (message.contains('response') || message.contains('server')) {
      return _getContextualMessage(
        'Request timed out. The service may be busy. Please try again.',
        context,
      );
    }

    return _getContextualMessage(
      'Request timed out. Please try again.',
      context,
    );
  }

  /// Gets a user-friendly message for network exceptions
  static String _getNetworkMessage(SocketException error, {String? context}) {
    final message = error.message.toLowerCase();

    if (message.contains('failed host lookup')) {
      return 'Unable to reach server. Please check your internet connection.';
    }

    if (message.contains('network is unreachable')) {
      return 'No internet connection. Please check your network settings.';
    }

    return _getContextualMessage(
      'Connection failed. Please check your internet connection.',
      context,
    );
  }

  /// Gets a user-friendly message for HTTP exceptions
  static String _getHttpMessage(HttpException error, {String? context}) {
    final message = error.message.toLowerCase();

    // Try to extract status code
    final statusCodeMatch = RegExp(r'status (\d{3})').firstMatch(message);
    if (statusCodeMatch != null) {
      final statusCode = int.parse(statusCodeMatch.group(1)!);
      return _getHttpStatusMessage(statusCode, context: context);
    }

    return _getContextualMessage(
      'Service error. Please try again later.',
      context,
    );
  }

  /// Parses error string for common patterns
  static String _parseErrorString(String errorString, {String? context}) {
    // HTTP Status codes
    if (errorString.contains('status 400') ||
        errorString.contains('bad request')) {
      return 'Invalid request. Please try again.';
    }

    if (errorString.contains('status 401') ||
        errorString.contains('unauthorized')) {
      return 'Session expired. Please sign in again.';
    }

    if (errorString.contains('status 403') ||
        errorString.contains('forbidden')) {
      return 'Access denied. You don\'t have permission for this action.';
    }

    if (errorString.contains('status 404') ||
        errorString.contains('not found')) {
      return _getContextualMessage(
        'Content not found. It may have been removed.',
        context,
      );
    }

    if (errorString.contains('status 429') ||
        errorString.contains('too many requests')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    if (errorString.contains('status 500') ||
        errorString.contains('status 502') ||
        errorString.contains('status 503') ||
        errorString.contains('internal server error') ||
        errorString.contains('bad gateway') ||
        errorString.contains('service unavailable')) {
      return _getContextualMessage(
        'Service temporarily unavailable. Please try again later.',
        context,
      );
    }

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection reset') ||
        errorString.contains('connection closed')) {
      return _getContextualMessage(
        'Connection failed. Please check your internet connection.',
        context,
      );
    }

    if (errorString.contains('network') ||
        errorString.contains('no internet') ||
        errorString.contains('unreachable')) {
      return 'No internet connection. Please check your network settings.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return _getContextualMessage(
        'Request timed out. Please try again.',
        context,
      );
    }

    // Authentication/Authorization
    if (errorString.contains('authentication required') ||
        errorString.contains('not authenticated')) {
      return 'Please sign in to continue.';
    }

    if (errorString.contains('token expired') ||
        errorString.contains('session expired')) {
      return 'Session expired. Please sign in again.';
    }

    // Parsing/Format errors
    if (errorString.contains('json') ||
        errorString.contains('parse') ||
        errorString.contains('format')) {
      return 'Invalid response from server. Please try again.';
    }

    // Configuration errors (should be rare in production)
    if (errorString.contains('not configured') ||
        errorString.contains('configuration')) {
      return 'Service configuration error. Please contact support.';
    }

    // Generic fallback
    return _getContextualMessage(
      'Something went wrong. Please try again.',
      context,
    );
  }

  /// Gets HTTP status code specific messages
  static String _getHttpStatusMessage(int statusCode, {String? context}) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please try again.';
      case 401:
        return 'Session expired. Please sign in again.';
      case 403:
        return 'Access denied. You don\'t have permission for this action.';
      case 404:
        return _getContextualMessage(
          'Content not found. It may have been removed.',
          context,
        );
      case 408:
        return 'Request timed out. Please try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return _getContextualMessage(
          'Service temporarily unavailable. Please try again later.',
          context,
        );
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return 'Request error. Please try again.';
        } else if (statusCode >= 500) {
          return 'Server error. Please try again later.';
        }
        return _getContextualMessage(
          'Something went wrong. Please try again.',
          context,
        );
    }
  }

  /// Adds context-specific information to error messages
  static String _getContextualMessage(String baseMessage, String? context) {
    if (context == null || context.isEmpty) {
      return baseMessage;
    }

    // Add context-specific prefixes for certain operations
    switch (context.toLowerCase()) {
      case 'chat':
      case 'message':
        return 'Unable to send message. $baseMessage';
      case 'thread':
      case 'conversation':
        return 'Unable to load conversation. $baseMessage';
      case 'delete':
        return 'Unable to delete. $baseMessage';
      case 'load':
      case 'fetch':
        return 'Unable to load content. $baseMessage';
      case 'save':
        return 'Unable to save. $baseMessage';
      default:
        return baseMessage;
    }
  }

  /// Checks if an error is likely a network-related issue
  static bool isNetworkError(dynamic error) {
    if (error is SocketException || error is NetworkFailure) {
      return true;
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('unreachable') ||
        errorString.contains('no internet');
  }

  /// Checks if an error is likely a timeout issue
  static bool isTimeoutError(dynamic error) {
    if (error is TimeoutException) {
      return true;
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') || errorString.contains('timed out');
  }

  /// Checks if an error is likely an authentication issue
  static bool isAuthError(dynamic error) {
    if (error is AuthenticationFailure) {
      return true;
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('401') ||
        errorString.contains('unauthorized') ||
        errorString.contains('authentication') ||
        errorString.contains('token expired') ||
        errorString.contains('session expired');
  }

  /// Checks if an error is retryable (network, timeout, server errors)
  static bool isRetryable(dynamic error) {
    if (error is NetworkFailure ||
        error is ServerFailure ||
        error is TimeoutException ||
        error is SocketException) {
      return true;
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504');
  }
}
