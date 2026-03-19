import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/ai/domain/entities/chat_message.dart';
import 'package:flutter_pecha/features/ai/domain/entities/chat_thread.dart';
import 'package:flutter_pecha/features/ai/domain/repositories/ai_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Get chat threads use case.
class GetChatThreadsUseCase extends UseCase<List<ChatThread>, NoParams> {
  final AIRepository _repository;

  GetChatThreadsUseCase(this._repository);

  @override
  Future<Either<Failure, List<ChatThread>>> call(NoParams params) async {
    return await _repository.getThreads();
  }
}

/// Send message use case.
class SendMessageUseCase extends UseCase<ChatMessage, SendMessageParams> {
  final AIRepository _repository;

  SendMessageUseCase(this._repository);

  @override
  Future<Either<Failure, ChatMessage>> call(SendMessageParams params) async {
    if (params.threadId.isEmpty) {
      return const Left(ValidationFailure('Thread ID cannot be empty'));
    }
    if (params.content.trim().isEmpty) {
      return const Left(ValidationFailure('Message content cannot be empty'));
    }
    return await _repository.sendMessage(params.threadId, params.content);
  }
}

class SendMessageParams {
  final String threadId;
  final String content;

  const SendMessageParams({
    required this.threadId,
    required this.content,
  });
}

/// Create thread use case.
class CreateThreadUseCase extends UseCase<ChatThread, CreateThreadParams> {
  final AIRepository _repository;

  CreateThreadUseCase(this._repository);

  @override
  Future<Either<Failure, ChatThread>> call(CreateThreadParams params) async {
    if (params.title.trim().isEmpty) {
      return const Left(ValidationFailure('Thread title cannot be empty'));
    }
    return await _repository.createThread(params.title);
  }
}

class CreateThreadParams {
  final String title;

  const CreateThreadParams({required this.title});
}

/// Search content use case.
class SearchContentUseCase extends UseCase<List<SearchResult>, SearchContentParams> {
  final AIRepository _repository;

  SearchContentUseCase(this._repository);

  @override
  Future<Either<Failure, List<SearchResult>>> call(SearchContentParams params) async {
    if (params.query.trim().isEmpty) {
      return const Left(ValidationFailure('Search query cannot be empty'));
    }
    return await _repository.searchContent(params.query);
  }
}

class SearchContentParams {
  final String query;

  const SearchContentParams({required this.query});
}

/// Delete thread use case.
class DeleteThreadUseCase extends UseCase<void, DeleteThreadParams> {
  final AIRepository _repository;

  DeleteThreadUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteThreadParams params) async {
    if (params.threadId.isEmpty) {
      return const Left(ValidationFailure('Thread ID cannot be empty'));
    }
    return await _repository.deleteThread(params.threadId);
  }
}

class DeleteThreadParams {
  final String threadId;

  const DeleteThreadParams({required this.threadId});
}
