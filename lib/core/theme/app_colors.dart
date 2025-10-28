import 'package:flutter/material.dart';

/// Color palette extracted from Figma design
/// Based on Monlam Colors design system
class AppColors {
  AppColors._(); // Prevent instantiation

  // ============ Primary Colors (Action Negative - Red/Burgundy Theme) ============
  static const Color primary = Color(0xFFAD2424); // MAN 700
  static const Color primaryLight = Color(0xFFD32F2F); // MAN 500
  static const Color primaryDark = Color(0xFF871C1C); // MAN 800
  static const Color primaryDarkest = Color(0xFF611414); // MAN 900

  /// Primary color containers and tints
  static const Color primaryContainer = Color(0xFFFAE6E6); // MAN 100
  static const Color primarySurface = Color(0xFFFCF2F2); // MAN 50

  // ============ Surface Colors ============
  static const Color surfaceLight = Color(0xFFFBF9F4); // Light BG
  static const Color surfaceDark = Color(0xFF020C1D); // Dark BG
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // ============ Gold/Accent Colors ============
  /// Warm gold tones for cards and highlights
  static const Color goldLight = Color(0xFFFBF9F4); // MG 50
  static const Color goldAccent = Color(0xFFF6F3E9); // MG 100

  // ============ Grey Scale ============
  static const Color greyLight = Color(0xFFEDEDED); // MGS 100
  static const Color greyMedium = Color(0xFF707070); // MGS 800
  static const Color greyDark = Color(0xFF454545); // MGS 900

  // ============ Text Colors ============
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF707070);

  // ============ Semantic Colors (for compatibility) ============
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF008000);
  static const Color warning = Color(0xFFFFA500);
  static const Color info = Color(0xFF0000FF);
  static const Color danger = Color(0xFFD32F2F);

  // ============ Background Colors ============
  static const Color scaffoldBackgroundLight = Color(0xFFFFFFFF);
  static const Color scaffoldBackgroundDark = Color(0xFF000000);
  static const Color cardBackgroundLight = Color(0xFFF5F5F5);
  static const Color cardBackgroundDark = Color(0xFF232121);

  // ============ Design System Reference ============
  // Figma file: 0TE5qdViUvrisFZfNqODpX/WeBuddhist-App
  // Design system: Monlam Colors
  // Primary theme: Red/Burgundy Buddhist aesthetic
}
