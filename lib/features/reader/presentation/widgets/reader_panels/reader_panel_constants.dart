import 'package:flutter/material.dart';

/// Visual constants shared by the reader Versions/Commentary bottom panels.
class ReaderPanelConstants {
  ReaderPanelConstants._();

  static const double horizontalPadding = 16.0;
  static const double itemSpacing = 16.0;
  static const double sectionSpacing = 20.0;
  static const double contentSpacing = 8.0;

  static const int previewMaxLength = 150;

  static const double topRadius = 20.0;
  static const double cardRadius = 14.0;

  static const double dragHandleWidth = 36.0;
  static const double dragHandleHeight = 4.0;
  static const Radius cardCornerRadius = Radius.circular(cardRadius);
  static const Radius topCornerRadius = Radius.circular(topRadius);

  /// Theme-aware divider color tuned for visibility on both light and dark
  /// reader panel backgrounds. Material's default `dividerColor` is too
  /// subtle on the off-white scaffold background used here.
  static Color dividerColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.14);
  }
}
