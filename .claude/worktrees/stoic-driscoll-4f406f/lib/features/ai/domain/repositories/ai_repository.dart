import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/ai/domain/entities/chat_message.dart';
import 'package:flutter_pecha/features/ai/domain/entities/chat_thread.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// AI repository interface.
abstract class AIRepository extends Repository {
  /// Get all chat threads for the current user.
  Future<Either<Failure, List<ChatThread>>> getThreads();

  /// Get a specific thread by ID.
  Future<Either<Failure, ChatThread?>> getThread(String threadId);

  /// Create a new chat thread.
  Future<Either<Failure, ChatThread>> createThread(String title);

  /// Delete a chat thread.
  Future<Either<Failure, void>> deleteThread(String threadId);

  /// Send a message and get AI response.
  Future<Either<Failure, ChatMessage>> sendMessage(String threadId, String content);

  /// Search text content using AI.
  Future<Either<Failure, List<SearchResult>>> searchContent(String query);

  /// Get suggestions based on context.
  Future<Either<Failure, List<String>>> getSuggestions(String context, int count);
}

/// Search result from AI content search.
class SearchResult {
  final String contentId;
  final String title;
  final String snippet;
  final double relevance;

  const SearchResult({
    required this.contentId,
    required this.title,
    required this.snippet,
    required this.relevance,
  });
}
