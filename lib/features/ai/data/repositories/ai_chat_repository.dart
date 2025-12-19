import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/data/datasource/ai_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/ai/models/chat_message.dart';

/// Event types emitted by the chat stream
abstract class ChatStreamEvent {}

class SearchResultsEvent extends ChatStreamEvent {
  final List<SearchResult> results;
  SearchResultsEvent(this.results);
}

class TokenEvent extends ChatStreamEvent {
  final String token;
  TokenEvent(this.token);
}

class DoneEvent extends ChatStreamEvent {}

class ErrorEvent extends ChatStreamEvent {
  final String message;
  ErrorEvent(this.message);
}

class AiChatRepository {
  final AiChatRemoteDatasource _datasource;
  final _logger = AppLogger('AiChatRepository');

  AiChatRepository(this._datasource);

  /// Sends a message and returns a stream of chat events
  Stream<ChatStreamEvent> sendMessage(String message) async* {
    try {
      await for (final data in _datasource.sendMessage(message)) {
        final type = data['type'] as String?;
        
        switch (type) {
          case 'search_results':
            final resultsData = (data['data'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ?? [];
            
            final results = resultsData
                .map((json) => SearchResult.fromJson(json))
                .toList();
            
            _logger.debug('Received ${results.length} search results');
            yield SearchResultsEvent(results);
            break;
            
          case 'token':
            final token = data['data'] as String? ?? '';
            yield TokenEvent(token);
            break;
            
          case 'done':
            _logger.info('Stream completed');
            yield DoneEvent();
            break;
            
          default:
            _logger.warning('Unknown event type: $type');
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Error in chat stream', e, stackTrace);
      yield ErrorEvent(e.toString());
    }
  }
}

