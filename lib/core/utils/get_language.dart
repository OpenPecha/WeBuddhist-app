import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';

String getLanguageLabel(String code, BuildContext context) {
  final localizations = AppLocalizations.of(context)!;
  switch (code.toLowerCase()) {
    case AppConfig.tibetanLanguageCode:
    case 'tibetan':
      return localizations.tibetan;
    case AppConfig.englishLanguageCode:
    case 'english':
      return localizations.english;
    case AppConfig.chineseLanguageCode:
    case 'chinese':
      return localizations.chinese;
    default:
      return localizations.english;
  }
}
