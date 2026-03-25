import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/data/models/chat_thread.dart';
import 'package:flutter_pecha/features/ai/services/retry_service.dart';

/// Remote data source for thread operations.
///
/// This datasource uses the dedicated AI Dio client which:
/// - Uses AI_URL as base URL
/// - Automatically adds auth tokens via interceptors
/// - Has AI-specific timeout configurations
class ThreadRemoteDatasource {
  final Dio _aiDio;
  final _logger = AppLogger('ThreadRemoteDatasource');

  ThreadRemoteDatasource(this._aiDio);

  /// Get list of all threads
  Future<ThreadListResponse> getThreads({int skip = 0, int limit = 50}) async {
    _logger.info('Fetching threads');

    try {
      return await RetryService.execute(
        () async {
          final response = await _aiDio.get(
            '/threads',
            queryParameters: {
              'application': 'webuddhist',
              'skip': skip,
              'limit': limit,
            },
          );

          if (response.statusCode == 200) {
            _logger.info('Successfully fetched threads');
            return ThreadListResponse.fromJson(response.data);
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            _logger.error('Authentication error: ${response.statusCode}');
            throw Exception('Authentication required. Please log in.');
          } else {
            _logger.error('Failed to fetch threads: ${response.statusCode}');
            throw Exception(
              'Failed to load chat history: ${response.statusCode}',
            );
          }
        },
        onRetry: (attempt, delay, error) {
          _logger.warning(
            'Retrying getThreads (attempt $attempt) after ${delay.inSeconds}s',
          );
        },
      );
    } catch (e) {
      if (e is Exception) rethrow;
      _logger.error('Network error fetching threads', e);
      throw Exception(
        'Unable to load chat history. Please check your connection.',
      );
    }
  }

  /// Get specific thread by ID with all messages
  Future<ChatThreadDetail> getThreadById(String threadId) async {
    _logger.info('Fetching thread details: $threadId');

    try {
      return await RetryService.execute(
        () async {
          final response = await _aiDio.get('/threads/$threadId');

          if (response.statusCode == 200) {
            _logger.info('Successfully fetched thread: $threadId');
            return ChatThreadDetail.fromJson(response.data);
          } else if (response.statusCode == 404) {
            _logger.error('Thread not found: $threadId');
            throw Exception('Conversation not found');
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            _logger.error('Authentication error: ${response.statusCode}');
            throw Exception('Authentication required. Please log in.');
          } else {
            _logger.error('Failed to fetch thread: ${response.statusCode}');
            throw Exception(
              'Failed to load conversation: ${response.statusCode}',
            );
          }
        },
        onRetry: (attempt, delay, error) {
          _logger.warning(
            'Retrying getThreadById (attempt $attempt) after ${delay.inSeconds}s',
          );
        },
      );
    } catch (e) {
      if (e is Exception) rethrow;
      _logger.error('Network error fetching thread', e);
      throw Exception(
        'Unable to load conversation. Please check your connection.',
      );
    }
  }

  /// Delete a thread by ID
  Future<void> deleteThread(String threadId) async {
    _logger.info('Deleting thread: $threadId');

    try {
      await RetryService.execute(
        () async {
          final response = await _aiDio.delete(
            '/threads/$threadId',
            data: {'thread_id': threadId},
          );

          if (response.statusCode == 200 || response.statusCode == 204) {
            // Parse response body for 200 status code
            if (response.statusCode == 200) {
              try {
                final jsonData = response.data as Map<String, dynamic>;
                final message =
                    jsonData['message'] ?? 'Thread deleted successfully';
                _logger.info(
                  'Delete thread response: $message (thread_id: $threadId)',
                );
              } catch (e) {
                _logger.info('Successfully deleted thread: $threadId');
              }
            } else {
              _logger.info('Successfully deleted thread: $threadId');
            }
            return;
          } else if (response.statusCode == 404) {
            _logger.error('Thread not found: $threadId');
            throw Exception('Conversation not found');
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            _logger.error('Authentication error: ${response.statusCode}');
            throw Exception('Authentication required. Please log in.');
          } else {
            _logger.error('Failed to delete thread: ${response.statusCode}');
            throw Exception(
              'Failed to delete conversation: ${response.statusCode}',
            );
          }
        },
        onRetry: (attempt, delay, error) {
          _logger.warning(
            'Retrying deleteThread (attempt $attempt) after ${delay.inSeconds}s',
          );
        },
      );
    } catch (e) {
      if (e is Exception) rethrow;
      _logger.error('Network error deleting thread', e);
      throw Exception(
        'Unable to delete conversation. Please check your connection.',
      );
    }
  }
}
