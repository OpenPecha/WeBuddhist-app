import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/services/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/services/analytics/posthog_analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton analytics service. Resolves to a real PostHog implementation
/// when `POSTHOG_API_KEY` is present in the loaded `.env`, otherwise a
/// no-op so debug builds and tests don't ship data.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final apiKey = dotenv.maybeGet('POSTHOG_API_KEY') ?? '';
  if (apiKey.isEmpty) {
    return const NoopAnalyticsService();
  }
  final host = dotenv.maybeGet('POSTHOG_HOST') ?? 'https://us.i.posthog.com';
  return PosthogAnalyticsService(apiKey: apiKey, host: host);
});
