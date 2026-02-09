import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/data/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/domain/services/navigation_service.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_actions/segement_action_bar.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_app_bar.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/reader_commentary_split_view.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_content_part.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_controls/reader_chapter_header.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_gestures/swipe_navigation_wrapper.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_search/reader_search_delegate.dart';
import 'package:flutter_pecha/features/texts/constants/text_routes.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_version_language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  static final _logger = AppLogger('ReaderScreen');
  late ReaderParams _params;
  final NavigationService _navigationService = const NavigationService();

  @override
  void initState() {
    super.initState();
    _params = ReaderParams(
      textId: widget.textId,
      contentId: widget.contentId,
      segmentId: widget.segmentId,
      navigationContext: widget.navigationContext,
    );

    // Auto-track subtask completion for enrolled plan navigation
    _trackSubtaskCompletion();
  }

  /// Automatically marks the current subtask as complete when navigating
  /// to a plan text item (via tap or swipe).
  /// Only fires when subtaskId is present (enrolled plan), skipped for preview.
  void _trackSubtaskCompletion() {
    final navContext = widget.navigationContext;
    if (navContext == null || navContext.source != NavigationSource.plan) return;

    final items = navContext.planTextItems;
    final index = navContext.currentTextIndex;
    if (items == null || index == null || index < 0 || index >= items.length) {
      return;
    }

    final subtaskId = items[index].subtaskId;
    if (subtaskId == null || subtaskId.isEmpty) return;

    // Fire-and-forget: mark subtask complete via API
    Future.microtask(() async {
      try {
        final success =
            await ref.read(completeSubTaskFutureProvider(subtaskId).future);
        if (success) {
          _logger.info('Auto-tracked subtask $subtaskId as complete');
        } else {
          _logger.warning('Subtask $subtaskId completion returned false');
        }
      } catch (e) {
        _logger.error('Failed to auto-track subtask $subtaskId', e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerNotifierProvider(_params));
    final notifier = ref.read(readerNotifierProvider(_params).notifier);

    return Scaffold(
      appBar: ReaderAppBar(
        params: _params,
        colorIndex: widget.colorIndex,
        onSearchPressed: () => _handleSearch(context, state),
        onLanguagePressed: () => _handleLanguageSelection(context, state),
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReaderState state,
    ReaderNotifier notifier,
  ) {
    final localizations = AppLocalizations.of(context)!;

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
                label: const Text('Retry'),
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

    return Column(
      children: [
        // Chapter header
        ReaderChapterHeader(textDetail: state.textDetail!),
        // Plan progress indicator (if applicable)
        if (state.navigationContext?.canSwipe ?? false)
          _buildPlanProgressIndicator(state.navigationContext!),
        // Main content area
        Expanded(
          child: SwipeNavigationWrapper(
            params: _params,
            child: ReaderCommentarySplitView(
              params: _params,
              mainContent: Stack(
                children: [
                  // Reader content
                  ReaderContentPart(
                    params: _params,
                    language: state.textDetail!.language,
                    initialSegmentId: widget.segmentId,
                  ),
                  // Segment action bar (when segment selected and commentary closed)
                  if (state.hasSelection && !state.isCommentaryOpen)
                    SegmentActionBar(
                      segment: state.selectedSegment!,
                      params: _params,
                      onClose: () => notifier.selectSegment(null),
                      onOpenCommentary: () {
                        // Scroll to segment when opening commentary
                        // This will be handled by the content widget
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanProgressIndicator(NavigationContext navigationContext) {
    final progress = _navigationService.getProgress(navigationContext);
    if (progress == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [PlanNavigationIndicator(progress: progress)],
      ),
    );
  }

  Future<void> _handleSearch(BuildContext context, ReaderState state) async {
    final notifier = ref.read(readerNotifierProvider(_params).notifier);
    final router = GoRouter.of(context); // Capture router before async gap

    // Close selection before search
    notifier.selectSegment(null);
    notifier.closeCommentary();

    final result = await showSearch<Map<String, String>?>(
      context: context,
      delegate: ReaderSearchDelegate(ref: ref, textId: widget.textId),
    );

    if (result != null && mounted) {
      final selectedTextId = result['textId']!;
      final selectedSegmentId = result['segmentId']!;

      if (selectedTextId == widget.textId) {
        // Same text - highlight and scroll to segment
        notifier.highlightSegment(selectedSegmentId, NavigationSource.search);
      } else {
        // Different text - navigate to it
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
    final router = GoRouter.of(context); // Capture router before async gap

    // Close selection before navigation
    notifier.selectSegment(null);
    notifier.closeCommentary();

    if (state.textDetail != null) {
      ref
          .read(textVersionLanguageProvider.notifier)
          .setLanguage(state.textDetail!.language);

      final result = await router.push(
        TextRoutes.versionSelection,
        extra: {"textId": widget.textId},
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
