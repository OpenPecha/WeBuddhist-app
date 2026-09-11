import 'package:flutter_pecha/core/constants/app_config.dart';

abstract final class GroupEventLiveUtils {
  /// Languages the live stream can be requested in, in toggle order.
  static const List<String> languages = [
    AppConfig.englishLanguageCode,
    AppConfig.tibetanLanguageCode,
    AppConfig.chineseLanguageCode,
  ];

  static const Map<String, String> languageLabels = {
    AppConfig.englishLanguageCode: 'En',
    AppConfig.tibetanLanguageCode: 'བོད',
    AppConfig.chineseLanguageCode: '中文',
  };

  /// The toggle starts on the content language when the stream supports it.
  static String initialLanguage(String contentLanguage) {
    final code = contentLanguage.trim().toLowerCase();
    return languages.contains(code) ? code : AppConfig.englishLanguageCode;
  }

  static bool isLiveLabel(String? label) =>
      label?.toLowerCase().contains('live') ?? false;
}
