import 'dart:async';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/data/models/secondary_reader_state.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier that owns the secondary (companion) version's pages and exposes
/// a segment_number → content lookup map for the interlinear renderer.
///
/// Aligns with the primary by segment_number. Pagination uses the secondary
/// version's own segment_id boundaries so the API returns the correct page.
class SecondaryReaderNotifier extends StateNotifier<SecondaryReaderState> {
  SecondaryReaderNotifier({
    required Ref ref,
    required this.key,
  })  : _ref = ref,
        super(SecondaryReaderState.initial()) {
    _loadInitial();
  }

  final Ref _ref;
  final SecondaryReaderKey key;
  final _logger = AppLogger('SecondaryReader');
  bool _disposed = false;

  Future<void> _loadInitial() async {
    if (_disposed) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _fetch(segmentId: null, direction: 'next');
      if (_disposed) return;

      final segments = _extractSegments(response.content.sections);
      final map = _buildSegmentNumberMap(segments);

      state = state.copyWith(
        contentBySegmentNumber: map,
        loadedSegments: segments,
        totalSegments: response.totalSegments,
        isLoading: false,
        hasNextPage: response.currentSegmentPosition < response.totalSegments,
        hasPreviousPage: response.currentSegmentPosition > 1,
      );
      _logger.debug(
        'Secondary initial load (${key.versionId}): '
        '${segments.length} segments, total=${response.totalSegments}',
      );
    } catch (e, st) {
      _logger.error('Secondary initial load failed for ${key.versionId}', e, st);
      if (_disposed) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Extend the secondary forward by one page.
  Future<void> loadNext() async {
    if (_disposed || state.isLoadingNext || !state.hasNextPage) return;
    final lastId = state.lastLoadedSegmentId;
    if (lastId == null) return;

    state = state.copyWith(isLoadingNext: true);
    try {
      final response = await _fetch(segmentId: lastId, direction: 'next');
      if (_disposed) return;

      final newSegments = _extractSegments(response.content.sections);
      final existingIds =
          state.loadedSegments.map((s) => s.segmentId).toSet();
      final dedupedNew = newSegments
          .where((s) => !existingIds.contains(s.segmentId))
          .toList();

      if (dedupedNew.isEmpty) {
        state = state.copyWith(
          isLoadingNext: false,
          hasNextPage: response.currentSegmentPosition < response.totalSegments,
          totalSegments: response.totalSegments,
        );
        return;
      }

      final mergedSegments = [...state.loadedSegments, ...dedupedNew];
      final mergedMap =
          Map<int, String>.from(state.contentBySegmentNumber);
      for (final seg in dedupedNew) {
        // First try to get content from the translation object (if present)
        if (seg.translation != null && 
            seg.translation!.content.trim().isNotEmpty) {
          mergedMap[seg.segmentNumber] = seg.translation!.content;
        } 
        // Fall back to main content field if no translation
        else if (seg.content != null && seg.content!.isNotEmpty) {
          mergedMap[seg.segmentNumber] = seg.content!;
        }
      }

      state = state.copyWith(
        loadedSegments: mergedSegments,
        contentBySegmentNumber: mergedMap,
        isLoadingNext: false,
        hasNextPage: response.currentSegmentPosition < response.totalSegments,
        totalSegments: response.totalSegments,
      );
    } catch (e, st) {
      _logger.error('Secondary loadNext failed for ${key.versionId}', e, st);
      if (_disposed) return;
      state = state.copyWith(isLoadingNext: false);
    }
  }

  /// Extend the secondary backward by one page.
  Future<void> loadPrevious() async {
    if (_disposed || state.isLoadingPrevious || !state.hasPreviousPage) return;
    final firstId = state.firstLoadedSegmentId;
    if (firstId == null) return;

    state = state.copyWith(isLoadingPrevious: true);
    try {
      final response = await _fetch(segmentId: firstId, direction: 'previous');
      if (_disposed) return;

      final newSegments = _extractSegments(response.content.sections);
      final existingIds =
          state.loadedSegments.map((s) => s.segmentId).toSet();
      final dedupedNew = newSegments
          .where((s) => !existingIds.contains(s.segmentId))
          .toList();

      if (dedupedNew.isEmpty) {
        state = state.copyWith(
          isLoadingPrevious: false,
          hasPreviousPage: response.currentSegmentPosition > 1,
        );
        return;
      }

      final mergedSegments = [...dedupedNew, ...state.loadedSegments];
      final mergedMap =
          Map<int, String>.from(state.contentBySegmentNumber);
      for (final seg in dedupedNew) {
        // First try to get content from the translation object (if present)
        if (seg.translation != null && 
            seg.translation!.content.trim().isNotEmpty) {
          mergedMap[seg.segmentNumber] = seg.translation!.content;
        } 
        // Fall back to main content field if no translation
        else if (seg.content != null && seg.content!.isNotEmpty) {
          mergedMap[seg.segmentNumber] = seg.content!;
        }
      }

      state = state.copyWith(
        loadedSegments: mergedSegments,
        contentBySegmentNumber: mergedMap,
        isLoadingPrevious: false,
        hasPreviousPage: response.currentSegmentPosition > 1,
      );
    } catch (e, st) {
      _logger.error('Secondary loadPrevious failed for ${key.versionId}', e, st);
      if (_disposed) return;
      state = state.copyWith(isLoadingPrevious: false);
    }
  }

  Future<void> reload() async {
    state = SecondaryReaderState.initial();
    await _loadInitial();
  }

  Future<ReaderResponse> _fetch({
    required String? segmentId,
    required String direction,
  }) async {
    final params = TextDetailsParams(
      textId: key.textId,
      versionId: key.versionId,
      segmentId: segmentId,
      direction: direction,
    );
    final result = await _ref.read(textDetailsFutureProvider(params).future);
    return result.fold(
      (failure) => throw Exception(
        'Failed to fetch secondary text: ${failure.message}',
      ),
      (response) => response,
    );
  }

  List<Segment> _extractSegments(List<Section> sections) {
    final result = <Segment>[];
    for (final section in sections) {
      result.addAll(section.segments);
      final nested = section.sections;
      if (nested != null && nested.isNotEmpty) {
        result.addAll(_extractSegments(nested));
      }
    }
    return result;
  }

  Map<int, String> _buildSegmentNumberMap(List<Segment> segments) {
    final map = <int, String>{};
    for (final seg in segments) {
      // First try to get content from the translation object (if present)
      if (seg.translation != null && 
          seg.translation!.content.trim().isNotEmpty) {
        map[seg.segmentNumber] = seg.translation!.content;
      } 
      // Fall back to main content field if no translation
      else if (seg.content != null && seg.content!.isNotEmpty) {
        map[seg.segmentNumber] = seg.content!;
      }
    }
    return map;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// AutoDispose family provider keyed by (textId, versionId). When the user
/// disables the secondary or picks a different version, the old provider is
/// torn down and a fresh one is created on demand.
final secondaryReaderProvider = StateNotifierProvider.autoDispose
    .family<SecondaryReaderNotifier, SecondaryReaderState, SecondaryReaderKey>(
  (ref, key) => SecondaryReaderNotifier(ref: ref, key: key),
);
