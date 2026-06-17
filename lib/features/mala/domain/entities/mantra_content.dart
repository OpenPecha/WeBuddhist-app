import 'package:equatable/equatable.dart';

/// One localized rendering of a mantra's text.
///
/// Mantra content lives in the standalone `GET /mantra` endpoint, keyed by
/// mantra id, with one entry per language (`bo`, `en`, `zh`, ...).
class MantraLocalization extends Equatable {
  final String id;
  final String text;
  final String? meaning;
  final String? transliteration;
  final String language;

  const MantraLocalization({
    required this.id,
    required this.text,
    this.meaning,
    this.transliteration,
    required this.language,
  });

  @override
  List<Object?> get props => [id, text, meaning, transliteration, language];
}

/// A mantra and all of its localized renderings (from `GET /mantra`).
class MantraContent extends Equatable {
  final String id;
  final String? audioUrl;
  final List<MantraLocalization> localizations;

  const MantraContent({
    required this.id,
    this.audioUrl,
    this.localizations = const [],
  });

  /// The Tibetan (`bo`) rendering if present, otherwise the first available.
  MantraLocalization? get tibetan =>
      _byLanguage('bo') ?? (localizations.isNotEmpty ? localizations.first : null);

  /// Best localization for [language], falling back to English then anything.
  MantraLocalization? localized(String language) =>
      _byLanguage(language) ?? _byLanguage('en') ??
      (localizations.isNotEmpty ? localizations.first : null);

  MantraLocalization? _byLanguage(String language) {
    for (final l in localizations) {
      if (l.language.toLowerCase() == language.toLowerCase()) return l;
    }
    return null;
  }

  @override
  List<Object?> get props => [id, audioUrl, localizations];
}
