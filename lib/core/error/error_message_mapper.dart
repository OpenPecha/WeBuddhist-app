import 'dart:async';
import 'dart:io';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';

/// Centralized error message mapper.
///
/// Converts domain failures and exceptions into user-friendly messages.
/// This is the single source of truth for error message mapping.
class ErrorMessageMapper {
  ErrorMessageMapper._(); // Private constructor to prevent instantiation

  /// Map a failure to a user-friendly message.
  static String mapFailure(Failure failure) {
    // Since Failure doesn't have a `when` method, use a switch on type
    return switch (failure) {
      NetworkFailure _ => failure.message,
      ServerFailure _ => failure.message,
      CacheFailure _ => failure.message,
      ValidationFailure _ => failure.message,
      AuthenticationFailure _ => failure.message,
      AuthorizationFailure _ => failure.message,
      NotFoundFailure _ => failure.message,
      PairingFailure _ => failure.message,
      RateLimitFailure _ => failure.message,
      UnknownFailure _ => failure.message,
      _ => 'An unexpected error occurred.',
    };
  }

  /// Map an exception to a user-friendly message.
  static String mapException(Exception exception) {
    if (exception is NetworkException) {
      return 'No internet connection. Please check your network settings.';
    }
    if (exception is ServerException) {
      return 'Server error. Please try again later.';
    }
    if (exception is AuthenticationException) {
      return 'Please login to continue.';
    }
    if (exception is AuthorizationException) {
      return 'You do not have permission to perform this action.';
    }
    if (exception is NotFoundException) {
      return 'The requested resource was not found.';
    }
    if (exception is ValidationException) {
      return exception.message;
    }
    if (exception is RateLimitException) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (exception is CacheException) {
      return 'Local data error. Please try again.';
    }
    if (exception is PairingException) {
      return 'Device pairing failed. Please try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Map a dynamic error (could be Failure or Exception) to a message.
  static String map(dynamic error) {
    if (error is Failure) {
      return mapFailure(error);
    }
    if (error is Exception) {
      return mapException(error);
    }
    return 'An unexpected error occurred.';
  }

  /// Converts any error object into a user-friendly display message.
  ///
  /// This is a convenience method that delegates to the appropriate
  /// mapping method based on the error type.
  ///
  /// [error] - The error object to convert
  /// [context] - Optional context for more specific messages (currently unused)
  ///
  /// Returns a user-friendly error message string
  static String getDisplayMessage(dynamic error, {String? context}) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    // Handle Failure objects (from core/error/failures.dart)
    if (error is Failure) {
      return mapFailure(error);
    }

    // Handle common exceptions
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    }

    if (error is FormatException) {
      return 'Invalid data format. Please try again.';
    }

    if (error is HttpException) {
      return 'Service error. Please try again later.';
    }

    // Handle custom exceptions
    if (error is Exception) {
      return mapException(error);
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Checks if an error is retryable (network, timeout, server errors)
  static bool isRetryable(dynamic error) {
    if (error is NetworkFailure ||
        error is ServerFailure ||
        error is TimeoutException ||
        error is SocketException) {
      return true;
    }

    if (error is Exception) {
      final errorString = error.toString().toLowerCase();
      return errorString.contains('timeout') ||
          errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('500') ||
          errorString.contains('502') ||
          errorString.contains('503') ||
          errorString.contains('504');
    }

    return false;
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
}
