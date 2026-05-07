import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/domain/services/navigation_service.dart';
import 'package:go_router/go_router.dart';

/// Centralised navigation between plan subtask screens.
///
/// A plan day's subtask list is a flat sequence of mixed content types
/// (SOURCE_REFERENCE → ReaderScreen, TEXT → PlanTextScreen). When the user
/// taps prev/next or swipes, the next item may live on a *different* screen
/// than the current one. This helper picks the right route and replaces the
/// current screen, so the user perceives a seamless "1/N → 2/N" sequence.
class PlanNavigator {
  PlanNavigator._();

  /// Push the screen for [item], scrolling to its first segment (if any),
  /// using the supplied [navigationContext].
  ///
  /// Use [push] for the initial entry from the activity list. For mid-sequence
  /// transitions where the user shouldn't be able to back-stack to every prior
  /// item, use [replace] instead.
  static Future<T?> push<T>(
    BuildContext context,
    PlanTextItem item,
    NavigationContext navigationContext,
  ) {
    return context.push<T>(_routeFor(item), extra: navigationContext);
  }

  /// Same as [push] but replaces the current screen, used by the bottom
  /// bar's prev/next arrows and by horizontal swipes.
  static void replace(
    BuildContext context,
    PlanTextItem item,
    NavigationContext navigationContext,
  ) {
    context.pushReplacement(_routeFor(item), extra: navigationContext);
  }

  /// Move to the adjacent item in [direction]. Returns true if it navigated,
  /// false if there is no neighbour in that direction.
  static bool navigateAdjacent(
    BuildContext context,
    NavigationContext currentContext,
    SwipeDirection direction,
  ) {
    const service = NavigationService();
    final newContext = service.createNavigationContextForAdjacent(
      currentContext,
      direction,
    );
    final adjacent = service.getAdjacentText(currentContext, direction);
    if (newContext == null || adjacent == null) return false;

    replace(context, adjacent, newContext);
    return true;
  }

  static String _routeFor(PlanTextItem item) {
    switch (item.contentType) {
      case PlanItemContentType.sourceReference:
        return '${AppRoutes.reader}/${item.textId}';
      case PlanItemContentType.inlineText:
        // Subtask id is required for plan-text routes; fall back to a stable
        // synthetic id only if the item came from preview (no subtaskId).
        // Item identity is irrelevant to PlanTextScreen — it reads content
        // from navigationContext.currentItem.
        final id = item.subtaskId ?? 'preview';
        return '${AppRoutes.planText}/$id';
    }
  }
}
