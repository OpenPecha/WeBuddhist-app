import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';

export 'package:flutter_pecha/core/theme/font_config.dart' show AppTextSize;

extension HelperFunctions on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}

// Helper function to get the font family for content text (backend texts, recitations, etc.)
// This returns the content font for the given language
String? getFontFamily(String language) {
  return AppFontConfig.getFontFamily(language, FontType.content);
}

// Helper function to get the system/UI font family (sans-serif for EN/ZH)
String? getSystemFontFamily(String language) {
  return AppFontConfig.getFontFamily(language, FontType.system);
}

// Helper function to get TextStyle for content with appropriate font
// Use this for content widgets that need Google Fonts or local fonts
TextStyle? getContentTextStyle(String? language, TextStyle? baseStyle) {
  return AppFontConfig.getContentTextStyle(language, baseStyle);
}

// Helper function to get the line height for a given language
double? getLineHeight(String language) {
  return AppFontConfig.getLineHeight(language);
}

// Helper function to get the font size for a given language
double? getFontSize(String language) {
  if (AppFontConfig.isTibetanLanguage(language)) {
    return AppFontConfig.tibetanContentFontSize;
  }

  switch (language) {
    case AppConfig.englishLanguageCode ||
        AppConfig.tibetanTransliterationLanguageCode:
      return 20;
    case AppConfig.chineseLanguageCode:
      return 18;
    default:
      return null;
  }
}

double getLocalizedFontSize(AppTextSize size) {
  return AppFontConfig.getTextSize(size);
}

/// Soft line-break marker embedded in segment content by the backend.
/// Replaced with a renderer-appropriate break by [normalizeSegmentHtml] /
/// [normalizeSegmentText].
const String kSegmentSoftBreak = '⤵';

/// Converts [kSegmentSoftBreak] to <br> for content passed to an HTML renderer.
String normalizeSegmentHtml(String? raw) =>
    raw?.replaceAll(kSegmentSoftBreak, '<br>') ?? '';

/// Converts [kSegmentSoftBreak] to \n for content displayed in a plain Text widget.
String normalizeSegmentText(String? raw) =>
    raw?.replaceAll(kSegmentSoftBreak, '\n') ?? '';

final _tibetanScriptPattern = RegExp(r'[\u0F00-\u0FFF]');
final _tibetanSyllableSeparatorPattern = RegExp(r'([་།])');

/// Inserts zero-width break opportunities after Tibetan syllable separators so
/// Flutter can wrap long Tibetan runs without leaving a nearly empty last line.
String withTibetanLineBreakOpportunities(String text) {
  if (text.isEmpty || !_tibetanScriptPattern.hasMatch(text)) return text;

  return text.replaceAllMapped(
    _tibetanSyllableSeparatorPattern,
    (match) => '${match[0]}\u200B',
  );
}

final _whitespacePattern = RegExp(r'\s');

/// Inserts zero-width break opportunities so Flutter can wrap [text] that has
/// no whitespace (e.g. a long username).
String withWordBreakOpportunities(String text, {int minLength = 12}) {
  if (text.isEmpty ||
      text.length < minLength ||
      _whitespacePattern.hasMatch(text)) {
    return text;
  }

  return text.split('').join('\u200B');
}

/// Applies Tibetan syllable and word-level break opportunities for constrained UI.
String withDisplayLineBreakOpportunities(String text) {
  return withWordBreakOpportunities(withTibetanLineBreakOpportunities(text));
}

/// Calculates the share position origin for share_plus ShareParams.
///
/// Tries to get the position from the provided [context] or [globalKey].
/// Falls back to screen center if unable to determine position.
///
/// [context] - BuildContext to find render box position
/// [globalKey] - Optional GlobalKey to find widget position
///
/// Returns a Rect representing the share position origin.
Rect getSharePositionOrigin({
  required BuildContext context,
  GlobalKey? globalKey,
}) {
  try {
    // Try to get position from globalKey first if provided
    if (globalKey != null) {
      final RenderBox? box =
          globalKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final Offset position = box.localToGlobal(Offset.zero);
        final Size size = box.size;
        return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
      }
    }

    // Try to get position from context
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final Offset position = box.localToGlobal(Offset.zero);
      final Size size = box.size;
      return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    }
  } catch (e) {
    // Fall through to screen center fallback
  }

  // Fallback to screen center
  final screenSize = MediaQuery.of(context).size;
  return Rect.fromLTWH(
    screenSize.width * 0.5 - 50,
    screenSize.height * 0.5 - 50,
    100,
    100,
  );
}
