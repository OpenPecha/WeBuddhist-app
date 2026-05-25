import 'package:flutter/foundation.dart';

/// Abstraction over the product-analytics provider so callers depend on a
/// stable surface instead of the underlying SDK. A no-op implementation is
/// substituted when analytics is disabled (tests, missing config).
abstract class AnalyticsService {
  Future<void> initialize();

  Future<void> identify({
    required String userId,
    Map<String, Object>? userProperties,
  });

  Future<void> reset();

  Future<void> capture(String event, {Map<String, Object>? properties});

  Future<void> screen(String name, {Map<String, Object>? properties});

  Future<void> setEnabled(bool enabled);
}

class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object>? userProperties,
  }) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> capture(String event, {Map<String, Object>? properties}) async {
    if (kDebugMode) {
      debugPrint('[Analytics noop] $event ${properties ?? const {}}');
    }
  }

  @override
  Future<void> screen(String name, {Map<String, Object>? properties}) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}
}
