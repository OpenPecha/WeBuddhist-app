// Font configuration for multi-language support
// Defines system fonts (for UI) and content fonts (for backend texts)
// for each supported language.

// - Tibetan (bo): Noto Serif Tibetan for system UI and SambhotaUnicode for content/source
// - English (en): Inter for system UI and Source Serif 4 for content/source
// - Chinese (zh): Noto Sans Traditional Chinese for system UI and Noto Serif Traditional Chinese for content
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';

/// Defines the type of font usage in the application
enum FontType {
  /// System font: Used for UI elements like tabs, navigation, settings, buttons
  system,

  /// Content font: Used for content from backend like texts, practice plans, recitations
  content,
}

/// Configuration for a language's font families
class LanguageFontConfig {
  final String systemFont;

  final String contentFont;

  final bool systemFontIsGoogle;
  final bool contentFontIsGoogle;

  const LanguageFontConfig({
    required this.systemFont,
    required this.contentFont,
    this.systemFontIsGoogle = true,
    this.contentFontIsGoogle = true,
  });
}

/// Central font configuration for all supported languages
class AppFontConfig {
  AppFontConfig._();

  static const Map<String, LanguageFontConfig> _languageFonts = {
    // Tibetan - Noto Serif Tibetan for UI, SambhotaUnicode for content/source
    AppConfig.tibetanLanguageCode: LanguageFontConfig(
      systemFont: AppConfig.tibetanSystemFont,
      contentFont: AppConfig.tibetanContentFont,
      systemFontIsGoogle: true,
      contentFontIsGoogle: false,
    ),

    AppConfig.tibetanAdaptationLanguageCode: LanguageFontConfig(
      systemFont: AppConfig.tibetanSystemFont,
      contentFont: AppConfig.tibetanContentFont,
      systemFontIsGoogle: true,
      contentFontIsGoogle: false,
    ),

    // English - Google Inter for UI, Source Serif 4 for content
    AppConfig.englishLanguageCode: LanguageFontConfig(
      systemFont: AppConfig.englishSystemFont,
      contentFont: AppConfig.englishContentFont,
      systemFontIsGoogle: true,
      contentFontIsGoogle: true,
    ),

    AppConfig.tibetanTransliterationLanguageCode: LanguageFontConfig(
      systemFont: AppConfig.englishSystemFont,
      contentFont: AppConfig.englishContentFont,
      systemFontIsGoogle: true,
      contentFontIsGoogle: true,
    ),

    // Chinese (zh-TW) - Noto Sans Traditional Chinese for UI, Noto Serif Traditional Chinese for content
    AppConfig.chineseLanguageCode: LanguageFontConfig(
      systemFont: AppConfig.chineseSystemFont,
      contentFont: AppConfig.chineseContentFont,
      systemFontIsGoogle: true,
      contentFontIsGoogle: true,
    ),
  };

  /// Default font configuration (used when language is not found)
  static const LanguageFontConfig _defaultConfig = LanguageFontConfig(
    systemFont: AppConfig.englishSystemFont,
    contentFont: AppConfig.englishContentFont,
    systemFontIsGoogle: true,
    contentFontIsGoogle: true,
  );

  /// Get font configuration for a specific language
  static LanguageFontConfig getConfig(String? languageCode) {
    if (languageCode == null) return _defaultConfig;
    return _languageFonts[languageCode.toLowerCase()] ?? _defaultConfig;
  }

  /// Get font family name for a specific language and font type
  /// Returns the actual font family string that can be used with TextStyle
  static String getFontFamily(String? languageCode, FontType fontType) {
    final config = getConfig(languageCode);
    final fontName =
        fontType == FontType.system ? config.systemFont : config.contentFont;
    final isGoogle =
        fontType == FontType.system
            ? config.systemFontIsGoogle
            : config.contentFontIsGoogle;

    if (!isGoogle) {
      // Return local font family name as-is
      return fontName;
    }

    // For Google Fonts, return the font family name from the GoogleFonts API
    return _getGoogleFontFamilyName(fontName);
  }

  /// Helper to get the actual font family name from Google Fonts
  static String _getGoogleFontFamilyName(String fontName) {
    switch (fontName) {
      case AppConfig.englishSystemFont:
        return GoogleFonts.inter().fontFamily ?? AppConfig.englishSystemFont;
      case AppConfig.englishContentFont:
        return GoogleFonts.sourceSerif4().fontFamily ??
            AppConfig.englishContentFont;
      case AppConfig.tibetanSystemFont:
        return GoogleFonts.notoSerifTibetan().fontFamily ??
            AppConfig.tibetanSystemFont;
      case AppConfig.chineseSystemFont:
        return GoogleFonts.notoSansTc().fontFamily ??
            AppConfig.chineseSystemFont;
      case AppConfig.chineseContentFont:
        return GoogleFonts.notoSerifTc().fontFamily ??
            AppConfig.chineseContentFont;
      default:
        return GoogleFonts.inter().fontFamily ?? AppConfig.englishSystemFont;
    }
  }

  /// Get TextTheme with appropriate font for a language and font type
  /// This is used for system UI elements
  static TextTheme getTextTheme(
    String? languageCode,
    FontType fontType,
    Brightness brightness,
  ) {
    final config = getConfig(languageCode);
    final fontName =
        fontType == FontType.system ? config.systemFont : config.contentFont;
    final isGoogle =
        fontType == FontType.system
            ? config.systemFontIsGoogle
            : config.contentFontIsGoogle;

    if (!isGoogle) {
      // For local fonts, return null to use fontFamily in ThemeData
      return ThemeData(brightness: brightness).textTheme;
    }

    // Use Google Fonts
    return _getGoogleFontTextTheme(fontName, brightness);
  }

  /// Helper method to get Google Font TextTheme by font name
  static TextTheme _getGoogleFontTextTheme(
    String fontName,
    Brightness brightness,
  ) {
    final baseTextTheme = ThemeData(brightness: brightness).textTheme;

    switch (fontName) {
      case AppConfig.englishSystemFont:
        return GoogleFonts.interTextTheme(baseTextTheme);
      case AppConfig.englishContentFont:
        return GoogleFonts.sourceSerif4TextTheme(baseTextTheme);
      case AppConfig.tibetanSystemFont:
        return GoogleFonts.notoSerifTibetanTextTheme(baseTextTheme);
      case AppConfig.chineseSystemFont:
        return GoogleFonts.notoSansTcTextTheme(baseTextTheme);
      case AppConfig.chineseContentFont:
        return GoogleFonts.notoSerifTcTextTheme(baseTextTheme);
      default:
        return GoogleFonts.interTextTheme(baseTextTheme);
    }
  }

  /// Get text style for content with appropriate font
  static TextStyle? getContentTextStyle(
    String? languageCode,
    TextStyle? baseStyle,
  ) {
    final config = getConfig(languageCode);

    if (!config.contentFontIsGoogle) {
      // For local fonts
      return baseStyle?.copyWith(fontFamily: config.contentFont);
    }

    // Use Google Fonts
    return _getGoogleFontTextStyle(config.contentFont, baseStyle);
  }

  /// Helper method to get Google Font TextStyle by font name
  static TextStyle? _getGoogleFontTextStyle(
    String fontName,
    TextStyle? baseStyle,
  ) {
    switch (fontName) {
      case AppConfig.englishSystemFont:
        return GoogleFonts.inter(textStyle: baseStyle);
      case AppConfig.englishContentFont:
        return GoogleFonts.sourceSerif4(textStyle: baseStyle);
      case AppConfig.tibetanSystemFont:
        return GoogleFonts.notoSerifTibetan(textStyle: baseStyle);
      case AppConfig.chineseSystemFont:
        return GoogleFonts.notoSansTc(textStyle: baseStyle);
      case AppConfig.chineseContentFont:
        return GoogleFonts.notoSerifTc(textStyle: baseStyle);
      default:
        return GoogleFonts.inter(textStyle: baseStyle);
    }
  }

  /// Get all supported language codes
  static List<String> get supportedLanguages => _languageFonts.keys.toList();
}
