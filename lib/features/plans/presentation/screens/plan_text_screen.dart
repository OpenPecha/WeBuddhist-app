import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigation_bottom_bar.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_subtask_completion.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_bottom_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_button.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lightweight reading screen for plan subtasks where
/// `content_type == "TEXT"`. Shares the same bottom navigation strip with
/// `ReaderScreen` so that prev/next/finish work identically across both
/// content types in a mixed-type plan day.
///
/// Compared to `ReaderScreen`, this screen intentionally omits commentary,
/// segment selection, copy/share, search, language switching and audio —
/// inline plan text has no segments to attach those features to.
class PlanTextScreen extends ConsumerStatefulWidget {
  /// The current subtask's content + plan-list context. The body renders
  /// `navigationContext.currentItem.inlineContent`.
  final NavigationContext navigationContext;

  const PlanTextScreen({super.key, required this.navigationContext});

  @override
  ConsumerState<PlanTextScreen> createState() => _PlanTextScreenState();
}

class _PlanTextScreenState extends ConsumerState<PlanTextScreen> {
  bool _isNavigating = false;

  // New state variables for smooth swipe visual feedback
  double _dragOffset = 0.0;
  bool _isDragging = false;

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
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Text(
          currentItem.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          ReaderFontSizeButton(
            onPressed: () => showFontSizeBottomSheet(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: GestureDetector(
        behavior:
            HitTestBehavior
                .opaque, // Ensures swipes register even on empty spaces
        onHorizontalDragStart: canSwipe ? _onDragStart : null,
        onHorizontalDragUpdate: canSwipe ? _onDragUpdate : null,
        onHorizontalDragEnd: canSwipe ? _onDragEnd : null,
        onHorizontalDragCancel: canSwipe ? _onDragCancel : null,
        child: SafeArea(
          // AnimatedContainer provides the smooth "snap back" effect
          child: AnimatedContainer(
            duration: Duration(milliseconds: _isDragging ? 0 : 250),
            curve: Curves.easeOutCubic,
            // Dampen the visual offset (0.25) to create a subtle tension/spring effect
            transform: Matrix4.translationValues(_dragOffset * 0.25, 0, 0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: SelectableText(
                      currentItem.inlineContent!,
                      style: TextStyle(fontSize: fontSize, height: 1.6),
                    ),
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

  Widget _buildMissingContentScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(child: Text('No content available')),
    );
  }

  void _onDragStart(DragStartDetails details) {
    if (_isNavigating) return;
    setState(() {
      _isDragging = true;
      _dragOffset = 0.0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isNavigating) return;
    setState(() {
      _dragOffset += details.primaryDelta ?? 0;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isNavigating) {
      _resetDrag();
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;

    // Enhanced logic: Trigger if swiped fast OR dragged a fair distance (20% of screen)
    final isHighVelocity =
        velocity.abs() >= ReaderConstants.swipeVelocityThreshold;
    final isFarDrag = _dragOffset.abs() > (screenWidth * 0.2);

    if (isHighVelocity || isFarDrag) {
      // Determine direction (fallback to distance if velocity is 0)
      final isNext = velocity < 0 || (velocity == 0 && _dragOffset < 0);
      final direction = isNext ? SwipeDirection.next : SwipeDirection.previous;
      _navigate(direction);
    }

    _resetDrag();
  }

  void _onDragCancel() {
    _resetDrag();
  }

  void _resetDrag() {
    setState(() {
      _isDragging = false;
      _dragOffset = 0.0;
    });
  }

  void _navigate(SwipeDirection direction) {
    if (_isNavigating) return;

    if (direction == SwipeDirection.next) {
      ref
          .read(planSubtaskCompletionProvider)
          .completeCurrent(widget.navigationContext);
    }

    final didNavigate = PlanNavigator.navigateAdjacent(
      context,
      widget.navigationContext,
      direction,
    );
    if (!didNavigate) {
      // A forward swipe past the last task exits the sequence.
      if (direction == SwipeDirection.next) _finish();
      return;
    }

    setState(() {
      _isNavigating = true;
    });
  }

  void _finish() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    await ref
        .read(planSubtaskCompletionProvider)
        .completeCurrent(widget.navigationContext);

    if (!mounted) return;
    context.pop();
  }
}
