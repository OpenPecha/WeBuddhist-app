import 'dart:async';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/data/providers/ai_chat_provider.dart';
import 'package:flutter_pecha/features/ai/data/repositories/ai_chat_repository.dart';
import 'package:flutter_pecha/features/ai/models/chat_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isStreaming;
  final String currentStreamingContent;
  final List<SearchResult> currentSearchResults;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.currentStreamingContent = '',
    this.currentSearchResults = const [],
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? currentStreamingContent,
    List<SearchResult>? currentSearchResults,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      currentStreamingContent: currentStreamingContent ?? this.currentStreamingContent,
      currentSearchResults: currentSearchResults ?? this.currentSearchResults,
      error: error,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  final AiChatRepository _repository;
  final _logger = AppLogger('ChatController');
  StreamSubscription? _streamSubscription;

  ChatController(this._repository) : super(ChatState());

  /// Sends a message to the AI and handles the streaming response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Cancel any ongoing stream
    await _streamSubscription?.cancel();

    // Add user message to the list
    final userMessage = ChatMessage(content: content, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      error: null,
    );

    // Start streaming AI response
    state = state.copyWith(
      isStreaming: true,
      currentStreamingContent: '',
      currentSearchResults: [],
    );

    try {
      final stream = _repository.sendMessage(content);
      
      _streamSubscription = stream.listen(
        (event) {
          if (event is SearchResultsEvent) {
            // Store search results for citations
            _logger.debug('Received search results: ${event.results.length} items');
            state = state.copyWith(
              currentSearchResults: event.results,
            );
          } else if (event is TokenEvent) {
            // Append token to the streaming content
            state = state.copyWith(
              currentStreamingContent: state.currentStreamingContent + event.token,
            );
          } else if (event is DoneEvent) {
            // Finalize the AI message with search results
            final aiMessage = ChatMessage(
              content: state.currentStreamingContent,
              isUser: false,
              searchResults: state.currentSearchResults,
            );
            state = state.copyWith(
              messages: [...state.messages, aiMessage],
              isStreaming: false,
              currentStreamingContent: '',
              currentSearchResults: [],
            );
            _logger.info('Message streaming completed');
          } else if (event is ErrorEvent) {
            _logger.error('Stream error: ${event.message}');
            state = state.copyWith(
              isStreaming: false,
              currentStreamingContent: '',
              currentSearchResults: [],
              error: event.message,
            );
          }
        },
        onError: (error, stackTrace) {
          _logger.error('Stream subscription error', error, stackTrace);
          state = state.copyWith(
            isStreaming: false,
            currentStreamingContent: '',
            error: error.toString(),
          );
        },
        onDone: () {
          _logger.info('Stream subscription completed');
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error sending message', e, stackTrace);
      state = state.copyWith(
        isStreaming: false,
        currentStreamingContent: '',
        error: e.toString(),
      );
    }
  }

  /// Clears the error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  final repository = ref.watch(aiChatRepositoryProvider);
  return ChatController(repository);
});

