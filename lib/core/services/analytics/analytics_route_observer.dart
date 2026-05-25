import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/services/analytics/analytics_service.dart';

/// Reports `$screen` events to analytics when GoRouter pushes or pops a
/// route. Hooked into the top-level GoRouter via `observers:` so the same
/// observer fires for every named route in the app.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _capture(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _capture(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _capture(previousRoute);
  }

  void _capture(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    _analytics.screen(name);
  }
}
