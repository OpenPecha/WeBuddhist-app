import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/config/ai_config.dart';

/// Remote data source for AI chat operations.
///
/// This datasource uses the dedicated AI Dio client which:
/// - Uses AI_URL as base URL
/// - Automatically adds auth tokens via interceptors
/// - Has AI-specific timeout configurations
class AiChatRemoteDatasource {
  final Dio _aiDio;
  final _logger = AppLogger('AiChatRemoteDatasource');

  AiChatRemoteDatasource(this._aiDio);

  Stream<Map<String, dynamic>> sendMessage({
    required String message,
    String? threadId,
  }) async* {
    // Build request body with required fields
    final requestBody = <String, dynamic>{
      'query': message,
      'application': 'webuddhist',
      'device_type': 'mobile_app',
    };

    // Only include thread_id if it's provided
    if (threadId != null && threadId.isNotEmpty) {
      requestBody['thread_id'] = threadId;
      _logger.info('Sending message with thread_id: $threadId');
    } else {
      _logger.info('Sending message without thread_id (new conversation)');
    }

    _logger.info('Sending message to AI API: /chats');
    _logger.debug('Request body: $requestBody');

    try {
      final response = await _aiDio.post(
        '/chats',
        data: requestBody,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      _logger.debug('Response status code: ${response.statusCode}');

      if (response.statusCode != 200) {
        _logger.error('API error: ${response.statusCode}');
        _logger.error('Response headers: ${response.headers}');
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else if (response.statusCode != null && response.statusCode! >= 500) {
          throw ServerException('API error: ${response.statusCode}');
        } else {
          throw const NetworkException('Connection failed');
        }
      }

      _logger.info('Receiving stream from API');

      // Buffer for incomplete lines across chunks
      String buffer = '';

      // Get the stream from ResponseBody
      final responseBody = response.data;
      final stream = responseBody.stream;

      // Parse the SSE stream with token timeout
      // Using stream timeout to detect stalled connections
      await for (final chunk in stream.timeout(
        AiConfig.tokenTimeout,
        onTimeout: (sink) {
          _logger.error(
            'Stream timeout - no data received for ${AiConfig.tokenTimeout.inSeconds}s',
          );
          sink.addError(
            TimeoutException(
              'Response timed out. The AI server may be busy.',
              AiConfig.tokenTimeout,
            ),
          );
          sink.close();
        },
      )) {
        // Convert bytes to string
        final chunkString = utf8.decode(chunk);
        buffer += chunkString;

        // Split by lines
        final lines = buffer.split('\n');

        // Keep the last line in buffer (might be incomplete)
        buffer = lines.last;

        // Process all complete lines (all except the last)
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();

          if (line.isEmpty) continue;

          // SSE format: "data: {json}"
          if (line.startsWith('data: ')) {
            final jsonString = line.substring(6); // Remove "data: " prefix

            try {
              final data = jsonDecode(jsonString) as Map<String, dynamic>;
              _logger.debug('Received event type: ${data['type']}');
              yield data;
            } catch (e) {
              _logger.warning('Failed to parse JSON: $jsonString');
              // Continue streaming even if one line fails
            }
          }
        }
      }

      // Process any remaining buffered line after stream ends
      if (buffer.trim().isNotEmpty && buffer.trim().startsWith('data: ')) {
        final jsonString = buffer.trim().substring(6);
        try {
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          _logger.debug('Received final event type: ${data['type']}');
          yield data;
        } catch (e) {
          _logger.warning('Failed to parse final buffered JSON: $jsonString');
        }
      }

      _logger.info('Stream completed');
    } on DioException catch (e) {
      _logger.error('Dio error in sendMessage', e);
      _logger.error('Dio error type: ${e.type}');
      _logger.error('Dio error response: ${e.response}');
      _logger.error('Dio error message: ${e.message}');
      _logger.error('Dio error request options: ${e.requestOptions}');
      if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException('Connection timed out');
      } else if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException('Network error');
      } else if (e.response?.statusCode != null) {
        final statusCode = e.response!.statusCode!;
        if (statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else if (statusCode >= 500) {
          throw ServerException('Server error: $statusCode');
        } else {
          throw NetworkException('Connection failed: $statusCode');
        }
      } else {
        throw const NetworkException('Connection failed');
      }
    } catch (e, stackTrace) {
      _logger.error('Error in sendMessage stream', e, stackTrace);
      if (e is TimeoutException) {
        throw const NetworkException('Request timeout');
      }
      throw ServerException('Failed to send message: $e');
    }
  }
}
