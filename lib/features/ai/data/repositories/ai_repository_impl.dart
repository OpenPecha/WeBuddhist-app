import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/ai/data/datasource/thread_remote_datasource.dart';
import 'package:flutter_pecha/features/ai/data/models/chat_thread.dart' as data_models;
import 'package:flutter_pecha/features/ai/domain/entities/chat_message.dart' as domain;
import 'package:flutter_pecha/features/ai/domain/entities/chat_thread.dart' as domain;
import 'package:flutter_pecha/features/ai/domain/repositories/ai_repository.dart';

/// Implementation of the AI repository domain interface.
///
/// Note: The sendMessage method in the domain interface returns a single ChatMessage,
/// but the actual API uses streaming. For streaming responses, use AiChatRepository directly.
/// This implementation is provided for non-streaming use cases.
class AiRepositoryImpl implements AIRepository {
  final ThreadRemoteDatasource _threadDatasource;

  AiRepositoryImpl(this._threadDatasource);

  @override
  Future<Either<Failure, List<domain.ChatThread>>> getThreads() async {
    try {
      final response = await _threadDatasource.getThreads(skip: 0, limit: 100);
      final threads = response.data.map((model) => _toDomainThread(model)).toList();
      return Right(threads);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'getThreads'));
    }
  }

  @override
  Future<Either<Failure, domain.ChatThread?>> getThread(String threadId) async {
    try {
      if (threadId.isEmpty) {
        return const Left(ValidationFailure('Thread ID cannot be empty'));
      }
      final threadDetail = await _threadDatasource.getThreadById(threadId);
      final thread = _toDomainThreadFromDetail(threadDetail);
      return Right(thread);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'getThread'));
    }
  }

  @override
  Future<Either<Failure, domain.ChatThread>> createThread(String title) async {
    try {
      if (title.trim().isEmpty) {
        return const Left(ValidationFailure('Thread title cannot be empty'));
      }
      // Note: The API may not have a createThread endpoint
      // Threads are typically created implicitly when sending the first message
      // This is a placeholder implementation
      return Left(
        ServerFailure('Create thread not implemented - threads are created implicitly'),
      );
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'createThread'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteThread(String threadId) async {
    try {
      if (threadId.isEmpty) {
        return const Left(ValidationFailure('Thread ID cannot be empty'));
      }
      await _threadDatasource.deleteThread(threadId);
      return const Right(null);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'deleteThread'));
    }
  }

  @override
  Future<Either<Failure, domain.ChatMessage>> sendMessage(
    String threadId,
    String content,
  ) async {
    // Note: The actual sendMessage API returns a stream, not a single message
    // This is a limitation of the current domain interface design
    // For streaming responses, use AiChatRepository.sendMessage() directly
    return Left(
      ServerFailure(
        'Streaming sendMessage not supported through domain interface. '
        'Use AiChatRepository directly for streaming responses.',
      ),
    );
  }

  @override
  Future<Either<Failure, List<SearchResult>>> searchContent(String query) async {
    try {
      if (query.trim().isEmpty) {
        return const Left(ValidationFailure('Search query cannot be empty'));
      }
      // Note: This would need to be implemented in the datasource
      return Left(
        ServerFailure('Search content not implemented in datasource'),
      );
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'searchContent'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSuggestions(
    String context,
    int count,
  ) async {
    try {
      // Note: This would need to be implemented in the datasource
      return Left(
        ServerFailure('Get suggestions not implemented in datasource'),
      );
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'getSuggestions'));
    }
  }

  /// Convert data model to domain entity
  domain.ChatThread _toDomainThread(data_models.ChatThreadSummary model) {
    final now = DateTime.now();
    return domain.ChatThread(
      id: model.id,
      title: model.title,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convert thread detail to domain entity
  domain.ChatThread _toDomainThreadFromDetail(data_models.ChatThreadDetail detail) {
    final now = DateTime.now();
    return domain.ChatThread(
      id: detail.id,
      title: detail.title,
      messages: detail.messages.map((m) => domain.ChatMessage(
        id: m.id,
        content: m.content,
        type: m.role == 'user' ? domain.MessageType.user : domain.MessageType.assistant,
        createdAt: now,
        sources: m.searchResults?.map((r) => r.id).toList(),
      )).toList(),
      createdAt: now,
      updatedAt: now,
    );
  }
}
