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
  /// Onboarding completion flag
  static const String onboardingCompleted = 'onboarding_completed';
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

  // ========== FEATURES ==========
  /// Profile data JSON
  static const String profileData = 'profile_data';

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
