import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// Builds a directional slide transition for plan navigation.
///
/// - When navigating **forward** (next): slides in from right
/// - When navigating **backward** (previous): slides in from left
/// - When direction is null (initial load): uses fade transition
Widget buildPlanNavigationTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
  SwipeDirection? direction,
) {
  // No direction? Use fade for initial navigation (e.g., from activity list)
  if (direction == null) {
    return FadeTransition(opacity: animation, child: child);
  }

  final isGoingBack = direction == SwipeDirection.previous;

  // Slide in direction:
  // - Previous (back): slide from LEFT (-1.0 → 0.0)
  // - Next (forward): slide from RIGHT (1.0 → 0.0)
  final slideInTween = Tween<Offset>(
    begin: Offset(isGoingBack ? -1.0 : 1.0, 0.0),
    end: Offset.zero,
  ).chain(
    CurveTween(curve: Curves.easeOutQuart),
  ); // Improved UX: Snappier, native-feeling curve

  // Slide out the old screen in opposite direction:
  // - Previous (back): old screen slides out slightly to RIGHT
  // - Next (forward): old screen slides out slightly to LEFT
  final slideOutTween = Tween<Offset>(
    begin: Offset.zero,
    end: Offset(
      isGoingBack ? 0.3 : -0.3,
      0.0,
    ), // Improved UX: 0.3 creates a modern parallax depth effect
  ).chain(CurveTween(curve: Curves.easeOutQuart));

  return SlideTransition(
    position: animation.drive(slideInTween),
    child: SlideTransition(
      position: secondaryAnimation.drive(slideOutTween),
      child: child,
    ),
  );
}
