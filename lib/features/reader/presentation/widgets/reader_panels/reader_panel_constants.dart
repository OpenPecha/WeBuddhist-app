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
}
