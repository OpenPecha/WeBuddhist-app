// This file contains the Tibetan localization delegate for Cupertino widgets.
// Tibetan cupertino localization delegate for the app.
// Provides Tibetan translations for Cupertino widgets.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';

class CupertinoLocalizationsBo extends DefaultCupertinoLocalizations {
  const CupertinoLocalizationsBo();

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      _CupertinoLocalizationsBoDelegate();

  @override
  String get todayLabel => 'དི་རིང་';
  @override
  String get alertDialogLabel => 'ཉེར་སྐྱོད་གྲོས་མོལ';
  @override
  String get cutButtonLabel => 'བཅད་';
  @override
  String get copyButtonLabel => 'འདྲ་བཤུས་';
  @override
  String get pasteButtonLabel => 'འཇུག';
  @override
  String get selectAllButtonLabel => 'ཆ་ཚང་འདེམས';
  // Add more overrides as needed
}

class _CupertinoLocalizationsBoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoLocalizationsBoDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == AppConfig.tibetanLanguageCode;

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return SynchronousFuture<CupertinoLocalizations>(
      const CupertinoLocalizationsBo(),
    );
  }

  @override
  bool shouldReload(_CupertinoLocalizationsBoDelegate old) => false;
}
