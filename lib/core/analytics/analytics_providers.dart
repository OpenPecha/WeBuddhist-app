import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/posthog_analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton analytics service (PostHog or no-op depending on env).
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return PostHogAnalyticsService.create();
});
