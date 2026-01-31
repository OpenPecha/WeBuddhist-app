/// Application route definitions
/// Contains all route path constants and route names used throughout the app
class AppRoutes {
  AppRoutes._();

  // ========== CORE ROUTES ==========
  static const String comingSoon = '/coming-soon';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  // ========== MAIN ROUTES ==========
  static const String home = '/home';
  static const String profile = '/profile';
  static const String creatorInfo = '/creator_info';
  static const String notifications = '/notifications';

  // ========== HOME SUB ROUTES ==========
  static const String homeVideoPlayer = '/home/video_player';
  static const String homeViewIllustration = '/home/view_illustration';
  static const String homeMeditationOfTheDay = '/home/meditation_of_the_day';
  static const String homeMeditationVideo = '/home/meditation_video';
  static const String homeStories = '/home/stories';
  static const String homeStoriesPresenter = '/home/stories-presenter';
  static const String homePlanStoriesPresenter = '/home/plan-stories-presenter';
  static const String homePrayerOfTheDay = '/home/prayer_of_the_day';

  // ========== TEXTS SUB ROUTES ==========
  static const String textsCollections = '/texts/collections';
  static const String textsCategory = '/texts/category';
  static const String textsWorks = '/texts/works';
  static const String textsTexts = '/texts/texts';
  static const String textsChapters = '/texts/chapters';
  static const String textsVersionSelection = '/texts/version_selection';
  static const String textsLanguageSelection = '/texts/language_selection';
  static const String textsSegmentImageChooseImage =
      '/texts/segment_image/choose_image';
  static const String textsSegmentImageCreateImage =
      '/texts/segment_image/create_image';
  static const String textsCommentary = '/texts/commentary';

  // ========== PLANS SUB ROUTES ==========
  static const String plansInfo = '/plans/info';
  static const String plansDetails = '/plans/details';

  // ========== RECITATIONS SUB ROUTES ==========
  static const String recitationDetail = '/recitations/detail';

  // ========== NOTIFICATIONS SUB ROUTES ==========
  static const String notificationSettings = '/notifications/settings';

  /// Check if route requires authentication
  static bool requiresAuth(String route) {
    const publicRoutes = [onboarding, login, comingSoon];
    return !publicRoutes.contains(route);
  }
}
