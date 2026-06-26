import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';

extension BuildContextExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  bool get isTibetanLocale => AppFontConfig.isTibetanLanguage(
    Localizations.localeOf(this).languageCode,
  );

  /// Returns a [StrutStyle] that prevents Tibetan glyphs from being clipped
  /// at the top, or null for non-Tibetan locales.
  StrutStyle? tibetanStrutStyle(double fontSize, {bool compact = false}) =>
      AppFontConfig.tibetanStrutStyle(
        Localizations.localeOf(this).languageCode,
        fontSize,
        compact: compact,
      );
}
