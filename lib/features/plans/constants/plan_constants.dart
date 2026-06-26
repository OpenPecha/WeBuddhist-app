import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';

/// Constants for the Plans feature
/// Centralized location for magic numbers, colors, and configuration values
class PlanConstants {
  PlanConstants._(); // Private constructor to prevent instantiation

  // Font Sizes
  static const double boFontSize = AppFontConfig.contentFontSize;
  static const double defaultFontSize = AppFontConfig.contentFontSize;
  static const double titleFontSize = AppFontConfig.titleFontSize;
  static const double bodyFontSize = AppFontConfig.bodyFontSize;
  static const double dayNumberFontSize = AppFontConfig.labelFontSize;

  // Pagination
  static const int paginationLimit = 20;
  static const double paginationThreshold =
      200.0; // pixels from bottom to trigger load more

  // UI Dimensions
  static const double dayCarouselViewportFraction = 0.24;
  static const double planCardBorderRadius = 12.0;
  static const double buttonBorderRadius = 20.0;
  static const double authorAvatarRadius = 20.0;

  // Colors
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color successGreen = Colors.green;
  static const Color errorRed = Colors.red;

  // Durations
  static const Duration snackBarDuration = Duration(seconds: 2);
  static const Duration longSnackBarDuration = Duration(seconds: 3);
  static const Duration refreshDelay = Duration(milliseconds: 500);
  static const Duration debounceDelay = Duration(milliseconds: 300);

  // Padding & Spacing
  static const EdgeInsets defaultScreenPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 16.0,
  );

  // Image Dimensions
  static double planImageHeight(BuildContext context) =>
      MediaQuery.of(context).size.height * 0.25;

  // Localized Font Sizes
  static double getFontSizeForLanguage(String language) {
    return language.toLowerCase() == 'bo' ? boFontSize : defaultFontSize;
  }
}
