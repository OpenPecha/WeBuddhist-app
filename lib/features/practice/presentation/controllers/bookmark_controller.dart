import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller for creating bookmarks.
///
/// Mirrors the [RecitationSaveController] pattern:
/// guest → show login drawer, authenticated → POST and show feedback.
class BookmarkController {
  final _logger = AppLogger('BookmarkController');
  final WidgetRef ref;
  final BuildContext context;

  BookmarkController({required this.ref, required this.context});

  /// Create a TEXT bookmark for a full text (used from the reader "more" sheet).
  Future<void> bookmarkText(String textId) =>
      _createBookmark(type: BookmarkType.text, sourceId: textId);

  /// Create a VERSE bookmark for a selected segment.
  Future<void> bookmarkVerse(String segmentId) =>
      _createBookmark(type: BookmarkType.verse, sourceId: segmentId);

  /// Create a TIMER bookmark for a preset timer.
  Future<void> bookmarkTimer(String timerId) =>
      _createBookmark(type: BookmarkType.timer, sourceId: timerId);

  Future<void> _createBookmark({
    required BookmarkType type,
    required String sourceId,
  }) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }

    try {
      final params = CreateBookmarkParams(type: type, sourceId: sourceId);
      final result = await ref.read(createBookmarkProvider(params).future);
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => _showSuccessSnackBar(),
      );
    } catch (e, st) {
      _logger.error('Error creating bookmark', e, st);
      _showErrorSnackBar();
    }
  }

  void _showSuccessSnackBar() {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar() {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to save bookmark'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
