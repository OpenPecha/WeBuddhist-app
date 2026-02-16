/// Application route definitions
/// Contains all route path constants and route names used throughout the app
///
/// Route Categories:
/// - Public Routes: Accessible without authentication
/// - Guest Accessible Routes: Accessible in guest mode
/// - Protected Routes: Require full authentication
class AppRoutes {
  AppRoutes._();

  // ========== CORE ROUTES ==========
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  // ========== MAIN ROUTES ==========
  static const String home = '/home';
  static const String texts = "/ai-mode";
  static const String practice = "/practice";
  static const String more = "/more";
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
  static const String homePlans = '/home/plans';

  // ========== TEXTS/AI MODE SUB ROUTES ==========
  static const String aiModeSearchResults = '/ai-mode/search-results';
  static const String aiModeTextChapters =
      '/ai-mode/search-results/text-chapters';
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

  // ========== PRACTICE SUB ROUTES ==========
  static const String practiceEditRoutine = '/practice/edit-routine';
  static const String practiceSelectPlan = '/practice/edit-routine/select-plan';
  static const String practiceSelectRecitation =
      '/practice/edit-routine/select-recitation';
  static const String practiceText = '/practice/texts';
  static const String practicePlanPreview = '/practice/plans/preview';
  static const String practicePlanInfo = '/practice/plans/info';
  static const String practicePlanDetails = '/practice/plans/info/details';

  // ========== PLANS SUB ROUTES ==========
  static const String plansInfo = '/plans/info';
  static const String plansDetails = '/plans/details';

  // ========== RECITATIONS SUB ROUTES ==========
  static const String recitationDetail = '/recitations/detail';

  // ========== READER ROUTES ==========
  static const String reader = '/reader';

  // ========== NOTIFICATIONS SUB ROUTES ==========
  static const String notificationSettings = '/notifications/settings';

  // ========== SEARCH ROUTES ==========
  static const String searchResults = '/search-results';

  // ========== ROUTE CATEGORIES ==========

  /// Routes that don't require any authentication
  static const Set<String> publicRoutes = {onboarding, login};

  /// Routes accessible to guest users (includes sub-routes automatically)
  static const Set<String> guestAccessibleRoutes = {
    home,
    more,
    texts,
    practice, // Guests can see empty practice screen
    practicePlanPreview, // Allow guests to browse/preview plans
    reader,
  };

  /// Base paths that require full authentication (prefix matching)
  static const Set<String> _protectedBasePaths = {
    practiceEditRoutine, // Building routine requires auth
    profile,
    notifications,
    plansInfo,
    recitationDetail,
  };

  // ========== HELPER METHODS ==========

  /// Check if a route is fully public (no auth needed at all)
  static bool isPublicRoute(String path) {
    return publicRoutes.contains(path);
  }

  /// Check if a route is accessible to guest users
  static bool isGuestAccessible(String path) {
    if (isPublicRoute(path)) return true;
    return guestAccessibleRoutes.any((route) => _matchesRoute(path, route));
  }

  /// Check if a route requires full authentication
  static bool requiresAuth(String path) {
    // Public and guest routes don't require auth
    if (isGuestAccessible(path)) return false;

    // Check if path matches any protected base path
    return _protectedBasePaths.any((route) => _matchesRoute(path, route));
  }

  /// Match a path against a route pattern (exact or prefix match)
  static bool _matchesRoute(String path, String route) {
    return path == route || path.startsWith('$route/');
  }
}
