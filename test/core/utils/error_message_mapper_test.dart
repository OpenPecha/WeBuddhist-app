import 'dart:async';
import 'dart:io';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/error_message_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMessageMapper', () {
    group('getDisplayMessage', () {
      test('handles null error', () {
        final message = ErrorMessageMapper.getDisplayMessage(null);
        expect(message, 'An unexpected error occurred. Please try again.');
      });

      group('Failure objects', () {
        test('handles NetworkFailure', () {
          const failure = NetworkFailure('Network error');
          final message = ErrorMessageMapper.getDisplayMessage(failure);
          expect(
            message,
            'Unable to connect. Please check your internet connection.',
          );
        });

        test('handles ServerFailure', () {
          const failure = ServerFailure('Server error');
          final message = ErrorMessageMapper.getDisplayMessage(failure);
          expect(
            message,
            'Service temporarily unavailable. Please try again later.',
          );
        });

        test('handles AuthenticationFailure', () {
          const failure = AuthenticationFailure('Auth error');
          final message = ErrorMessageMapper.getDisplayMessage(failure);
          expect(message, 'Session expired. Please sign in again.');
        });

        test('handles AuthorizationFailure', () {
          const failure = AuthorizationFailure('Not authorized');
          final message = ErrorMessageMapper.getDisplayMessage(failure);
          expect(message, 'You don\'t have permission to perform this action.');
        });

        test('handles ValidationFailure with custom message', () {
          const failure = ValidationFailure('Email is required');
          final message = ErrorMessageMapper.getDisplayMessage(failure);
          expect(message, 'Email is required');
        });

        test('handles ValidationFailure with empty message', () {
          const failure = ValidationFailure('');
          final message = ErrorMessageMapper.getDisplayMessage(failure);
          expect(message, 'Invalid input. Please check and try again.');
        });

        test('handles RateLimitFailure with custom message', () {
          const failure = RateLimitFailure('Wait 30 seconds');
          final message = ErrorMessageMapper.getDisplayMessage(failure);
          expect(message, 'Wait 30 seconds');
        });

        test('handles NotFoundFailure', () {
          const failure = NotFoundFailure('Not found');
          final message = ErrorMessageMapper.getDisplayMessage(failure);
          expect(message, 'Content not found. It may have been removed.');
        });

        test('handles CacheFailure', () {
          const failure = CacheFailure('Cache error');
          final message = ErrorMessageMapper.getDisplayMessage(failure);
          expect(message, 'Unable to load saved data. Please try again.');
        });

        test('handles UnknownFailure', () {
          const failure = UnknownFailure('Unknown error');
          final message = ErrorMessageMapper.getDisplayMessage(failure);
          expect(message, 'Something went wrong. Please try again.');
        });
      });

      group('Exception objects', () {
        test('handles TimeoutException with connection message', () {
          final exception = TimeoutException('Connection timeout');
          final message = ErrorMessageMapper.getDisplayMessage(exception);
          expect(
            message,
            'Connection timed out. Please check your internet connection.',
          );
        });

        test('handles TimeoutException with server message', () {
          final exception = TimeoutException('Server response timeout');
          final message = ErrorMessageMapper.getDisplayMessage(exception);
          expect(
            message,
            'Request timed out. The service may be busy. Please try again.',
          );
        });

        test('handles SocketException with failed host lookup', () {
          final exception = SocketException('Failed host lookup');
          final message = ErrorMessageMapper.getDisplayMessage(exception);
          expect(
            message,
            'Unable to reach server. Please check your internet connection.',
          );
        });

        test('handles SocketException with network unreachable', () {
          final exception = SocketException('Network is unreachable');
          final message = ErrorMessageMapper.getDisplayMessage(exception);
          expect(
            message,
            'No internet connection. Please check your network settings.',
          );
        });

        test('handles FormatException', () {
          final exception = FormatException('Invalid format');
          final message = ErrorMessageMapper.getDisplayMessage(exception);
          expect(message, 'Invalid data format. Please try again.');
        });

        test('handles HttpException with status code', () {
          final exception = HttpException('API returned status 500');
          final message = ErrorMessageMapper.getDisplayMessage(exception);
          expect(
            message,
            'Service temporarily unavailable. Please try again later.',
          );
        });
      });

      group('Error strings', () {
        test('handles 400 Bad Request', () {
          final message = ErrorMessageMapper.getDisplayMessage('status 400');
          expect(message, 'Invalid request. Please try again.');
        });

        test('handles 401 Unauthorized', () {
          final message = ErrorMessageMapper.getDisplayMessage('status 401');
          expect(message, 'Session expired. Please sign in again.');
        });

        test('handles 403 Forbidden', () {
          final message = ErrorMessageMapper.getDisplayMessage('status 403');
          expect(
            message,
            'Access denied. You don\'t have permission for this action.',
          );
        });

        test('handles 404 Not Found', () {
          final message = ErrorMessageMapper.getDisplayMessage('status 404');
          expect(message, 'Content not found. It may have been removed.');
        });

        test('handles 429 Too Many Requests', () {
          final message = ErrorMessageMapper.getDisplayMessage('status 429');
          expect(
            message,
            'Too many requests. Please wait a moment and try again.',
          );
        });

        test('handles 500 Internal Server Error', () {
          final message = ErrorMessageMapper.getDisplayMessage('status 500');
          expect(
            message,
            'Service temporarily unavailable. Please try again later.',
          );
        });

        test('handles 502 Bad Gateway', () {
          final message = ErrorMessageMapper.getDisplayMessage('status 502');
          expect(
            message,
            'Service temporarily unavailable. Please try again later.',
          );
        });

        test('handles 503 Service Unavailable', () {
          final message = ErrorMessageMapper.getDisplayMessage('status 503');
          expect(
            message,
            'Service temporarily unavailable. Please try again later.',
          );
        });

        test('handles socket exception string', () {
          final message = ErrorMessageMapper.getDisplayMessage(
            'SocketException: Connection refused',
          );
          expect(
            message,
            'Connection failed. Please check your internet connection.',
          );
        });

        test('handles timeout string', () {
          final message = ErrorMessageMapper.getDisplayMessage(
            'Request timed out',
          );
          expect(message, 'Request timed out. Please try again.');
        });

        test('handles network error string', () {
          final message = ErrorMessageMapper.getDisplayMessage(
            'Network is unreachable',
          );
          expect(
            message,
            'No internet connection. Please check your network settings.',
          );
        });

        test('handles authentication required string', () {
          final message = ErrorMessageMapper.getDisplayMessage(
            'Authentication required',
          );
          expect(message, 'Please sign in to continue.');
        });

        test('handles token expired string', () {
          final message = ErrorMessageMapper.getDisplayMessage('Token expired');
          expect(message, 'Session expired. Please sign in again.');
        });

        test('handles JSON parse error', () {
          final message = ErrorMessageMapper.getDisplayMessage(
            'JSON parse error',
          );
          expect(message, 'Invalid response from server. Please try again.');
        });

        test('handles configuration error', () {
          final message = ErrorMessageMapper.getDisplayMessage(
            'Service not configured',
          );
          expect(
            message,
            'Service configuration error. Please contact support.',
          );
        });

        test('handles generic error', () {
          final message = ErrorMessageMapper.getDisplayMessage(
            'Some random error',
          );
          expect(message, 'Something went wrong. Please try again.');
        });
      });

      group('Context-specific messages', () {
        test('adds chat context', () {
          final message = ErrorMessageMapper.getDisplayMessage(
            SocketException('Connection refused'),
            context: 'chat',
          );
          expect(
            message,
            'Unable to send message. Connection failed. Please check your internet connection.',
          );
        });

        test('adds thread context', () {
          final message = ErrorMessageMapper.getDisplayMessage(
            SocketException('Connection refused'),
            context: 'thread',
          );
          expect(
            message,
            'Unable to load conversation. Connection failed. Please check your internet connection.',
          );
        });

        test('adds delete context', () {
          final message = ErrorMessageMapper.getDisplayMessage(
            SocketException('Connection refused'),
            context: 'delete',
          );
          expect(
            message,
            'Unable to delete. Connection failed. Please check your internet connection.',
          );
        });

        test('adds load context', () {
          final message = ErrorMessageMapper.getDisplayMessage(
            SocketException('Connection refused'),
            context: 'load',
          );
          expect(
            message,
            'Unable to load content. Connection failed. Please check your internet connection.',
          );
        });

        test('adds save context', () {
          final message = ErrorMessageMapper.getDisplayMessage(
            SocketException('Connection refused'),
            context: 'save',
          );
          expect(
            message,
            'Unable to save. Connection failed. Please check your internet connection.',
          );
        });
      });
    });

    group('isNetworkError', () {
      test('returns true for SocketException', () {
        final exception = SocketException('Connection failed');
        expect(ErrorMessageMapper.isNetworkError(exception), isTrue);
      });

      test('returns true for NetworkFailure', () {
        const failure = NetworkFailure('Network error');
        expect(ErrorMessageMapper.isNetworkError(failure), isTrue);
      });

      test('returns true for network-related strings', () {
        expect(ErrorMessageMapper.isNetworkError('socket error'), isTrue);
        expect(ErrorMessageMapper.isNetworkError('network error'), isTrue);
        expect(ErrorMessageMapper.isNetworkError('connection failed'), isTrue);
        expect(ErrorMessageMapper.isNetworkError('unreachable'), isTrue);
        expect(ErrorMessageMapper.isNetworkError('no internet'), isTrue);
      });

      test('returns false for non-network errors', () {
        expect(ErrorMessageMapper.isNetworkError('timeout'), isFalse);
        expect(ErrorMessageMapper.isNetworkError('status 500'), isFalse);
      });
    });

    group('isTimeoutError', () {
      test('returns true for TimeoutException', () {
        final exception = TimeoutException('Timeout');
        expect(ErrorMessageMapper.isTimeoutError(exception), isTrue);
      });

      test('returns true for timeout strings', () {
        expect(ErrorMessageMapper.isTimeoutError('timeout'), isTrue);
        expect(ErrorMessageMapper.isTimeoutError('timed out'), isTrue);
      });

      test('returns false for non-timeout errors', () {
        expect(ErrorMessageMapper.isTimeoutError('network error'), isFalse);
        expect(ErrorMessageMapper.isTimeoutError('status 500'), isFalse);
      });
    });

    group('isAuthError', () {
      test('returns true for AuthenticationFailure', () {
        const failure = AuthenticationFailure('Auth error');
        expect(ErrorMessageMapper.isAuthError(failure), isTrue);
      });

      test('returns true for auth-related strings', () {
        expect(ErrorMessageMapper.isAuthError('status 401'), isTrue);
        expect(ErrorMessageMapper.isAuthError('unauthorized'), isTrue);
        expect(ErrorMessageMapper.isAuthError('authentication failed'), isTrue);
        expect(ErrorMessageMapper.isAuthError('token expired'), isTrue);
        expect(ErrorMessageMapper.isAuthError('session expired'), isTrue);
      });

      test('returns false for non-auth errors', () {
        expect(ErrorMessageMapper.isAuthError('network error'), isFalse);
        expect(ErrorMessageMapper.isAuthError('status 500'), isFalse);
      });
    });

    group('isRetryable', () {
      test('returns true for NetworkFailure', () {
        const failure = NetworkFailure('Network error');
        expect(ErrorMessageMapper.isRetryable(failure), isTrue);
      });

      test('returns true for ServerFailure', () {
        const failure = ServerFailure('Server error');
        expect(ErrorMessageMapper.isRetryable(failure), isTrue);
      });

      test('returns true for TimeoutException', () {
        final exception = TimeoutException('Timeout');
        expect(ErrorMessageMapper.isRetryable(exception), isTrue);
      });

      test('returns true for SocketException', () {
        final exception = SocketException('Connection failed');
        expect(ErrorMessageMapper.isRetryable(exception), isTrue);
      });

      test('returns true for retryable error strings', () {
        expect(ErrorMessageMapper.isRetryable('timeout'), isTrue);
        expect(ErrorMessageMapper.isRetryable('network error'), isTrue);
        expect(ErrorMessageMapper.isRetryable('connection failed'), isTrue);
        expect(ErrorMessageMapper.isRetryable('status 500'), isTrue);
        expect(ErrorMessageMapper.isRetryable('status 502'), isTrue);
        expect(ErrorMessageMapper.isRetryable('status 503'), isTrue);
        expect(ErrorMessageMapper.isRetryable('status 504'), isTrue);
      });

      test('returns false for non-retryable errors', () {
        expect(ErrorMessageMapper.isRetryable('status 400'), isFalse);
        expect(ErrorMessageMapper.isRetryable('status 401'), isFalse);
        expect(ErrorMessageMapper.isRetryable('status 404'), isFalse);
        expect(ErrorMessageMapper.isRetryable('validation error'), isFalse);
      });
    });
  });
}
