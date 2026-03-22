import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/domain/services/navigation_service.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Wrapper widget that handles swipe gestures for plan navigation
class SwipeNavigationWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final ReaderParams params;
  final TextDetail textDetail;
  final bool isAppBarVisible;

  const SwipeNavigationWrapper({
    super.key,
    required this.child,
    required this.params,
    required this.textDetail,
    required this.isAppBarVisible,
  });

  @override
  ConsumerState<SwipeNavigationWrapper> createState() =>
      _SwipeNavigationWrapperState();
}

class _SwipeNavigationWrapperState
    extends ConsumerState<SwipeNavigationWrapper> {
  static final _logger = AppLogger('SwipeNavigationWrapper');
  final NavigationService _navigationService = const NavigationService();
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerNotifierProvider(widget.params));
    final navigationContext = state.navigationContext;

    // Hide bottom navigation bar when segment action bar is visible
    final hideBottomNav = state.hasSelection && !state.isCommentaryOpen;

    // Show bottom bar for all readers (with or without navigation context)
    final showBottomBar = !hideBottomNav;

    // Determine if we should enable swipe and show full controls
    final canSwipe = navigationContext != null && navigationContext.canSwipe;
    final isPlanNavigation =
        navigationContext != null &&
        navigationContext.source == NavigationSource.plan;

    return GestureDetector(
      onHorizontalDragStart: canSwipe ? _onDragStart : null,
      onHorizontalDragEnd:
          canSwipe ? (details) => _onDragEnd(details, navigationContext) : null,
      child: Stack(
        children: [
          widget.child,
          // Circular audio play button - positioned above SegmentActionBar
          if (!state.isCommentaryOpen)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: hideBottomNav ? 110 : 80,
              left: MediaQuery.of(context).size.width / 2 - 28,
              child: Material(
                elevation: 4,
                shape: const CircleBorder(),
                color: Theme.of(context).cardColor,
                child: InkWell(
                  onTap: () {
                    // show a comming soon snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    );
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 32,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          // Bottom bar - always present but animated in/out
          if (showBottomBar && !state.isCommentaryOpen)
            _BottomBar(
              textDetail: widget.textDetail,
              navigationContext: navigationContext,
              isPlanNavigation: isPlanNavigation,
              isAppBarVisible: widget.isAppBarVisible,
              onPreviousTap:
                  canSwipe
                      ? () => _navigateToAdjacentText(
                        navigationContext,
                        SwipeDirection.previous,
                      )
                      : null,
              onNextTap:
                  canSwipe
                      ? () => _navigateToAdjacentText(
                        navigationContext,
                        SwipeDirection.next,
                      )
                      : null,
              onFinishedTap: canSwipe ? _finishReading : null,
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
      return;
    }

    _navigateToAdjacentText(navigationContext, direction);
  }

  void _completeCurrentSubtask() {
    final navContext = widget.params.navigationContext;
    if (navContext == null || navContext.source != NavigationSource.plan) return;

    final items = navContext.planTextItems;
    final index = navContext.currentTextIndex;
    if (items == null || index == null || index < 0 || index >= items.length) {
      return;
    }

    final currentItem = items[index];
    final subtaskId = currentItem.subtaskId;
    if (subtaskId == null || subtaskId.isEmpty) return;
    if (currentItem.isCompleted) return;

    Future.microtask(() async {
      try {
        await ref.read(completeSubTaskFutureProvider(subtaskId).future);
        _logger.info('Marked subtask $subtaskId as complete on navigation');
      } catch (e) {
        _logger.error('Failed to complete subtask $subtaskId', e);
      }
    });
  }

  void _navigateToAdjacentText(
    NavigationContext currentContext,
    SwipeDirection direction,
  ) {
    if (_isNavigating) return;

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

    if (direction == SwipeDirection.next) {
      _completeCurrentSubtask();
    }

    _isNavigating = true;

    // Clear UI state before navigation for clean transition
    final notifier = ref.read(readerNotifierProvider(widget.params).notifier);
    notifier.selectSegment(null);
    notifier.closeCommentary();

    // Navigate to the new text
    // Pass NavigationContext directly (it already contains targetSegmentId)
    context.pushReplacement(
      '/reader/${adjacentText.textId}',
      extra: newContext,
    );

    // Reset navigating flag after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _isNavigating = false;
      }
    });
  }

  void _finishReading() {
    _completeCurrentSubtask();

    final navContext = widget.params.navigationContext;
    if (navContext != null && navContext.source == NavigationSource.plan) {
      final planId = navContext.planId;
      final dayNumber = navContext.dayNumber;
      if (planId != null && dayNumber != null) {
        ref.invalidate(
          userPlanDayContentFutureProvider(
            PlanDaysParams(planId: planId, dayNumber: dayNumber),
          ),
        );
        ref.invalidate(userPlanDaysCompletionStatusProvider(planId));
      }
    }
    if (mounted) {
      context.pop();
    }
  }
}

/// Bottom bar - shows title only initially, expands to show full controls when tapped
class _BottomBar extends StatelessWidget {
  final NavigationContext? navigationContext;
  final TextDetail textDetail;
  final bool isPlanNavigation;
  final bool isAppBarVisible;
  final VoidCallback? onPreviousTap;
  final VoidCallback? onNextTap;
  final VoidCallback? onFinishedTap;

  const _BottomBar({
    required this.textDetail,
    required this.navigationContext,
    this.isPlanNavigation = false,
    required this.isAppBarVisible,
    required this.onPreviousTap,
    required this.onNextTap,
    this.onFinishedTap,
  });

  @override
  Widget build(BuildContext context) {
    final canSwipe = navigationContext != null && navigationContext!.canSwipe;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: isAppBarVisible ? Offset.zero : Offset.zero,
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
            child:
                canSwipe
                    ? _buildFullControls(context)
                    : isPlanNavigation
                        ? _buildSingleItemControls(context)
                        : _buildMinimalTitle(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalTitle(BuildContext context) {
    return Center(
      child: Text(
        textDetail.title,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontFamily: getFontFamily(textDetail.language),
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSingleItemControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            textDetail.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFamily: getFontFamily(textDetail.language),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        _NavigationButton(
          icon: Icons.check,
          isEnabled: true,
          onTap: onFinishedTap ?? () => context.pop(),
        ),
      ],
    );
  }

  Widget _buildFullControls(BuildContext context) {
    final hasPrevious = navigationContext!.hasPreviousText;
    final hasNext = navigationContext!.hasNextText;
    final progress = _getProgressText();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous button
        if (hasPrevious)
          _NavigationButton(
            icon: Icons.chevron_left,
            isEnabled: hasPrevious,
            onTap: hasPrevious ? onPreviousTap! : () => context.pop(),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
        if (hasNext)
          _NavigationButton(
            icon: Icons.chevron_right,
            isEnabled: hasNext,
            onTap: hasNext ? onNextTap! : () => context.pop(),
          ),

        // if is last text, show checked icon to pop back to the plan screen
        if (!hasNext)
          _NavigationButton(
            icon: Icons.check,
            isEnabled: !hasNext,
            onTap: onFinishedTap ?? () => context.pop(),
          ),
      ],
    );
  }

  String _getProgressText() {
    final items = navigationContext?.planTextItems;
    final index = navigationContext?.currentTextIndex;
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
