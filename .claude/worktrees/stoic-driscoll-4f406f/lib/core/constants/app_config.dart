class AppConfig {
  AppConfig._();

  static const String appName = 'WeBuddhist';
  static const String appPackageName = 'org.pecha.app';
  static const String appStoreUrl =
      'https://apps.apple.com/app/webuddhist/id6745810914';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=org.pecha.app';

  // Font configuration
  static const String englishSystemFont = 'Inter';
  static const String englishContentFont = 'Source Serif 4';
  static const String chineseSystemFont = 'Noto Sans Traditional Chinese';
  static const String chineseContentFont = 'Noto Serif Traditional Chinese';
  static const String tibetanSystemFont = 'Noto Serif Tibetan';
  static const String tibetanContentFont = 'SambhotaUnicode';

  // Language configuration
  static const String tibetanLanguageCode = 'bo';
  static const String englishLanguageCode = 'en';
  static const String chineseLanguageCode = 'zh';
  static const String tibetanAdaptationLanguageCode = 'tib';
  static const String tibetanTransliterationLanguageCode = 'tibphono';
  static const List<String> supportedLanguages = ['en', 'zh', 'bo'];

  // Theme configuration
  static const String defaultLanguage = 'en';
  static const String defaultThemeMode = 'system';
}
