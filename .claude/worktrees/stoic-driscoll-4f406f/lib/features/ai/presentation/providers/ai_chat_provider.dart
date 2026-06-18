import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/ai/data/datasource/ai_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/ai/data/datasource/thread_remote_datasource.dart';
import 'package:flutter_pecha/features/ai/data/repositories/ai_chat_repository.dart';
import 'package:flutter_pecha/features/ai/services/rate_limiter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rateLimiterProvider = Provider<RateLimiter>((ref) {
  return RateLimiter(maxRequests: 10, window: const Duration(minutes: 1));
});

/// Provider for AiChatRemoteDatasource
///
/// Uses the dedicated AI Dio client which handles auth via interceptors
final aiChatDatasourceProvider = Provider<AiChatRemoteDatasource>((ref) {
  final aiDio = ref.watch(aiDioProvider);
  return AiChatRemoteDatasource(aiDio);
});

/// Provider for ThreadRemoteDatasource
///
/// Uses the dedicated AI Dio client which handles auth via interceptors
final threadRemoteDatasourceProvider = Provider<ThreadRemoteDatasource>((ref) {
  final aiDio = ref.watch(aiDioProvider);
  return ThreadRemoteDatasource(aiDio);
});

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  final datasource = ref.watch(aiChatDatasourceProvider);
  final threadDatasource = ref.watch(threadRemoteDatasourceProvider);
  return AiChatRepository(datasource, threadDatasource);
});
