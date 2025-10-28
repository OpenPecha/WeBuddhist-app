// This file provides a shared theme utility for the application,
// defining the light and dark themes and other styling elements.
// Defines the application's light and dark themes and theme utilities.
// Shared across all features for consistent styling.
//
// Typography specs from Figma (for reference):
// - Font sizes: 32px, 24px, 18px, 16px, 14px, 12px, 10px, 8px
// - Font weights: Light (300), Regular (400), Medium (500), Semi Bold (600), Bold (700), Extra Bold (800)
// - Primary font: System default (Roboto on Android, SF Pro on iOS)
// - Accent font: Serif fallback for special headings
// - Tibetan: MonlamTibetan (existing implementation)

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme([Locale? locale]) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamilyForLocale(locale),
      scaffoldBackgroundColor: AppColors.surfaceLight,

      // Color scheme based on Figma design
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.primary,
        onSecondary: AppColors.onPrimary,
        error: AppColors.error,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimary,
      ),

      // AppBar with light background
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme with gold accent colors
      cardTheme: CardTheme(
        color: AppColors.goldLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.goldAccent, width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // List tiles
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textPrimary,
      ),

      // Input fields with rounded corners
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.greyMedium,
        fillColor: AppColors.primarySurface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),

      // Bottom navigation bar with burgundy background and rounded top corners
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryDark, // MAN 800
        selectedItemColor: AppColors.surfaceLight,
        unselectedItemColor: AppColors.surfaceLight,
        selectedIconTheme: IconThemeData(
          size: 28,
          color: AppColors.surfaceLight,
        ),
        unselectedIconTheme: IconThemeData(
          size: 24,
          color: AppColors.surfaceLight,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.surfaceLight,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: AppColors.surfaceLight,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.greyLight,
        thickness: 1,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryContainer,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: AppColors.surfaceLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // If locale is Tibetan, set line height to 2.0 for all text styles
    if (locale?.languageCode == 'bo') {
      final baseTextTheme = baseTheme.textTheme;
      final boTextTheme = baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(height: 2.0),
        displayMedium: baseTextTheme.displayMedium?.copyWith(height: 2.0),
        displaySmall: baseTextTheme.displaySmall?.copyWith(height: 2.0),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(height: 2.0),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(height: 2.0),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(height: 2.0),
        titleLarge: baseTextTheme.titleLarge?.copyWith(height: 2.0),
        titleMedium: baseTextTheme.titleMedium?.copyWith(height: 2.0),
        titleSmall: baseTextTheme.titleSmall?.copyWith(height: 2.0),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 2.0),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 2.0),
        bodySmall: baseTextTheme.bodySmall?.copyWith(height: 2.0),
        labelLarge: baseTextTheme.labelLarge?.copyWith(height: 2.0),
        labelMedium: baseTextTheme.labelMedium?.copyWith(height: 2.0),
        labelSmall: baseTextTheme.labelSmall?.copyWith(height: 2.0),
      );
      return baseTheme.copyWith(textTheme: boTextTheme);
    }
    return baseTheme;
  }

  static ThemeData darkTheme([Locale? locale]) {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      fontFamily: _fontFamilyForLocale(locale),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF222222),
        foregroundColor: Colors.white30,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white),
        labelSmall: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        displayLarge: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.white),
        displaySmall: TextStyle(color: Colors.white),
      ),
      cardColor: const Color(0xFF232121),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
      ).copyWith(secondary: Colors.blueAccent, brightness: Brightness.dark),
      listTileTheme: const ListTileThemeData(
        // titleTextStyle removed to inherit fontFamily from theme
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIconColor: Colors.grey[400],
        fillColor: const Color(0xFF444444),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF121212),
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFF7f7f7f),
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
    // If locale is Tibetan, set line height to 2.0 for all text styles
    if (locale?.languageCode == 'bo') {
      final baseTextTheme = baseTheme.textTheme;
      final boTextTheme = baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(height: 2.0),
        displayMedium: baseTextTheme.displayMedium?.copyWith(height: 2.0),
        displaySmall: baseTextTheme.displaySmall?.copyWith(height: 2.0),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(height: 2.0),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(height: 2.0),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(height: 2.0),
        titleLarge: baseTextTheme.titleLarge?.copyWith(height: 2.0),
        titleMedium: baseTextTheme.titleMedium?.copyWith(height: 2.0),
        titleSmall: baseTextTheme.titleSmall?.copyWith(height: 2.0),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 2.0),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 2.0),
        bodySmall: baseTextTheme.bodySmall?.copyWith(height: 2.0),
        labelLarge: baseTextTheme.labelLarge?.copyWith(height: 2.0),
        labelMedium: baseTextTheme.labelMedium?.copyWith(height: 2.0),
        labelSmall: baseTextTheme.labelSmall?.copyWith(height: 2.0),
      );
      return baseTheme.copyWith(textTheme: boTextTheme);
    }
    return baseTheme;
  }

  static String? _fontFamilyForLocale(Locale? locale) {
    if (locale?.languageCode == 'bo') {
      return 'MonlamTibetan';
    }
    return null; // Default font
  }
}
