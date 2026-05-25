/// Canonical event names. Keep this list curated — every new event should
/// land here so analysts have a single source of truth and we avoid
/// `event_name`/`eventName` style drift in dashboards.
abstract final class AnalyticsEvents {
  static const String login = 'user_logged_in';
  static const String logout = 'user_logged_out';
  static const String guestModeStarted = 'guest_mode_started';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String planStarted = 'plan_started';
  static const String planCompleted = 'plan_completed';
  static const String routineStarted = 'routine_started';
  static const String recitationPlayed = 'recitation_played';
  static const String aiSearchSubmitted = 'ai_search_submitted';
}
