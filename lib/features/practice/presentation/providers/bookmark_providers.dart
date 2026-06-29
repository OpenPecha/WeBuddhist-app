import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';
import 'package:flutter_pecha/features/practice/data/repositories/bookmark_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(
    remoteDatasource: BookmarkRemoteDatasource(
      dio: ref.watch(dioProvider),
    ),
  );
});

/// Identifies a bookmarkable entity for exists checks and cache invalidation.
@immutable
class BookmarkTarget {
  final BookmarkType type;
  final String sourceId;

  const BookmarkTarget({required this.type, required this.sourceId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkTarget && type == other.type && sourceId == other.sourceId;

  @override
  int get hashCode => Object.hash(type, sourceId);
}

/// Maps list-item types to create/check types. [BookmarkItemType.plan] has no
/// in-app toggle entry point.
BookmarkType? bookmarkTypeFromItem(BookmarkItemType type) => switch (type) {
  BookmarkItemType.text => BookmarkType.text,
  BookmarkItemType.verse => BookmarkType.verse,
  BookmarkItemType.series => BookmarkType.series,
  BookmarkItemType.accumulator => BookmarkType.accumulator,
  BookmarkItemType.timer => BookmarkType.timer,
  BookmarkItemType.plan => null,
};

/// Whether [target] is bookmarked for the signed-in user.
///
/// Guests always resolve to `exists: false` without hitting the network.
final bookmarkExistsProvider = FutureProvider.autoDispose
    .family<BookmarkExistsResult, BookmarkTarget>((ref, target) async {
      final auth = ref.watch(authProvider);
      if (auth.isGuest || !auth.isLoggedIn) {
        return const BookmarkExistsResult(exists: false);
      }

      final result = await ref
          .watch(bookmarkRepositoryProvider)
          .checkBookmarkExists(
            sourceId: target.sourceId,
            type: target.type,
          );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (exists) => exists,
      );
    });

/// Refreshes bookmark list and optional per-item exists state after mutations.
void invalidateBookmarkCaches(WidgetRef ref, {BookmarkTarget? target}) {
  if (target != null) {
    ref.invalidate(bookmarkExistsProvider(target));
  }
  ref.invalidate(bookmarksProvider);
}

/// The tabs shown on the bookmarks screen, in display order.
enum BookmarkTab { all, plans, mala, timers, texts }

extension BookmarkTabFilter on BookmarkTab {
  /// Whether [bookmark] belongs under this tab.
  ///
  /// `plans` merges PLAN + SERIES (in-app both are "series" routine items);
  /// `texts` merges TEXT + VERSE client-side (VERSE isn't a server filter
  /// value); `mala` maps to ACCUMULATOR.
  bool matches(BookmarkDTO bookmark) => switch (this) {
    BookmarkTab.all => true,
    BookmarkTab.plans =>
      bookmark.type == BookmarkItemType.plan ||
          bookmark.type == BookmarkItemType.series,
    BookmarkTab.mala => bookmark.type == BookmarkItemType.accumulator,
    BookmarkTab.timers => bookmark.type == BookmarkItemType.timer,
    BookmarkTab.texts =>
      bookmark.type == BookmarkItemType.text ||
          bookmark.type == BookmarkItemType.verse,
  };
}

/// Immutable view-state for the bookmarks screen. A single fetch backs every
/// tab; [forTab] derives each tab's slice.
class BookmarksState {
  final List<BookmarkDTO> bookmarks;
  final bool isLoading;
  final String? error;

  const BookmarksState({
    this.bookmarks = const [],
    this.isLoading = false,
    this.error,
  });

  BookmarksState copyWith({
    List<BookmarkDTO>? bookmarks,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BookmarksState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  List<BookmarkDTO> forTab(BookmarkTab tab) =>
      bookmarks.where(tab.matches).toList();
}

class BookmarksNotifier extends StateNotifier<BookmarksState> {
  BookmarksNotifier(this._repository, this._language)
    : super(const BookmarksState(isLoading: true)) {
    load();
  }

  final BookmarkRepository _repository;
  final String _language;
  final _logger = AppLogger('BookmarksNotifier');

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.fetchBookmarks(language: _language);
    if (!mounted) return;
    result.fold(
      (failure) {
        _logger.error('Failed to load bookmarks: ${failure.message}');
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (list) {
        final sorted = [...list]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = BookmarksState(bookmarks: sorted, isLoading: false);
      },
    );
  }

  Future<void> refresh() => load();

  /// Optimistically removes [bookmark], restoring it if the API call fails.
  /// Returns `true` on success.
  Future<bool> remove(BookmarkDTO bookmark) async {
    final previous = state.bookmarks;
    state = state.copyWith(
      bookmarks: previous.where((b) => b.id != bookmark.id).toList(),
      clearError: true,
    );

    final result = await _repository.deleteBookmark(bookmark.id);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        _logger.error('Failed to remove bookmark: ${failure.message}');
        state = state.copyWith(bookmarks: previous);
        return false;
      },
      (_) => true,
    );
  }
}

final bookmarksProvider =
    StateNotifierProvider.autoDispose<BookmarksNotifier, BookmarksState>((ref) {
      // Watch the content language so changing locale refetches localized
      // bookmark titles/metadata.
      return BookmarksNotifier(
        ref.watch(bookmarkRepositoryProvider),
        ref.watch(contentLanguageProvider),
      );
    });
