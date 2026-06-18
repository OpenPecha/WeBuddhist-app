import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/ai/data/datasource/thread_remote_datasource.dart';
import 'package:flutter_pecha/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:flutter_pecha/features/ai/domain/repositories/ai_repository.dart';
import 'package:flutter_pecha/features/ai/domain/usecases/ai_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Repository Provider ==========

/// Provider for the AI repository (domain interface).
final aiDomainRepositoryProvider = Provider<AIRepository>((ref) {
  final aiDio = ref.watch(aiDioProvider);
  final threadDatasource = ThreadRemoteDatasource(aiDio);
  return AiRepositoryImpl(threadDatasource);
});

// ========== Use Case Providers ==========

/// Provider for GetChatThreadsUseCase.
final getChatThreadsUseCaseProvider = Provider<GetChatThreadsUseCase>((ref) {
  final repository = ref.watch(aiDomainRepositoryProvider);
  return GetChatThreadsUseCase(repository);
});

/// Provider for SendMessageUseCase.
/// Note: This use case returns a single ChatMessage, not a stream.
/// For streaming responses, use AiChatRepository directly via aiChatRepositoryProvider.
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  final repository = ref.watch(aiDomainRepositoryProvider);
  return SendMessageUseCase(repository);
});

/// Provider for CreateThreadUseCase.
final createThreadUseCaseProvider = Provider<CreateThreadUseCase>((ref) {
  final repository = ref.watch(aiDomainRepositoryProvider);
  return CreateThreadUseCase(repository);
});

/// Provider for SearchContentUseCase.
final searchContentUseCaseProvider = Provider<SearchContentUseCase>((ref) {
  final repository = ref.watch(aiDomainRepositoryProvider);
  return SearchContentUseCase(repository);
});

/// Provider for DeleteThreadUseCase.
final deleteThreadUseCaseProvider = Provider<DeleteThreadUseCase>((ref) {
  final repository = ref.watch(aiDomainRepositoryProvider);
  return DeleteThreadUseCase(repository);
});
