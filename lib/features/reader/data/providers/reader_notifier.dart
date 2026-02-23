import 'dart:async';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_flattener_service.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_merger_service.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_pecha/features/texts/models/text/reader_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parameters for initializing the reader
class ReaderParams {
  final String textId;
  final String? contentId;
  final String? segmentId;
  final NavigationContext? navigationContext;

  const ReaderParams({
    required this.textId,
    this.contentId,
    this.segmentId,
    this.navigationContext,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderParams &&
        other.textId == textId &&
        other.contentId == contentId &&
        other.segmentId == segmentId;
  }

  @override
  int get hashCode => Object.hash(textId, contentId, segmentId);
}

/// Notifier for managing reader state
class ReaderNotifier extends StateNotifier<ReaderState> {
  final Ref _ref;
  final ReaderParams _params;
  final SectionFlattenerService _flattener;
  final SectionMergerService _merger;
  final _logger = AppLogger('ReaderNotifier');

  Timer? _highlightTimer;
  bool _isDisposed = false;

  ReaderNotifier({
    required Ref ref,
    required ReaderParams params,
    SectionFlattenerService? flattener,
    SectionMergerService? merger,
  }) : _ref = ref,
       _params = params,
       _flattener = flattener ?? const SectionFlattenerService(),
       _merger = merger ?? SectionMergerService(),
       super(ReaderState.initial(params.textId)) {
    _initialize();
  }

  /// Initialize the reader with initial content
  Future<void> _initialize() async {
    if (_isDisposed) return;
    _logger.debug('ReaderNotifier initializing with params: $_params');

    state = state.copyWith(
      status: ReaderStatus.loading,
      contentId: _params.contentId,
      navigationContext: _params.navigationContext,
    );

    try {
      _logger.debug('ReaderNotifier fetching content with params: ${_params.segmentId}');
      final response = await _fetchContent(
        segmentId: _params.segmentId,
        direction: 'next',
      );
      _logger.debug('ReaderNotifier initialized with response: $response');

      if (_isDisposed) return;

      // Flatten the content
      final flattenedContent = _flattener.flatten(response.content.sections);

      state = state.copyWith(
        status: ReaderStatus.loaded,
        textDetail: response.textDetail,
        content: flattenedContent,
        currentSegmentPosition: response.currentSegmentPosition,
        totalSegments: response.totalSegments,
        hasNextPage: response.currentSegmentPosition < response.totalSegments,
        hasPreviousPage: response.currentSegmentPosition > 1,
      );

      // Handle highlight if navigating to a specific segment
      if (_params.segmentId != null && _params.navigationContext != null) {
        _triggerHighlight(
          _params.segmentId!,
          _params.navigationContext!.source,
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize reader', e, stackTrace);
      if (_isDisposed) return;
      state = state.copyWith(
        status: ReaderStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Fetch content from the repository
  Future<ReaderResponse> _fetchContent({
    String? segmentId,
    required String direction,
  }) async {
    final params = TextDetailsParams(
      textId: _params.textId,
      contentId: state.contentId ?? _params.contentId,
      segmentId: segmentId,
      direction: direction,
    );

    return await _ref.read(textDetailsFutureProvider(params).future);
  }

  /// Load the next page of content
  Future<void> loadNextPage() async {
    if (_isDisposed || state.isLoadingNext || !state.hasNextPage) return;

    state = state.copyWith(isLoadingNext: true);

    try {
      final lastSegmentId = state.content?.lastSegmentId;
      if (lastSegmentId == null) {
        state = state.copyWith(isLoadingNext: false);
        return;
      }

      final response = await _fetchContent(
        segmentId: lastSegmentId,
        direction: 'next',
      );

      if (_isDisposed) return;

      // Merge new content with existing
      final mergedContent = _merger.merge(
        state.content ?? FlattenedContent.empty(),
        response.content.sections,
        PaginationDirection.next,
      );

      state = state.copyWith(
        content: mergedContent,
        isLoadingNext: false,
        hasNextPage: response.currentSegmentPosition < response.totalSegments,
        totalSegments: response.totalSegments,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to load next page', e, stackTrace);
      if (_isDisposed) return;
      state = state.copyWith(isLoadingNext: false);
    }
  }

  /// Load the previous page of content
  Future<void> loadPreviousPage() async {
    if (_isDisposed || state.isLoadingPrevious || !state.hasPreviousPage) return;

    state = state.copyWith(isLoadingPrevious: true);

    try {
      final firstSegmentId = state.content?.firstSegmentId;
      if (firstSegmentId == null) {
        state = state.copyWith(isLoadingPrevious: false);
        return;
      }

      final response = await _fetchContent(
        segmentId: firstSegmentId,
        direction: 'previous',
      );

      if (_isDisposed) return;

      // Merge new content with existing
      final mergedContent = _merger.merge(
        state.content ?? FlattenedContent.empty(),
        response.content.sections,
        PaginationDirection.previous,
      );

      state = state.copyWith(
        content: mergedContent,
        isLoadingPrevious: false,
        hasPreviousPage: response.currentSegmentPosition > 1,
        currentSegmentPosition: response.currentSegmentPosition,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to load previous page', e, stackTrace);
      if (_isDisposed) return;
      state = state.copyWith(isLoadingPrevious: false);
    }
  }

  /// Select a segment
  void selectSegment(Segment? segment) {
    if (_isDisposed) return;

    if (segment == null) {
      state = state.copyWith(clearSelectedSegment: true);
    } else {
      state = state.copyWith(selectedSegment: segment);
    }
  }

  /// Toggle segment selection
  void toggleSegmentSelection(Segment segment) {
    if (_isDisposed) return;

    if (state.selectedSegment?.segmentId == segment.segmentId) {
      // Deselect if same segment
      state = state.copyWith(
        clearSelectedSegment: true,
        clearCommentarySegmentId: true,
      );
    } else {
      // Select new segment
      state = state.copyWith(selectedSegment: segment);
      
      // Update commentary if it's open
      if (state.isCommentaryOpen) {
        state = state.copyWith(commentarySegmentId: segment.segmentId);
      }
    }
  }

  /// Open commentary panel for a segment
  void openCommentary(String segmentId) {
    if (_isDisposed) return;
    state = state.copyWith(commentarySegmentId: segmentId);
  }

  /// Close commentary panel
  void closeCommentary() {
    if (_isDisposed) return;
    state = state.copyWith(clearCommentarySegmentId: true);
  }

  /// Toggle commentary panel
  void toggleCommentary(String segmentId) {
    if (_isDisposed) return;

    if (state.commentarySegmentId == segmentId) {
      closeCommentary();
    } else {
      openCommentary(segmentId);
    }
  }

  /// Update split ratio for commentary panel
  void updateSplitRatio(double ratio) {
    if (_isDisposed) return;
    final clampedRatio = ratio.clamp(
      ReaderConstants.minSplitRatio,
      ReaderConstants.maxSplitRatio,
    );
    state = state.copyWith(splitRatio: clampedRatio);
  }

  /// Trigger highlight for a segment
  void _triggerHighlight(String segmentId, NavigationSource source) {
    if (_isDisposed) return;

    // Cancel any existing highlight timer
    _highlightTimer?.cancel();

    state = state.copyWith(
      highlightedSegmentId: segmentId,
      highlightSource: source,
    );

    // Get duration based on source
    final duration = switch (source) {
      NavigationSource.plan => ReaderConstants.planHighlightDuration,
      NavigationSource.search => ReaderConstants.searchHighlightDuration,
      NavigationSource.deepLink => ReaderConstants.deepLinkHighlightDuration,
      NavigationSource.normal => Duration.zero,
    };

    if (duration > Duration.zero) {
      _highlightTimer = Timer(duration, () {
        if (!_isDisposed) {
          state = state.copyWith(clearHighlightedSegmentId: true);
        }
      });
    }
  }

  /// Manually highlight a segment (for search navigation within reader)
  void highlightSegment(String segmentId, NavigationSource source) {
    _triggerHighlight(segmentId, source);
  }

  /// Clear highlight
  void clearHighlight() {
    if (_isDisposed) return;
    _highlightTimer?.cancel();
    state = state.copyWith(clearHighlightedSegmentId: true);
  }

  /// Reload content
  Future<void> reload() async {
    if (_isDisposed) return;
    await _initialize();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _highlightTimer?.cancel();
    super.dispose();
  }
}

/// Provider for reader notifier
final readerNotifierProvider =
    StateNotifierProvider.family<ReaderNotifier, ReaderState, ReaderParams>(
  (ref, params) => ReaderNotifier(ref: ref, params: params),
);
