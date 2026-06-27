import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_button.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_segment_audio_controller.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_subtask_completion.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_actions/segement_action_bar.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_app_bar.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_more_bottom_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/reader_commentary_split_view.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_translation/reader_translation_split_view.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_content_part.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_gestures/swipe_navigation_wrapper.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_search/reader_search_delegate.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_settings_screen.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Main reader screen - thin orchestrator that composes child widgets
class ReaderScreen extends ConsumerStatefulWidget {
  final String textId;
  final String? segmentId;
  final NavigationContext? navigationContext;
  final int? colorIndex;

  const ReaderScreen({
    super.key,
    required this.textId,
    this.segmentId,
    this.navigationContext,
    this.colorIndex,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with SingleTickerProviderStateMixin {
  late ReaderParams _params;

  /// Gap kept below the floating audio button when it sits over the bare
  /// reader content (no action bar). Matches the original floating offset.
  static const double _audioBottomGap = 76;

  /// Tighter gap used when the audio button sits directly above the segment
  /// action bar, so the button hugs the bar instead of leaving a large empty
  /// band of background between them.
  static const double _audioActionBarGap = 16;

  /// Lets the audio button keep its state when it is reparented between the
  /// behind-panel slot and the bottom overlay.
  final GlobalKey _audioButtonKey = GlobalKey();

  // App bar visibility state
  bool _isAppBarVisible = true;
  // Scroll controller callback
  void Function(String segmentId, {double? alignment})? _scrollToSegment;

  // ─── Audio ─────────────────────────────────────────────────────────────
  // Plays the current SOURCE_REFERENCE subtask's audio when the reader is
  // opened from a plan. Shares the engine with PlanTextScreen.
  PlanSegmentAudioController? _audioController;
  bool _isAdvancing = false;

  bool get _hasAudio => _audioController?.hasAudio ?? false;

  @override
  void initState() {
    super.initState();
    _params = ReaderParams(
      textId: widget.textId,
      segmentId: widget.segmentId,
      navigationContext: widget.navigationContext,
    );
    _initAudio();
  }

  /// Create the audio controller when the reader was opened from a plan and the
  /// current item has resolvable audio (its own `audioUrl` wins over the
  /// day-level track). Auto-plays when the navigation requested it.
  void _initAudio() {
    final ctx = widget.navigationContext;
    if (ctx == null || ctx.source != NavigationSource.plan) return;
    final item = ctx.currentItem;
    if (item == null) return;
    final url = ctx.effectiveAudioUrlFor(item);
    if (url == null) return;

    _audioController = PlanSegmentAudioController(
      url: url,
      startMs: item.startMs,
      endMs: item.endMs,
      onSegmentComplete: _onAudioSegmentComplete,
    );

    if (ctx.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _audioController?.maybeAutoPlay(),
      );
    }
  }

  @override
  void dispose() {
    _audioController?.dispose();
    super.dispose();
  }

  /// Called when the current item's audio finishes. Mirrors
  /// [SwipeNavigationWrapper]'s forward navigation: mark the subtask complete,
  /// clear transient reader UI, then advance to the next task with auto-play.
  /// Pops the sequence when there is no next task.
  void _onAudioSegmentComplete() {
    if (!mounted || _isAdvancing) return;
    final navContext = widget.navigationContext;
    if (navContext == null) return;

    _audioController?.cancel();
    ref.read(planSubtaskCompletionProvider).completeCurrent(navContext);

    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    notifier.selectSegment(null);
    notifier.closeCommentary();
    notifier.closeTranslation();

    final didNavigate = PlanNavigator.navigateAdjacent(
      context,
      navContext,
      SwipeDirection.next,
      autoPlay: true,
    );

    if (didNavigate) {
      _isAdvancing = true;
    } else if (context.canPop()) {
      // Last task in the day — close the sequence.
      context.pop();
    }
  }

  void _onScrollDirectionChanged(bool isScrollingDown) {
    if (!ReaderConstants.enableAppBarAutoHide) return;
    if (isScrollingDown && _isAppBarVisible) {
      setState(() {
        _isAppBarVisible = false;
      });
    } else if (!isScrollingDown && !_isAppBarVisible) {
      setState(() {
        _isAppBarVisible = true;
      });
    }
  }

  void _invalidatePlanProviders() {
    final navContext = widget.navigationContext;
    if (navContext == null || navContext.source != NavigationSource.plan) {
      return;
    }

    final planId = navContext.planId;
    final dayNumber = navContext.dayNumber;
    if (planId == null || dayNumber == null) return;

    ref.invalidate(
      userPlanDayContentFutureProvider(
        PlanDaysParams(planId: planId, dayNumber: dayNumber),
      ),
    );
    ref.invalidate(userPlanDaysCompletionStatusProvider(planId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerNotifierProvider(_params));
    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    final readerTheme = _readerTheme(context);

    return Theme(
      data: readerTheme,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) return;
          // Stop audio immediately so nothing plays during the exit animation.
          _audioController?.cancel();
          // Clear transient reader state so panels don't linger if the user
          // navigates back to this textId again later in the session.
          notifier.selectSegment(null);
          notifier.closeCommentary();
          notifier.closeTranslation();
          _invalidatePlanProviders();
        },
        child: Scaffold(
          backgroundColor: readerTheme.scaffoldBackgroundColor,
          body: _buildBody(context, state, notifier),
        ),
      ),
    );
  }

  ThemeData _readerTheme(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness != Brightness.light) return theme;

    return theme.copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: theme.appBarTheme.copyWith(backgroundColor: Colors.white),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReaderState state,
    ReaderNotifier notifier,
  ) {
    final localizations = context.l10n;
    final textDetail = state.textDetail;
    // Loading state
    if (state.isLoading) {
      return _buildStatusView(
        context,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(localizations.loading),
            ],
          ),
        ),
      );
    }

    // Error / empty content state — always reachable back navigation so the
    // user is never trapped on a dead-end screen. Technical exception text is
    // never surfaced; we show a friendly, localized message instead.
    if (state.isError || state.textDetail == null) {
      return _buildStatusView(
        context,
        child: _ReaderErrorView(
          title: localizations.no_content,
          message: localizations.noContentAvailable,
          retryLabel: localizations.retry,
          backLabel: localizations.back,
          onRetry: () => notifier.reload(),
          onBack: () => _navigateBack(context),
        ),
      );
    }

    final isPanelOpen = state.isCommentaryOpen || state.isTranslationOpen;
    final isActionBarVisible = state.hasSelection && !isPanelOpen;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // Audio in the background of an open panel: keep the button alive
        // (playing or paused) but paint it *under* the content so the opaque
        // panel covers it. Rendered first so it sits behind everything.
        if (_hasAudio && isPanelOpen)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + _audioBottomGap,
            child: Center(child: _buildAudioButton()),
          ),
        // Main content area
        SafeArea(
          child: Column(
            children: [
              // Animated App Bar with smooth hide/show
              AnimatedSize(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: _isAppBarVisible ? null : 0,
                  child:
                      _isAppBarVisible
                          ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReaderAppBarOverlay(
                                params: _params,
                                colorIndex: widget.colorIndex,
                                onSearchPressed:
                                    () => _handleSearch(context, state),
                                onSettingsPressed:
                                    () => _openReaderSettings(
                                      context,
                                      textDetail,
                                    ),
                                onMorePressed:
                                    () => _openMoreBottomSheet(
                                      context,
                                      textDetail,
                                    ),
                              ),
                            ],
                          )
                          : const SizedBox.shrink(),
                ),
              ),
              // Main scrollable content
              Expanded(
                child: SwipeNavigationWrapper(
                  params: _params,
                  textDetail: state.textDetail!,
                  isAppBarVisible: _isAppBarVisible,
                  child: ReaderTranslationSplitView(
                    params: _params,
                    // Reader content with scroll detection. The segment action
                    // bar is hosted in the screen-level bottom overlay so it
                    // can share a fixed gap with the floating audio button.
                    mainContent: ReaderCommentarySplitView(
                      params: _params,
                      mainContent: ReaderContentPart(
                        params: _params,
                        language: state.textDetail!.language,
                        initialSegmentId: widget.segmentId,
                        visibleSegmentIds:
                            widget.navigationContext?.currentSegmentIds,
                        onScrollDirectionChanged: _onScrollDirectionChanged,
                        onScrollControllerReady: (scrollFn) {
                          _scrollToSegment = scrollFn;
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom overlay (only when no panel is open): the floating audio
        // button sits above the segment action bar, sharing a fixed gap so
        // the two never overlap. When neither is present this branch is
        // skipped entirely.
        if (!isPanelOpen && (_hasAudio || isActionBarVisible))
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Stretch so the action bar spans full width; the audio button
              // is centered explicitly.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_hasAudio)
                  Padding(
                    // Hug the action bar with a tight gap when it is open;
                    // otherwise keep the original floating offset above bottom.
                    padding: EdgeInsets.only(
                      bottom:
                          isActionBarVisible
                              ? _audioActionBarGap
                              : bottomInset + _audioBottomGap,
                    ),
                    child: Center(child: _buildAudioButton()),
                  ),
                if (isActionBarVisible) _buildSegmentActionBar(state, notifier),
              ],
            ),
          ),
      ],
    );
  }

  /// The floating plan audio play/pause control. Keyed so its animation state
  /// survives reparenting between the behind-panel slot and the bottom overlay.
  Widget _buildAudioButton() {
    return PlanAudioButton(key: _audioButtonKey, controller: _audioController!);
  }

  /// Segment action bar wired to the reader notifier. Scrolls the selected
  /// segment to the top when a commentary/translation panel is opened.
  Widget _buildSegmentActionBar(ReaderState state, ReaderNotifier notifier) {
    return SegmentActionBar(
      segment: state.selectedSegment!,
      params: _params,
      onClose: () => notifier.selectSegment(null),
      onOpenCommentary: () {
        if (_scrollToSegment != null && state.selectedSegment != null) {
          _scrollToSegment!(state.selectedSegment!.segmentId, alignment: 0.0);
        }
      },
      onOpenTranslation: () {
        if (_scrollToSegment != null && state.selectedSegment != null) {
          _scrollToSegment!(state.selectedSegment!.segmentId, alignment: 0.0);
        }
      },
    );
  }

  /// Wraps a status view (loading / error / empty) in a [SafeArea] with a
  /// minimal app bar that always exposes a back button. This guarantees the
  /// user can leave the screen even when content fails to load.
  Widget _buildStatusView(BuildContext context, {required Widget child}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                tooltip: context.l10n.back,
                onPressed: () => _navigateBack(context),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  /// Pops back if possible, otherwise falls back to the home route so the user
  /// is never stranded (e.g. when arriving via a deep link with no history).
  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleSearch(BuildContext context, ReaderState state) async {
    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    final router = ref.read(appRouterProvider);

    // Close selection before search
    notifier.selectSegment(null);
    notifier.closeCommentary();
    notifier.closeTranslation();

    final result = await showSearch<Map<String, String>?>(
      context: context,
      delegate: ReaderSearchDelegate(
        ref: ref,
        textId: widget.textId,
        language: state.textDetail?.language,
      ),
    );

    if (result != null && mounted) {
      final selectedTextId = result['textId']!;
      final selectedSegmentId = result['segmentId']!;

      if (selectedTextId == widget.textId) {
        router.pushReplacement(
          '/reader/$selectedTextId',
          extra: NavigationContext(
            source: NavigationSource.search,
            targetSegmentId: selectedSegmentId,
          ),
        );
      }
    }
  }

  Future<void> _openReaderSettings(
    BuildContext context,
    TextDetail? textDetail,
  ) async {
    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    notifier.selectSegment(null);
    notifier.closeCommentary();
    notifier.closeTranslation();

    // Pass the currently-loaded primary display so the settings screen can
    // show it under "Main text" without the reader notifier having to write
    // into a global settings store as a side effect. The backend returns a
    // raw language code (e.g. "bo") — render it through getLanguageName so
    // the user sees "Tibetan", not "bo". `versionId` in this API is just the
    // loaded text's id, so textDetail.id / textDetail.title pre-fill the
    // version row of the Main text card.
    final languageCode = textDetail?.language ?? 'en';
    final initialPrimaryDisplay = ReaderSlotConfig(
      languageCode: languageCode,
      languageLabel: getLanguageName(languageCode, context),
      versionId: textDetail?.id,
      versionLabel: textDetail?.title,
    );

    await openReaderSettings(
      context,
      textId: widget.textId,
      initialPrimaryDisplay: initialPrimaryDisplay,
    );
  }

  void _openMoreBottomSheet(BuildContext context, TextDetail? textDetail) {
    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    notifier.selectSegment(null);
    notifier.closeCommentary();
    notifier.closeTranslation();

    final showAddToPractices =
        (widget.navigationContext?.source == NavigationSource.recitationList ||
            widget.navigationContext?.source == NavigationSource.routine) &&
        textDetail != null;

    showReaderMoreBottomSheet(
      context,
      showAddToPractices: showAddToPractices,
      onAddToPractices:
          showAddToPractices
              ? () => _openRoutineWithRecitation(context, textDetail)
              : null,
      onBookmark: () => _bookmarkText(context),
    );
  }

  /// Bookmarks the current text. Invoked after the "more" sheet has been
  /// dismissed, using the reader's own context so the success/login feedback
  /// isn't drawn behind the closing modal.
  void _bookmarkText(BuildContext context) {
    BookmarkController(ref: ref, context: context).bookmarkText(widget.textId);
  }

  void _openRoutineWithRecitation(BuildContext context, TextDetail textDetail) {
    context.push(
      AppRoutes.practiceEditRoutine,
      extra: {
        'initialRecitation': RecitationModel(
          textId: widget.textId,
          title: textDetail.title,
          language: textDetail.language,
        ),
      },
    );
  }
}

/// Friendly, centered error/empty state for the reader with retry and back
/// actions. Intentionally hides raw exception details from the user.
class _ReaderErrorView extends StatelessWidget {
  final String title;
  final String message;
  final String retryLabel;
  final String backLabel;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ReaderErrorView({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.backLabel,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(backLabel),
            ),
          ],
        ),
      ),
    );
  }
}
