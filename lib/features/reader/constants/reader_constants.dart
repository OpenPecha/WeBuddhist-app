/// Constants for reader feature
class ReaderConstants {
  ReaderConstants._(); // Private constructor to prevent instantiation

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
  static const Duration scrollAnimationDuration = Duration(milliseconds: 500);
  static const Duration instantScrollDuration = Duration(milliseconds: 1);
  static const double scrollToSegmentAlignment = 0.3; // 30% from top

  // Highlight durations by source
  static const Duration planHighlightDuration = Duration(seconds: 3);
  static const Duration searchHighlightDuration = Duration(seconds: 2);
  static const Duration deepLinkHighlightDuration = Duration(seconds: 2);

  // Swipe navigation
  static const double swipeVelocityThreshold = 300.0;
  static const Duration swipeAnimationDuration = Duration(milliseconds: 300);

  // Skeleton loading
  static const int skeletonLineCount = 5;
  static const int skeletonLineCountShort = 3;

  // Loading thresholds
  static const double loadingThresholdPercentage = 0.8;

  // App bar
  static const double appBarElevation = 0.0;
  static const double appBarToolbarHeight = 56.0;
  static const double appBarBottomHeight = 3.0;
  static const bool enableAppBarAutoHide = true; // Set to true to re-enable

  // Segment item
  static const double segmentHorizontalPadding = 12.0;
  static const double segmentVerticalPadding = 6.0;
  static const double segmentNumberWidth = 28.0;
  static const double segmentBorderRadius = 8.0;

  // Font sizes
  static const double tibetanBaseFontSize = 22.0;
  static const double defaultBaseFontSize = 22.0;
  static const double sectionTitleFontSizeTibetan = 26.0;
  static const double sectionTitleFontSizeDefault = 22.0;
}
