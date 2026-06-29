import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';
import 'package:flutter_pecha/features/practice/data/repositories/bookmark_repository.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller for bookmark create/remove (toggle) operations.
///
/// Uses the pre-warmed exists cache for a single API call per tap, with
/// optimistic UI that reverts on failure.
class BookmarkController {
  final _logger = AppLogger('BookmarkController');
  final WidgetRef ref;
  final BuildContext context;

  BookmarkController({required this.ref, required this.context});

  Future<void> toggleText(String textId) =>
      toggle(type: BookmarkType.text, sourceId: textId);

  Future<void> toggleVerse(String segmentId) =>
      toggle(type: BookmarkType.verse, sourceId: segmentId);

  Future<void> toggleTimer(String timerId) =>
      toggle(type: BookmarkType.timer, sourceId: timerId);

  Future<void> toggleMala(String accumulatorId, {String? name}) => toggle(
        type: BookmarkType.accumulator,
        sourceId: accumulatorId,
        name: name,
      );

  Future<void> toggleSeries(String seriesId, {String? name}) => toggle(
        type: BookmarkType.series,
        sourceId: seriesId,
        name: name,
      );

  /// Optimistically toggles bookmark state, then POST or DELETE (one call).
  Future<void> toggle({
    required BookmarkType type,
    required String sourceId,
    String? name,
  }) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }

    final target = BookmarkTarget(type: type, sourceId: sourceId);
    final repository = ref.read(bookmarkRepositoryProvider);
    final cache = ref.read(bookmarkExistsCacheProvider.notifier);
    final previous = readBookmarkStatus(ref, target);
    final wasBookmarked = previous.exists;

    cache.set(
      target,
      BookmarkExistsResult(
        exists: !wasBookmarked,
        id: wasBookmarked ? null : previous.id,
      ),
    );

    try {
      if (wasBookmarked) {
        final bookmarkId = await _resolveBookmarkId(
          repository: repository,
          target: target,
          cachedId: previous.id,
        );
        final deleteResult = await repository.deleteBookmark(bookmarkId);
        deleteResult.fold(
          (failure) => throw Exception(failure.message),
          (_) {},
        );
        cache.set(target, const BookmarkExistsResult(exists: false));
        _showRemovedSnackBar();
      } else {
        final createResult = await repository.createBookmark(
          type: type,
          sourceId: sourceId,
          name: name,
        );
        createResult.fold(
          (failure) => throw Exception(failure.message),
          (_) {},
        );
        cache.set(target, const BookmarkExistsResult(exists: true));
        _showSavedSnackBar();
      }

      ref.invalidate(bookmarksProvider);
    } catch (e, st) {
      _logger.error('Error toggling bookmark', e, st);
      cache.set(target, previous);
      _showErrorSnackBar(wasBookmarked);
    }
  }

  /// Uses cached id when available; falls back to exists check only if needed.
  Future<String> _resolveBookmarkId({
    required BookmarkRepository repository,
    required BookmarkTarget target,
    required String? cachedId,
  }) async {
    if (cachedId != null && cachedId.isNotEmpty) return cachedId;

    final existsResult = await repository.checkBookmarkExists(
      sourceId: target.sourceId,
      type: target.type,
    );
    return existsResult.fold(
      (failure) => throw Exception(failure.message),
      (exists) {
        final id = exists.id;
        if (!exists.exists || id == null || id.isEmpty) {
          throw Exception('Bookmark exists but id is missing');
        }
        return id;
      },
    );
  }

  void _showSavedSnackBar() {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRemovedSnackBar() {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(bool wasBookmarked) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to ${wasBookmarked ? 'remove' : 'save'} bookmark',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
