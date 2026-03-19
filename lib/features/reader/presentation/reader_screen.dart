import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:flutter_pecha/features/plans/data/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/data/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_actions/segement_action_bar.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_app_bar.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/reader_commentary_split_view.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_content_part.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_gestures/swipe_navigation_wrapper.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_search/reader_search_delegate.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_version_language_provider.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main reader screen - thin orchestrator that composes child widgets
class ReaderScreen extends ConsumerStatefulWidget {
  final String textId;
  final String? contentId;
  final String? segmentId;
  final NavigationContext? navigationContext;
  final int? colorIndex;

  const ReaderScreen({
    super.key,
    required this.textId,
    this.contentId,
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
      contentId: widget.contentId,
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
        if (didPop) _invalidatePlanProviders();
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

    // Loading state
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(localizations.loading),
          ],
        ),
      );
    }

    // Error state
    if (state.isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.no_content,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => notifier.reload(),
                icon: const Icon(Icons.refresh),
                label: Text(localizations.retry),
              ),
            ],
          ),
        ),
      );
    }

    // Content
    if (state.textDetail == null) {
      return const Center(child: CircularProgressIndicator());
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
                          ? ReaderAppBarOverlay(
                            params: _params,
                            colorIndex: widget.colorIndex,
                            onSearchPressed:
                                () => _handleSearch(context, state),
                            onLanguagePressed:
                                () => _handleLanguageSelection(context, state),
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
                  child: ReaderCommentarySplitView(
                    params: _params,
                    mainContent: Stack(
                      children: [
                        // Reader content with scroll detection
                        ReaderContentPart(
                          params: _params,
                          language: state.textDetail!.language,
                          initialSegmentId: widget.segmentId,
                          onScrollDirectionChanged: _onScrollDirectionChanged,
                          onScrollControllerReady: (scrollFn) {
                            _scrollToSegment = scrollFn;
                          },
                        ),
                        // Segment action bar (when segment selected and commentary closed)
                        if (state.hasSelection && !state.isCommentaryOpen)
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
                          ),
                      ],
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

  Future<void> _handleSearch(BuildContext context, ReaderState state) async {
    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    final router = ref.read(appRouterProvider);

    // Close selection before search
    notifier.selectSegment(null);
    notifier.closeCommentary();

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

  Future<void> _handleLanguageSelection(
    BuildContext context,
    ReaderState state,
  ) async {
    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    final router = ref.read(appRouterProvider);

    // Close selection before navigation
    notifier.selectSegment(null);
    notifier.closeCommentary();

    if (state.textDetail != null) {
      ref
          .read(textVersionLanguageProvider.notifier)
          .setLanguageCode(state.textDetail!.language);

      final result = await router.pushNamed(
        "reader-versions",
        pathParameters: {"textId": widget.textId},
      );

      if (result != null && result is Map<String, dynamic> && mounted) {
        final newTextId = result['textId'] as String?;
        final newContentId = result['contentId'] as String?;

        if (newTextId != null && newContentId != null) {
          router.pushReplacement(
            '/reader/$newTextId',
            extra: NavigationContext(source: NavigationSource.normal),
          );
        }
      }
    }
  }
}
