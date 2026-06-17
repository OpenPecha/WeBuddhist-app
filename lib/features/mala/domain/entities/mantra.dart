import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra_content.dart';

/// Standard beads in one mala round. Not exposed by the API, so it is fixed
/// here. (`target_count` on the accumulator is a separate lifetime goal.)
const int kBeadsPerRound = 108;

/// A mantra the user can accumulate — a **preset accumulator**
/// (`GET /accumulators`) joined with its localized [content] (`GET /mantra`).
///
/// [presetId] is the preset accumulator's id; it is used as the local
/// namespacing key and as the source for lazily creating the user's own
/// accumulator on first tap. The user-owned accumulator id (needed for
/// PUT/DELETE) is tracked separately in the local store, not here.
class Mantra extends Equatable {
  final String presetId;
  final String name;
  final String? description;
  final String? mantraId;
  final int? targetCount;

  /// Bead artwork URL. The backend will add this to `GET /accumulators`;
  /// null-safe until then (UI falls back to a drawn bead).
  final String? beadImageUrl;

  /// Localized mantra text, joined by [mantraId]. Null if no match.
  final MantraContent? content;

  const Mantra({
    required this.presetId,
    required this.name,
    this.description,
    this.mantraId,
    this.targetCount,
    this.beadImageUrl,
    this.content,
  });

  int get beadsPerRound => kBeadsPerRound;

  /// Large Tibetan script for the mantra, if available.
  String? get tibetan => content?.tibetan?.text;

  /// Transliteration in [language] (falls back to English, then anything).
  String? transliteration(String language) =>
      content?.localized(language)?.transliteration;

  /// Meaning in [language] (falls back to English, then anything).
  String? meaning(String language) => content?.localized(language)?.meaning;

  Mantra copyWith({MantraContent? content}) => Mantra(
        presetId: presetId,
        name: name,
        description: description,
        mantraId: mantraId,
        targetCount: targetCount,
        beadImageUrl: beadImageUrl,
        content: content ?? this.content,
      );

  @override
  List<Object?> get props =>
      [presetId, name, description, mantraId, targetCount, beadImageUrl, content];
}
