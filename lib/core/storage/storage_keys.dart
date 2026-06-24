/// Storage keys - Single source of truth for all storage keys.
///
/// This class consolidates all storage keys used throughout the app.
/// All SharedPreferences and SecureStorage keys should be defined here.
///
/// Note: This replaces the old AppStorageKeys class which was in
/// lib/core/constants/app_storage_keys.dart
class StorageKeys {
  StorageKeys._();

  // ========== AUTHENTICATION ==========
  /// User data JSON
  static const String userData = 'user_data';
  /// Guest mode flag
  static const String isGuestMode = 'is_guest_mode';

  // ========== AUTH TOKENS (Secure Storage) ==========
  /// Access token for API calls
  static const String accessToken = 'access_token';
  /// Refresh token for getting new access tokens
  static const String refreshToken = 'refresh_token';
  /// ID token from Auth0
  static const String idToken = 'id_token';
  /// User ID
  static const String userId = 'user_id';

  // ========== ONBOARDING ==========
  /// Onboarding preferences JSON
  static const String onboardingPreferences = 'onboarding_preferences';
  /// Device-level onboarding completion flag (legacy / guest fallback)
  static const String onboardingCompleted = 'onboarding_completed';
  /// Per-user onboarding completion key — one entry per user ID.
  /// Use this to check/set completion for a specific account.
  static String onboardingCompletedForUser(String userId) =>
      'onboarding_completed_$userId';
  /// ID of the currently logged-in user, written before the router fires
  /// so the route guard can read the correct per-user onboarding key.
  static const String currentUserId = 'current_user_id';
  /// Current onboarding step
  static const String onboardingStep = 'onboarding_step';
  /// Onboarding data JSON
  static const String onboardingData = 'onboarding_data';

  // ========== USER PREFERENCES ==========
  /// Theme mode preference (light/dark/system)
  static const String themeMode = 'theme_mode';
  /// App language/locale preference
  static const String preferredLanguage = 'locale';
  /// Font size preference
  static const String fontSize = 'font_size';
  /// First launch flag
  static const String firstLaunch = 'first_launch';

  // ========== NOTIFICATIONS ==========
  /// Daily reminder time
  static const String dailyReminderTime = 'daily_reminder_time';
  /// Daily reminder enabled flag
  static const String dailyReminderEnabled = 'daily_reminder_enabled';
  /// App-level master notification toggle. When false the app cancels all
  /// scheduled notifications without touching OS permission. Re-enabling
  /// re-schedules from the stored routine. Default: true.
  static const String notificationMasterEnabled = 'notification_master_enabled';
  /// App-level toggle for routine (plan) block notifications. Default: true.
  static const String notificationRoutineEnabled = 'notification_routine_enabled';
  /// App-level toggle for recitation block notifications. Default: true.
  static const String notificationRecitationEnabled = 'notification_recitation_enabled';

  // Special-plan (ITCC and similar) keys — hardcoded per-day content series.
  /// Per-plan startedAt prefix. Full key: `special_plan_started_at_<planId>` → ISO8601 string.
  static const String specialPlanStartedAtPrefix = 'special_plan_started_at_';
  /// Idempotency flag preventing duplicate immediate fires on any series day.
  /// Full key: `special_plan_day1_shown_<planId>_<yyyy-MM-dd>` → bool.
  /// Note: key prefix is kept for backwards compatibility with stored data.
  static const String specialPlanDay1ShownPrefix = 'special_plan_day1_shown_';

  // General plan duration-based notification keys — all other enrolled plans.
  /// Per-plan startedAt prefix. Full key: `plan_started_at_<planId>` → ISO8601 string.
  static const String planStartedAtPrefix = 'plan_started_at_';
  /// Per-plan totalDays prefix. Full key: `plan_total_days_<planId>` → int.
  static const String planTotalDaysPrefix = 'plan_total_days_';
  /// Idempotency flag preventing duplicate immediate fires.
  /// Full key: `plan_immediate_shown_<planId>_<yyyy-MM-dd>` → bool.
  static const String planImmediateShownPrefix = 'plan_immediate_shown_';
  /// Marker recording that today's plan-series notification was handed to the
  /// OS ahead of its fire time, so the catch-up immediate must not re-fire
  /// after the OS delivers it in the background.
  /// Full key: `plan_series_scheduled_<planId>` → `<yyyy-MM-dd>|<notificationId>`.
  static const String planSeriesScheduledPrefix = 'plan_series_scheduled_';

  // ========== FEATURES ==========
  /// Profile data JSON
  static const String profileData = 'profile_data';
  /// Whether the dual-slot reader's secondary panel is enabled. Global UX
  /// preference (bool). Slot picks (language/version/script) are per-text
  /// and live in memory only — they don't survive navigating to a different
  /// text because `versionId` is text-scoped and won't resolve elsewhere.
  static const String readerSecondaryEnabled = 'reader_secondary_enabled';
  /// Bead-tap sound on the mala counter. Default: true.
  static const String malaSoundEnabled = 'mala_sound_enabled';
  /// Haptic feedback on the mala counter. Default: true.
  static const String malaVibrationEnabled = 'mala_vibration_enabled';

  // ========== BUSINESS LOGIC ==========
  /// Last profile update timestamp
  static const String lastProfileUpdate = 'last_profile_update';
  /// Current streak count
  static const String streakCount = 'streak_count';

  // ========== CACHE METADATA ==========
  /// Last sync timestamp
  static const String lastSyncTime = 'last_sync_time';
  /// Cache version for invalidation
  static const String cacheVersion = 'cache_version';
}
