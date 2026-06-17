import 'package:flutter_pecha/features/mala/domain/entities/mantra_content.dart';

/// Maps `MantraMetadataDTO` — one localized rendering of a mantra.
class MantraLocalizationModel {
  const MantraLocalizationModel({
    required this.id,
    required this.text,
    this.meaning,
    this.transliteration,
    required this.language,
  });

  final String id;
  final String text;
  final String? meaning;
  final String? transliteration;
  final String language;

  factory MantraLocalizationModel.fromJson(Map<String, dynamic> json) {
    return MantraLocalizationModel(
      id: (json['id'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
      meaning: json['meaning'] as String?,
      transliteration: json['transliteration'] as String?,
      language: (json['language'] as String?) ?? '',
    );
  }

  MantraLocalization toEntity() => MantraLocalization(
        id: id,
        text: text,
        meaning: meaning,
        transliteration: transliteration,
        language: language,
      );
}

/// Maps `MantraDTO` (`GET /mantra`).
class MantraContentModel {
  const MantraContentModel({
    required this.id,
    this.audioUrl,
    this.metadata = const [],
  });

  final String id;
  final String? audioUrl;
  final List<MantraLocalizationModel> metadata;

  factory MantraContentModel.fromJson(Map<String, dynamic> json) {
    final meta = (json['metadata'] as List<dynamic>?) ?? [];
    return MantraContentModel(
      id: (json['id'] as String?) ?? '',
      audioUrl: json['audio_url'] as String?,
      metadata: meta
          .map((e) => MantraLocalizationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  MantraContent toEntity() => MantraContent(
        id: id,
        audioUrl: audioUrl,
        localizations: metadata.map((m) => m.toEntity()).toList(),
      );
}

/// Wrapper for `MantraResponse` (`{ mantras: [...] }`).
class MantraResponseModel {
  const MantraResponseModel({required this.mantras});

  final List<MantraContentModel> mantras;

  factory MantraResponseModel.fromJson(Map<String, dynamic> json) {
    final list = (json['mantras'] as List<dynamic>?) ?? [];
    return MantraResponseModel(
      mantras: list
          .map((e) => MantraContentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
