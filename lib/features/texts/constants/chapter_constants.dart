/// Constants for chapter reading feature
class ChapterConstants {
  ChapterConstants._(); // Private constructor to prevent instantiation

  // Pagination
  static const int pageSize = 20;
  static const int previousLoadThreshold = 5;
  static const int nextLoadThreshold = 3;

  // Commentary split view
  static const double defaultSplitRatio = 0.5;
  static const double minSplitRatio = 0.2;
  static const double maxSplitRatio = 0.8;
  static const double commentaryDividerHeight = 8.0;

  // Scroll behavior
  static const Duration scrollDebounce = Duration(milliseconds: 100);
  static const Duration scrollAnimationDuration = Duration(milliseconds: 300);
  static const Duration instantScrollDuration = Duration(milliseconds: 1);

  // Loading thresholds
  static const double loadingThresholdPercentage = 0.8;
}
