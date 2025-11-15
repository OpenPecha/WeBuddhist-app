import 'package:flutter_pecha/features/recitation/domain/content_type.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';

/// Configuration class for handling language-specific recitation display logic.
///
/// This class provides:
/// - Content parameters for API requests based on language
/// - Content display order based on user's language preference
class RecitationLanguageConfig {
  RecitationLanguageConfig._();

  /// Language code constants for better maintainability
  static const String tibetan = 'bo';
  static const String english = 'en';
  static const String chinese = 'zh';

  /// Returns the appropriate [RecitationContentParams] based on the user's
  /// language preference.
  ///
  /// The params determine which content types are requested from the API:
  /// - Tibetan users: Tibetan recitation + adaptation + English translation
  /// - English users: English translation + Tibetan recitation + English transliteration
  /// - Chinese users: Chinese + English translations + English transliteration
  static RecitationContentParams getContentParams(
    String languageCode,
    String textId,
  ) {
    switch (languageCode) {
      case tibetan:
        return RecitationContentParams(
          textId: textId,
          recitations: [tibetan],
          adaptations: [tibetan],
          translations: [english],
        );

      case english:
        return RecitationContentParams(
          textId: textId,
          translations: [english],
          recitations: [tibetan],
          transliterations: [english],
        );

      case chinese:
        return RecitationContentParams(
          textId: textId,
          translations: [chinese, english],
          transliterations: [english],
        );

      default:
        // Default configuration for unsupported languages
        return RecitationContentParams(
          textId: textId,
          recitations: [tibetan],
          translations: [english],
        );
    }
  }

  /// Returns the display order of content types based on the user's language.
  ///
  /// This determines the visual hierarchy of different content types:
  /// - Tibetan users see: Recitation → Adaptation → Translation
  /// - English users see: Translation → Recitation → Transliteration
  /// - Chinese users see: Translation → Transliteration
  /// - Others see: Recitation → Translation → Transliteration → Adaptation
  static List<ContentType> getContentOrder(String languageCode) {
    switch (languageCode) {
      case tibetan:
        return [
          ContentType.recitation,
          ContentType.adaptation,
          ContentType.translation,
        ];

      case english:
        return [
          ContentType.translation,
          ContentType.recitation,
          ContentType.transliteration,
        ];

      case chinese:
        return [
          ContentType.translation,
          ContentType.transliteration,
        ];

      default:
        return [
          ContentType.recitation,
          ContentType.translation,
          ContentType.transliteration,
          ContentType.adaptation,
        ];
    }
  }

  /// Checks if a language code is supported.
  static bool isLanguageSupported(String languageCode) {
    return [tibetan, english, chinese].contains(languageCode);
  }
}
