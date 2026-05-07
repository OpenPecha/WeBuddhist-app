import 'dart:async';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_flattener_service.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_merger_service.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
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

  /// Tracks the `versionId` used for the current/last fetch so we can decide
  /// when a settings change actually warrants a reload. Starts `null` —
  /// matches "no `version_id` sent" which the API treats as "main text".
  String? _activeVersionId;

  /// True after the first successful initialize completes. Used to gate
  /// the one-time backfill that syncs `readerDualSettingsProvider.primary`
  /// to the language returned by the backend (so the settings sheet shows
  /// the actually-loaded text instead of the stale persisted default).
  bool _hasBackfilledPrimary = false;

  /// True while an `_initialize` call is in flight. Used to suppress the
  /// dual-settings listener during cold-start (when `_load` finishes mid
  /// initialize and the persisted versionId becomes visible) — the in-flight
  /// fetch already reads the latest settings so no extra reload is needed.
  bool _isInitializing = false;

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
    _ref.listen<ReaderDualLayoutSettings>(
      readerDualSettingsProvider,
      _onDualSettingsChanged,
      fireImmediately: false,
    );
    _initialize();
  }

  /// Reload primary content when the user picks a different version of the
  /// main text in Reader Settings. Other primary-slot fields (language,
  /// script, labels) are display-only here — they only translate into a new
  /// API request when paired with a `version_id`.
  void _onDualSettingsChanged(
    ReaderDualLayoutSettings? previous,
    ReaderDualLayoutSettings next,
  ) {
    if (_isDisposed) return;
    final newVersionId = next.primary.versionId;
    if (newVersionId == _activeVersionId) return;
    if (_isInitializing) {
      // Cold-start race: persisted prefs landed while the first fetch is
      // still pending. The pending fetch reads settings just before issuing
      // the request, so it will already see `newVersionId` and pick it up.
      _logger.debug(
        'Primary versionId changed during initialize, skipping listener-driven reload.',
      );
      return;
    }
    _logger.debug(
      'Primary versionId changed: $_activeVersionId -> $newVersionId. '
      'Reloading reader content.',
    );
    _reloadForVersionChange();
  }

  /// Fresh fetch driven by a primary version switch. We drop any
  /// pagination-state contentId/segmentId so the new version starts from
  /// its own first page rather than trying to resolve the previous version's
  /// segment id (which is meaningless against the new version).
  Future<void> _reloadForVersionChange() async {
    if (_isDisposed) return;
    state = ReaderState.initial(_params.textId).copyWith(
      status: ReaderStatus.loading,
      navigationContext: _params.navigationContext,
    );
    await _initialize(useNavParams: false);
  }

  /// Initialize the reader with initial content.
  ///
  /// [useNavParams] is `true` for the very first load — we honour
  /// `_params.contentId` / `_params.segmentId` so deep-links and search jumps
  /// work. After a primary-version change those original navigation params
  /// no longer apply (they belong to the previous version), so we ignore
  /// them and just fetch the new version's first page.
  Future<void> _initialize({bool useNavParams = true}) async {
    if (_isDisposed) return;
    _logger.debug('ReaderNotifier initializing with params: $_params');
    _isInitializing = true;

    // Wait until the persisted dual-slot prefs have been merged into state,
    // otherwise on cold start we'd fire the first fetch with no version_id
    // and then immediately re-fetch when the listener notices the loaded
    // versionId is non-null.
    await _ref.read(readerDualSettingsProvider.notifier).loaded;
    if (_isDisposed) {
      _isInitializing = false;
      return;
    }

    final initialContentId = useNavParams ? _params.contentId : null;
    final initialSegmentId = useNavParams ? _params.segmentId : null;

    state = state.copyWith(
      status: ReaderStatus.loading,
      contentId: initialContentId,
      navigationContext: _params.navigationContext,
    );

    try {
      _logger.debug('ReaderNotifier fetching content with params: $initialSegmentId');
      final response = await _fetchContent(
        segmentId: initialSegmentId,
        direction: 'next',
      );
      _logger.debug('ReaderNotifier initialized with response: $response');

      if (_isDisposed) return;

      // Flatten the content
      var flattenedContent = _flattener.flatten(response.content.sections);
      var hasPreviousPage = response.currentSegmentPosition > 1;

      // Pre-load previous page when target is near the top so the widget
      // receives content with the target already at a stable index.
      if (hasPreviousPage && initialSegmentId != null) {
        final targetIndex = flattenedContent.getSegmentIndex(initialSegmentId);
        if (targetIndex != null &&
            targetIndex <= ReaderConstants.previousLoadThreshold) {
          _logger.debug(
            'Pre-loading previous page during init (target at index $targetIndex)',
          );
          final firstSegmentId = flattenedContent.firstSegmentId;
          if (firstSegmentId != null) {
            try {
              final prevResponse = await _fetchContent(
                segmentId: firstSegmentId,
                direction: 'previous',
              );
              if (!_isDisposed) {
                flattenedContent = _merger.merge(
                  flattenedContent,
                  prevResponse.content.sections,
                  PaginationDirection.previous,
                );
                hasPreviousPage = prevResponse.currentSegmentPosition > 1;
                _logger.debug(
                  'Pre-loaded previous page during init. Total items: ${flattenedContent.itemCount}',
                );
              }
            } catch (e) {
              // Graceful fallback — widget will load via normal pagination
              _logger.debug('Pre-load previous page failed, skipping: $e');
            }
          }
        }
      }

      if (_isDisposed) return;

      state = state.copyWith(
        status: ReaderStatus.loaded,
        textDetail: response.textDetail,
        content: flattenedContent,
        currentSegmentPosition: response.currentSegmentPosition,
        totalSegments: response.totalSegments,
        hasNextPage: response.currentSegmentPosition < response.totalSegments,
        hasPreviousPage: hasPreviousPage,
      );

      _maybeBackfillPrimarySettings(response);

      // Handle highlight if navigating to a specific segment
      if (initialSegmentId != null && _params.navigationContext != null) {
        _triggerHighlight(
          initialSegmentId,
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
    } finally {
      _isInitializing = false;
      // If settings shifted to a different version while the initial fetch
      // was running, schedule a follow-up reload so we end on the active
      // selection instead of a stale snapshot.
      if (!_isDisposed) {
        final settings = _ref.read(readerDualSettingsProvider);
        if (settings.primary.versionId != _activeVersionId) {
          _logger.debug(
            'Settings drifted during initialize. Reloading to versionId=${settings.primary.versionId}',
          );
          unawaited(_reloadForVersionChange());
        }
      }
    }
  }

  /// Fetch content from the repository.
  ///
  /// `version_id` is sourced from `readerDualSettingsProvider.primary` so the
  /// primary stream stays in lockstep with what Reader Settings → Main text
  /// reports. When no version is selected we omit it and the API returns the
  /// default text — same as before this provider learned about settings.
  Future<ReaderResponse> _fetchContent({
    String? segmentId,
    required String direction,
  }) async {
    final dualSettings = _ref.read(readerDualSettingsProvider);
    final primaryVersionId = dualSettings.primary.versionId;
    _activeVersionId = primaryVersionId;

    final params = TextDetailsParams(
      textId: _params.textId,
      contentId: state.contentId ?? _params.contentId,
      versionId: primaryVersionId,
      segmentId: segmentId,
      direction: direction,
    );

    final result = await _ref.read(textDetailsFutureProvider(params).future);
    return result.fold(
      (failure) => throw Exception('Failed to fetch content: ${failure.message}'),
      (response) => response,
    );
  }

  /// One-shot, runs after the very first successful initialize: if the user
  /// has not explicitly chosen a primary version, copy the loaded text's
  /// language into `readerDualSettingsProvider.primary` so the Reader
  /// Settings → Main text card and the metadata subtitle reflect what the
  /// reader actually shows instead of the persisted "English" placeholder.
  ///
  /// We only sync language fields and only when `primary.versionId == null`,
  /// so explicit user picks are never overwritten.
  void _maybeBackfillPrimarySettings(ReaderResponse response) {
    if (_hasBackfilledPrimary) return;
    _hasBackfilledPrimary = true;

    final settingsNotifier = _ref.read(readerDualSettingsProvider.notifier);
    final settings = _ref.read(readerDualSettingsProvider);
    final primary = settings.primary;
    if (primary.versionId != null) {
      // User has an explicit version pick — trust it, don't clobber labels.
      return;
    }

    final loadedLanguage = response.textDetail.language;
    if (loadedLanguage.isEmpty) return;
    if (primary.languageCode.toLowerCase() == loadedLanguage.toLowerCase() &&
        primary.languageLabel.toLowerCase() == loadedLanguage.toLowerCase()) {
      return;
    }

    _logger.debug(
      'Backfilling primary settings from loaded text: '
      '${primary.languageCode} -> $loadedLanguage',
    );
    settingsNotifier.replacePrimary(
      ReaderSlotConfig(
        languageCode: loadedLanguage,
        languageLabel: loadedLanguage,
      ),
    );
  }

  /// Load the next page of content
  Future<void> loadNextPage() async {
    if (_isDisposed || state.isLoadingNext || !state.hasNextPage) return;

    state = state.copyWith(isLoadingNext: true);
    final fetchVersionId = _activeVersionId;

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
      if (_activeVersionId != fetchVersionId) {
        // Primary version changed mid-pagination — discard the stale page.
        _logger.debug('Discarding stale next page from versionId=$fetchVersionId');
        return;
      }

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
    final fetchVersionId = _activeVersionId;

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
      if (_activeVersionId != fetchVersionId) {
        // Primary version changed mid-pagination — discard the stale page.
        _logger.debug(
          'Discarding stale previous page from versionId=$fetchVersionId',
        );
        return;
      }

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
        clearTranslationSegmentId: true,
      );
    } else {
      // Select new segment
      state = state.copyWith(selectedSegment: segment);

      // Update commentary if it's open
      if (state.isCommentaryOpen) {
        state = state.copyWith(commentarySegmentId: segment.segmentId);
      }
      // Update translation if it's open
      if (state.isTranslationOpen) {
        state = state.copyWith(translationSegmentId: segment.segmentId);
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

  /// Open translation panel for a segment
  void openTranslation(String segmentId) {
    if (_isDisposed) return;
    state = state.copyWith(translationSegmentId: segmentId);
  }

  /// Close translation panel
  void closeTranslation() {
    if (_isDisposed) return;
    state = state.copyWith(clearTranslationSegmentId: true);
  }

  /// Toggle translation panel
  void toggleTranslation(String segmentId) {
    if (_isDisposed) return;

    if (state.translationSegmentId == segmentId) {
      closeTranslation();
    } else {
      openTranslation(segmentId);
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
