import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_actions/segement_action_bar.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_app_bar.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/reader_commentary_split_view.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_translation/reader_translation_split_view.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_content_part.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_gestures/swipe_navigation_wrapper.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_search/reader_search_delegate.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_settings_screen.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
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

  // App bar visibility state
  bool _isAppBarVisible = true;
  // Scroll controller callback
  void Function(String segmentId, {double? alignment})? _scrollToSegment;

  @override
  void initState() {
    super.initState();
    _params = ReaderParams(
      textId: widget.textId,
      segmentId: widget.segmentId,
      navigationContext: widget.navigationContext,
    );
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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        // Clear transient reader state so panels don't linger if the user
        // navigates back to this textId again later in the session.
        notifier.selectSegment(null);
        notifier.closeCommentary();
        notifier.closeTranslation();
        _invalidatePlanProviders();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _buildBody(context, state, notifier),
      ),
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

    return Stack(
      children: [
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
                    mainContent: ReaderCommentarySplitView(
                      params: _params,
                      mainContent: Stack(
                        children: [
                          // Reader content with scroll detection
                          ReaderContentPart(
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
                          // Segment action bar (when segment selected and no panel open)
                          if (state.hasSelection &&
                              !state.isCommentaryOpen &&
                              !state.isTranslationOpen)
                            SegmentActionBar(
                              segment: state.selectedSegment!,
                              params: _params,
                              onClose: () => notifier.selectSegment(null),
                              onOpenCommentary: () {
                                if (_scrollToSegment != null &&
                                    state.selectedSegment != null) {
                                  _scrollToSegment!(
                                    state.selectedSegment!.segmentId,
                                    alignment: 0.0,
                                  );
                                }
                              },
                              onOpenTranslation: () {
                                if (_scrollToSegment != null &&
                                    state.selectedSegment != null) {
                                  _scrollToSegment!(
                                    state.selectedSegment!.segmentId,
                                    alignment: 0.0,
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
