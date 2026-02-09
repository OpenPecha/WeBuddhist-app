import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/domain/services/navigation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Wrapper widget that handles swipe gestures for plan navigation
class SwipeNavigationWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final ReaderParams params;

  const SwipeNavigationWrapper({
    super.key,
    required this.child,
    required this.params,
  });

  @override
  ConsumerState<SwipeNavigationWrapper> createState() =>
      _SwipeNavigationWrapperState();
}

class _SwipeNavigationWrapperState
    extends ConsumerState<SwipeNavigationWrapper> {
  final NavigationService _navigationService = const NavigationService();
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerNotifierProvider(widget.params));
    final navigationContext = state.navigationContext;

    // Only enable swipe if we have plan context
    if (navigationContext == null || !navigationContext.canSwipe) {
      return widget.child;
    }

    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragEnd: (details) => _onDragEnd(details, navigationContext),
      child: Stack(
        children: [
          widget.child,
          // Navigation indicators
          if (navigationContext.hasPreviousText)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _SwipeIndicator(
                direction: SwipeDirection.previous,
                isActive: false,
              ),
            ),
          if (navigationContext.hasNextText)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _SwipeIndicator(
                direction: SwipeDirection.next,
                isActive: false,
              ),
            ),
        ],
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    // Track start position if needed for more complex gesture detection
    // Currently using velocity-based navigation
  }

  void _onDragEnd(DragEndDetails details, NavigationContext navigationContext) {
    if (_isNavigating) return;

    final velocity = details.primaryVelocity ?? 0;

    // Check if swipe velocity exceeds threshold
    if (velocity.abs() < ReaderConstants.swipeVelocityThreshold) {
      return;
    }

    final direction =
        velocity > 0 ? SwipeDirection.previous : SwipeDirection.next;

    // Check if navigation is possible
    if (!_navigationService.canNavigate(navigationContext, direction)) {
      _showEdgeReachedFeedback(direction);
      return;
    }

    _navigateToAdjacentText(navigationContext, direction);
  }

  void _navigateToAdjacentText(
    NavigationContext currentContext,
    SwipeDirection direction,
  ) {
    final newContext = _navigationService.createNavigationContextForAdjacent(
      currentContext,
      direction,
    );

    if (newContext == null) return;

    final adjacentText = _navigationService.getAdjacentText(
      currentContext,
      direction,
    );
    if (adjacentText == null) return;

    _isNavigating = true;

    // Navigate to the new text
    // Pass NavigationContext directly (it already contains targetSegmentId)
    context.pushReplacement(
      '/reader/${adjacentText.textId}',
      extra: newContext,
    );

    // Reset navigating flag after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _isNavigating = false;
    });
  }

  void _showEdgeReachedFeedback(SwipeDirection direction) {
    final message =
        direction == SwipeDirection.next
            ? 'Last text in this day'
            : 'First text in this day';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Visual indicator for swipe navigation
class _SwipeIndicator extends StatelessWidget {
  final SwipeDirection direction;
  final bool isActive;

  const _SwipeIndicator({required this.direction, required this.isActive});

  @override
  Widget build(BuildContext context) {
    // Subtle edge indicator
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isActive ? 8 : 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin:
                direction == SwipeDirection.previous
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
            end:
                direction == SwipeDirection.previous
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primary.withAlpha(isActive ? 128 : 0),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation indicator showing current position in plan
class PlanNavigationIndicator extends StatelessWidget {
  final NavigationProgress progress;

  const PlanNavigationIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progress.hasPrevious) const Icon(Icons.chevron_left, size: 16),
          Text(
            progress.progressText,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (progress.hasNext) const Icon(Icons.chevron_right, size: 16),
        ],
      ),
    );
  }
}
