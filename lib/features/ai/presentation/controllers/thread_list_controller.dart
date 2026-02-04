import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/error_message_mapper.dart';
import 'package:flutter_pecha/features/ai/data/providers/ai_chat_provider.dart';
import 'package:flutter_pecha/features/ai/data/repositories/ai_chat_repository.dart';
import 'package:flutter_pecha/features/ai/models/chat_thread.dart';
import 'package:flutter_pecha/features/auth/application/user_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThreadListState {
  final List<ChatThreadSummary> threads;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int total;
  final DateTime? lastFetchTime;
  final DateTime? lastInteractionTime;

  ThreadListState({
    this.threads = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.total = 0,
    this.lastFetchTime,
    this.lastInteractionTime,
  });

  ThreadListState copyWith({
    List<ChatThreadSummary>? threads,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? total,
    DateTime? lastFetchTime,
    DateTime? lastInteractionTime,
  }) {
    return ThreadListState(
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      total: total ?? this.total,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      lastInteractionTime: lastInteractionTime ?? this.lastInteractionTime,
    );
  }

  bool get hasMore => threads.length < total;

  /// Check if cache is stale using sliding window approach
  /// - Maximum lifetime: 1 hour (even if active)
  /// - Idle timeout: 5 minutes since last interaction
  bool get isStale {
    if (lastFetchTime == null) return true;
    final now = DateTime.now();

    // Maximum lifetime: 1 hour (even if active)
    if (now.difference(lastFetchTime!) > const Duration(hours: 1)) {
      return true;
    }

    // Idle timeout: 5 minutes since last interaction
    if (lastInteractionTime != null) {
      return now.difference(lastInteractionTime!) > const Duration(minutes: 5);
    }

    // Fallback: 5 minutes since fetch
    return now.difference(lastFetchTime!) > const Duration(minutes: 5);
  }
}

class ThreadListController extends StateNotifier<ThreadListState> {
  final AiChatRepository _repository;
  final Ref _ref;
  final _logger = AppLogger('ThreadListController');

  ThreadListController(this._repository, this._ref) : super(ThreadListState());

  /// Get user email for authenticated users
  String? _getUserEmail() {
    final userState = _ref.read(userProvider);

    // Only return email if user is authenticated
    if (userState.isAuthenticated &&
        userState.user?.email != null &&
        userState.user!.email!.isNotEmpty) {
      return userState.user!.email!;
    }

    return null;
  }

  /// Record user interaction to reset idle timer
  /// This implements the sliding window approach used by ChatGPT/Gemini
  void recordInteraction() {
    state = state.copyWith(lastInteractionTime: DateTime.now());
    _logger.debug('User interaction recorded, idle timer reset');
  }

  /// Load threads list with smart caching and optimistic UI
  /// Uses industry-standard sliding window: 5min idle timeout, 1hr max lifetime
  Future<void> loadThreads({bool showCachedFirst = true}) async {
    // Check if user is authenticated
    final email = _getUserEmail();
    if (email == null) {
      _logger.debug('User not authenticated, skipping thread load');
      return;
    }

    // Optimistic UI: Show cached data immediately if available
    if (showCachedFirst && state.threads.isNotEmpty) {
      _logger.debug('Showing cached threads while checking freshness');
      // Cache is already displayed, now check if refresh needed
    }

    // If data is fresh, skip reload
    if (state.threads.isNotEmpty && !state.isStale) {
      _logger.debug(
        'Threads fresh (within 5min idle or 1hr max), skipping reload',
      );
      recordInteraction(); // Reset idle timer
      return;
    }

    // Refresh in background if stale
    _logger.info('Cache stale, refreshing threads');
    await _fetchThreads();
    recordInteraction(); // Record interaction after successful fetch
  }

  /// Force refresh threads list (always reload)
  Future<void> refreshThreads() async {
    _logger.info('Force refreshing threads list');
    await _fetchThreads(forceRefresh: true);
  }

  /// Load more threads (pagination)
  Future<void> loadMoreThreads() async {
    // Don't load if already loading or no more threads
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }

    final email = _getUserEmail();
    if (email == null) {
      _logger.debug('User not authenticated, skipping load more');
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final skip = state.threads.length;
      _logger.info('Loading more threads (skip: $skip)');

      final response = await _repository.getThreads(skip: skip, limit: 50);

      state = state.copyWith(
        threads: [...state.threads, ...response.data],
        total: response.total,
        isLoadingMore: false,
        lastFetchTime: DateTime.now(),
      );

      _logger.info('Loaded ${response.data.length} more threads');
    } catch (e, stackTrace) {
      _logger.error('Error loading more threads', e, stackTrace);
      final friendlyMessage = ErrorMessageMapper.getDisplayMessage(
        e,
        context: 'load',
      );
      state = state.copyWith(isLoadingMore: false, error: friendlyMessage);
    }
  }

  Future<void> _fetchThreads({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getThreads(skip: 0, limit: 50);

      state = state.copyWith(
        threads: response.data,
        total: response.total,
        isLoading: false,
        lastFetchTime: DateTime.now(),
      );

      _logger.info(
        'Loaded ${response.data.length} threads (total: ${response.total})',
      );
    } catch (e, stackTrace) {
      _logger.error('Error loading threads', e, stackTrace);
      final friendlyMessage = ErrorMessageMapper.getDisplayMessage(
        e,
        context: 'load',
      );
      state = state.copyWith(isLoading: false, error: friendlyMessage);
    }
  }

  /// Delete a thread by ID
  Future<void> deleteThread(String threadId) async {
    final email = _getUserEmail();
    if (email == null) {
      _logger.debug('User not authenticated, skipping thread deletion');
      throw Exception('Authentication required');
    }

    try {
      _logger.info('Deleting thread: $threadId');
      await _repository.deleteThread(threadId);

      // Remove the thread from the local list
      final updatedThreads =
          state.threads.where((t) => t.id != threadId).toList();
      state = state.copyWith(threads: updatedThreads, total: state.total - 1);

      _logger.info('Thread deleted successfully: $threadId');
    } catch (e, stackTrace) {
      _logger.error('Error deleting thread', e, stackTrace);
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state (for logout)
  void reset() {
    state = ThreadListState();
  }
}

final threadListControllerProvider =
    StateNotifierProvider<ThreadListController, ThreadListState>((ref) {
      final repository = ref.watch(aiChatRepositoryProvider);
      return ThreadListController(repository, ref);
    });
