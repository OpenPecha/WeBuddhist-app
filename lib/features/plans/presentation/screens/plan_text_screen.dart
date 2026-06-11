import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_button.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigation_bottom_bar.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_segment_audio_controller.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_subtask_completion.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_bottom_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_button.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lightweight reading screen for plan subtasks where `content_type == "TEXT"`.
///
/// The subtask `content` is treated as markdown and rendered via
/// [PlanInlineMarkdownView]. Plain text remains valid markdown so callers
/// without formatting need no changes.
///
/// Audio behaviour (shared with `ReaderScreen` via
/// [PlanSegmentAudioController]):
/// - A floating play/pause button appears when the task has resolvable audio
///   (its own `audioUrl`, or the day-level track as fallback).
/// - Tapping it plays the task's segment. When the segment ends the screen
///   auto-advances to the next task with auto-play.
/// - Audio stops on any manual navigation or back press — no leaks.
class PlanTextScreen extends ConsumerStatefulWidget {
  final NavigationContext navigationContext;
  const PlanTextScreen({super.key, required this.navigationContext});

  @override
  ConsumerState<PlanTextScreen> createState() => _PlanTextScreenState();
}

class _PlanTextScreenState extends ConsumerState<PlanTextScreen> {
  // ─── Navigation state ──────────────────────────────────────────────────
  bool _isNavigating = false;
  double _dragOffset = 0.0;
  bool _isDragging = false;

  // ─── Audio ─────────────────────────────────────────────────────────────
  PlanSegmentAudioController? _audioController;

  bool get _hasAudio => _audioController?.hasAudio ?? false;

  // ─── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initAudio();
    if (widget.navigationContext.autoPlay && _hasAudio) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _audioController?.maybeAutoPlay(),
      );
    }
  }

  /// Resolve the audio for the current item (subtask audio wins over the
  /// day-level track) and create the controller if any audio is available.
  void _initAudio() {
    final ctx = widget.navigationContext;
    final item = ctx.currentItem;
    if (item == null) return;
    final url = ctx.effectiveAudioUrlFor(item);
    if (url == null) return;
    _audioController = PlanSegmentAudioController(
      url: url,
      startMs: item.startMs,
      endMs: item.endMs,
      onSegmentComplete: _autoAdvance,
    );
  }

  @override
  void dispose() {
    _audioController?.dispose();
    super.dispose();
  }

  /// Called by the audio controller when the segment finishes. Marks the
  /// current subtask complete and navigates to the next task with auto-play.
  /// Falls through to [_finish] on the last task.
  void _autoAdvance() {
    if (!mounted || _isNavigating) return;

    _audioController?.cancel();
    ref
        .read(planSubtaskCompletionProvider)
        .completeCurrent(widget.navigationContext);

    final didNavigate = PlanNavigator.navigateAdjacent(
      context,
      widget.navigationContext,
      SwipeDirection.next,
      autoPlay: true,
    );

    if (didNavigate) {
      setState(() => _isNavigating = true);
    } else {
      _finish(); // no next task — close the sequence
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.navigationContext.currentItem;
    final fontSize = ref.watch(fontSizeProvider);

    if (currentItem == null || currentItem.inlineContent == null) {
      return _buildMissingContentScaffold(context);
    }

    final canSwipe = widget.navigationContext.canSwipe;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, currentItem.title),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: canSwipe ? _onDragStart : null,
        onHorizontalDragUpdate: canSwipe ? _onDragUpdate : null,
        onHorizontalDragEnd: canSwipe ? _onDragEnd : null,
        onHorizontalDragCancel: canSwipe ? _onDragCancel : null,
        child: SafeArea(
          child: AnimatedContainer(
            duration: Duration(milliseconds: _isDragging ? 0 : 250),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_dragOffset * 0.25, 0, 0),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Text content — extra bottom padding reserves visual
                      // space so the last line stays above the floating button.
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          16,
                          20,
                          _hasAudio ? 88 : 16,
                        ),
                        child: PlanInlineMarkdownView(
                          content: currentItem.inlineContent!,
                          fontSize: fontSize,
                        ),
                      ),
                      // Floating play/pause — overlaid, zero layout footprint.
                      if (_hasAudio)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 8,
                          child: Center(
                            child: PlanAudioButton(
                              controller: _audioController!,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                PlanNavigationBottomBar(
                  navigationContext: widget.navigationContext,
                  fallbackTitle: currentItem.title,
                  onPreviousTap: () => _navigate(SwipeDirection.previous),
                  onNextTap: () => _navigate(SwipeDirection.next),
                  onFinishedTap: _finish,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(AppAssets.arrowLeft),
        onPressed: () {
          _audioController?.cancel();
          context.pop();
        },
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: [
        ReaderFontSizeButton(onPressed: () => showFontSizeBottomSheet(context)),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildMissingContentScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(child: Text(context.l10n.no_content)),
    );
  }

  // ─── Drag / swipe ──────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    if (_isNavigating) return;
    setState(() {
      _isDragging = true;
      _dragOffset = 0.0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isNavigating) return;
    setState(() => _dragOffset += details.primaryDelta ?? 0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isNavigating) {
      _resetDrag();
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isHighVelocity =
        velocity.abs() >= ReaderConstants.swipeVelocityThreshold;
    final isFarDrag = _dragOffset.abs() > screenWidth * 0.2;

    if (isHighVelocity || isFarDrag) {
      final goNext = velocity < 0 || (velocity == 0 && _dragOffset < 0);
      _navigate(goNext ? SwipeDirection.next : SwipeDirection.previous);
    }
    _resetDrag();
  }

  void _onDragCancel() => _resetDrag();

  void _resetDrag() {
    setState(() {
      _isDragging = false;
      _dragOffset = 0.0;
    });
  }

  // ─── Navigation ────────────────────────────────────────────────────────

  void _navigate(SwipeDirection direction) {
    if (_isNavigating) return;
    if (direction == SwipeDirection.next) {
      ref
          .read(planSubtaskCompletionProvider)
          .completeCurrent(widget.navigationContext);
    }
    _audioController?.cancel();
    final didNavigate = PlanNavigator.navigateAdjacent(
      context,
      widget.navigationContext,
      direction,
    );
    if (!didNavigate && direction == SwipeDirection.next) {
      _finish();
      return;
    }
    if (didNavigate) setState(() => _isNavigating = true);
  }

  void _finish() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    _audioController?.cancel();
    await ref
        .read(planSubtaskCompletionProvider)
        .completeCurrent(widget.navigationContext);
    if (!mounted) return;
    context.pop();
  }
}
