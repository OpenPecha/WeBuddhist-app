import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller for bookmark create/remove (toggle) operations.
///
/// Mirrors the [RecitationSaveController] pattern:
/// guest → show login drawer, authenticated → check exists → POST or DELETE,
/// then invalidate bookmark caches.
class BookmarkController {
  final _logger = AppLogger('BookmarkController');
  final WidgetRef ref;
  final BuildContext context;

  BookmarkController({required this.ref, required this.context});

  /// Toggle a TEXT bookmark for a full text (reader "more" sheet).
  Future<void> toggleText(String textId) =>
      toggle(type: BookmarkType.text, sourceId: textId);

  /// Toggle a VERSE bookmark for a selected segment.
  Future<void> toggleVerse(String segmentId) =>
      toggle(type: BookmarkType.verse, sourceId: segmentId);

  /// Toggle a TIMER bookmark for a preset timer.
  Future<void> toggleTimer(String timerId) =>
      toggle(type: BookmarkType.timer, sourceId: timerId);

  /// Toggle an ACCUMULATOR bookmark for a preset mala/mantra.
  Future<void> toggleMala(String accumulatorId, {String? name}) => toggle(
        type: BookmarkType.accumulator,
        sourceId: accumulatorId,
        name: name,
      );

  /// Toggle a SERIES bookmark.
  Future<void> toggleSeries(String seriesId, {String? name}) => toggle(
        type: BookmarkType.series,
        sourceId: seriesId,
        name: name,
      );

  /// Creates or removes a bookmark depending on current saved state.
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

    try {
      final existsResult = await repository.checkBookmarkExists(
        sourceId: sourceId,
        type: type,
      );

      await existsResult.fold(
        (failure) => throw Exception(failure.message),
        (exists) async {
          if (exists.exists) {
            final bookmarkId = exists.id;
            if (bookmarkId == null || bookmarkId.isEmpty) {
              throw Exception('Bookmark exists but id is missing');
            }
            final deleteResult = await repository.deleteBookmark(bookmarkId);
            deleteResult.fold(
              (failure) => throw Exception(failure.message),
              (_) => _showRemovedSnackBar(),
            );
          } else {
            final createResult = await repository.createBookmark(
              type: type,
              sourceId: sourceId,
              name: name,
            );
            createResult.fold(
              (failure) => throw Exception(failure.message),
              (_) => _showSavedSnackBar(),
            );
          }
        },
      );

      invalidateBookmarkCaches(ref, target: target);
    } catch (e, st) {
      _logger.error('Error toggling bookmark', e, st);
      _showErrorSnackBar();
    }
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

  void _showErrorSnackBar() {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to update bookmark'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
