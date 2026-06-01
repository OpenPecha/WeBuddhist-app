import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

extension BuildContextExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  bool get isTibetanLocale =>
      Localizations.localeOf(this).languageCode == AppConfig.tibetanLanguageCode;

  /// Returns a [StrutStyle] that prevents Tibetan glyphs from being clipped
  /// at the top, or null for non-Tibetan locales.
  StrutStyle? tibetanStrutStyle(double fontSize) => isTibetanLocale
      ? StrutStyle(
          fontSize: fontSize,
          height: 1.6,
          forceStrutHeight: true,
        )
      : null;
}
