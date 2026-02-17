import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/domain/services/navigation_service.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Wrapper widget that handles swipe gestures for plan navigation
class SwipeNavigationWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final ReaderParams params;
  final TextDetail textDetail;

  const SwipeNavigationWrapper({
    super.key,
    required this.child,
    required this.params,
    required this.textDetail,
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

    // Hide bottom navigation bar when segment action bar is visible
    final hideBottomNav = state.hasSelection && !state.isCommentaryOpen;

    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragEnd: (details) => _onDragEnd(details, navigationContext),
      child: Stack(
        children: [
          widget.child,
          // Bottom navigation bar with left/right tap buttons
          if (!hideBottomNav)
            _BottomNavigationBar(
              textDetail: widget.textDetail,
              navigationContext: navigationContext,
              onPreviousTap:
                  () => _navigateToAdjacentText(
                    navigationContext,
                    SwipeDirection.previous,
                  ),
              onNextTap:
                  () => _navigateToAdjacentText(
                    navigationContext,
                    SwipeDirection.next,
                  ),
              onEdgeReached: _showEdgeReachedFeedback,
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

/// Bottom navigation bar with left/right navigation buttons
class _BottomNavigationBar extends StatelessWidget {
  final NavigationContext navigationContext;
  final TextDetail textDetail;
  final VoidCallback onPreviousTap;
  final VoidCallback onNextTap;
  final void Function(SwipeDirection direction) onEdgeReached;

  const _BottomNavigationBar({
    required this.textDetail,
    required this.navigationContext,
    required this.onPreviousTap,
    required this.onNextTap,
    required this.onEdgeReached,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrevious = navigationContext.hasPreviousText;
    final hasNext = navigationContext.hasNextText;
    final progress = _getProgressText();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              _NavigationButton(
                icon: Icons.chevron_left,
                isEnabled: hasPrevious,
                onTap:
                    hasPrevious
                        ? onPreviousTap
                        : () => onEdgeReached(SwipeDirection.previous),
              ),
              // Progress text
              Expanded(
                child: Column(
                  children: [
                    // text title
                    Text(
                      textDetail.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: getFontFamily(textDetail.language),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      progress,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withAlpha(180),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Next button
              _NavigationButton(
                icon: Icons.chevron_right,
                isEnabled: hasNext,
                onTap:
                    hasNext
                        ? onNextTap
                        : () => onEdgeReached(SwipeDirection.next),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getProgressText() {
    final items = navigationContext.planTextItems;
    final index = navigationContext.currentTextIndex;
    if (items == null || index == null) return '';
    return '${index + 1} of ${items.length}';
  }
}

/// Individual navigation button (left/right arrow)
class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isEnabled
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurface.withAlpha(80);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withAlpha(isEnabled ? 100 : 50),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
      ),
    );
  }
}
