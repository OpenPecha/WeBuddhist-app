// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pecha App';

  @override
  String get pechaHeading => 'Pecha';

  @override
  String get learnLiveShare => 'Learn Live and Share';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get switchToLight => 'Switch to Light Mode';

  @override
  String get switchToDark => 'Switch to Dark Mode';
}
