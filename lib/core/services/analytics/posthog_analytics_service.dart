import 'package:flutter_pecha/core/services/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class PosthogAnalyticsService implements AnalyticsService {
  PosthogAnalyticsService({required String apiKey, required String host})
    : _apiKey = apiKey,
      _host = host;

  final String _apiKey;
  final String _host;
  final _logger = AppLogger('Analytics');
  final Posthog _posthog = Posthog();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    final config = PostHogConfig(_apiKey)
      ..host = _host
      ..captureApplicationLifecycleEvents = true
      ..debug = false;
    await _posthog.setup(config);
    _initialized = true;
    _logger.info('PostHog initialized');
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object>? userProperties,
  }) async {
    if (!_initialized) return;
    await _posthog.identify(userId: userId, userProperties: userProperties);
  }

  @override
  Future<void> reset() async {
    if (!_initialized) return;
    await _posthog.reset();
  }

  @override
  Future<void> capture(String event, {Map<String, Object>? properties}) async {
    if (!_initialized) return;
    await _posthog.capture(eventName: event, properties: properties);
  }

  @override
  Future<void> screen(String name, {Map<String, Object>? properties}) async {
    if (!_initialized) return;
    await _posthog.screen(screenName: name, properties: properties);
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (!_initialized) return;
    if (enabled) {
      await _posthog.enable();
    } else {
      await _posthog.disable();
    }
  }
}
