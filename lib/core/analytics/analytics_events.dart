/// PostHog event names using [object]_[verb] convention.
abstract final class AnalyticsEvents {
  static const String authLoginSucceeded = 'auth_login_succeeded';
  static const String authLoginFailed = 'auth_login_failed';
  static const String authGuestStarted = 'auth_guest_started';
  static const String planEnrolled = 'plan_enrolled';
  static const String routineSaved = 'routine_saved';
}

/// Shared analytics property keys.
abstract final class AnalyticsProperties {
  static const String method = 'method';
  static const String reason = 'reason';
  static const String planId = 'plan_id';
  static const String blockCount = 'block_count';
  static const String itemCount = 'item_count';
  static const String isGuest = 'is_guest';
}
