/// Application storage keys
///
/// Single source of truth for all SharedPreferences keys used throughout the app.
/// This consolidates keys from the legacy StorageKeys class.
class AppStorageKeys {
  AppStorageKeys._();

  // ========== AUTHENTICATION ==========
  static const String userData = 'user_data';
  static const String isGuestMode = 'is_guest_mode';

  // ========== ONBOARDING ==========
  static const String onboardingPreferences = 'onboarding_preferences';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String onboardingStep = 'onboarding_step';
  static const String onboardingData = 'onboarding_data';

  // ========== USER PREFERENCES ==========
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale'; // App language/locale preference
  static const String fontSize = 'font_size';
  static const String firstLaunch = 'first_launch';

  // ========== NOTIFICATIONS ==========
  static const String dailyReminderTime = 'daily_reminder_time';
  static const String dailyReminderEnabled = 'dailyReminder_enabled';

  // ========== FEATURES ==========
  static const String profileData = 'profile_data';

  // ========== BUSINESS LOGIC ==========
  static const String lastProfileUpdate = 'last_profile_update';
  static const String streakCount = 'streak_count';
}
