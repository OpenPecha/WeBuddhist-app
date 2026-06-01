/// Product analytics abstraction. Features depend on this interface, not PostHog.
abstract class AnalyticsService {
  Future<void> initialize();

  Future<void> identify({
    required String userId,
    Map<String, Object?>? properties,
  });

  Future<void> reset();

  Future<void> track(
    String event, {
    Map<String, Object?>? properties,
  });

  Future<void> setSuperProperties(Map<String, Object?> properties);
}
