import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Text content entity for the Reader feature.
///
/// Represents a text that can be read with its sections and metadata.
class TextContent extends BaseEntity {
  final String id;
  final String title;
  final String? titleTibetan;
  final String? author;
  final String? language;
  final int totalSections;
  final List<Section> sections;

  const TextContent({
    required this.id,
    required this.title,
    this.titleTibetan,
    this.author,
    this.language,
    this.totalSections = 0,
    this.sections = const [],
  });

  /// Get the display title based on language preference
  String getDisplayTitle(bool preferTibetan) {
    if (preferTibetan && titleTibetan != null && titleTibetan!.isNotEmpty) {
      return titleTibetan!;
    }
    return title;
  }

  @override
  List<Object?> get props => [id, title, titleTibetan, author, language, totalSections, sections];
}

/// Section entity representing a division of text content.
class Section extends BaseEntity {
  final String id;
  final int sectionNumber;
  final String title;
  final int startPage;
  final int endPage;
  final List<Verse> verses;

  const Section({
    required this.id,
    required this.sectionNumber,
    required this.title,
    required this.startPage,
    required this.endPage,
    this.verses = const [],
  });

  @override
  List<Object?> get props => [id, sectionNumber, title, startPage, endPage, verses];
}

/// Verse entity representing a single verse or segment.
class Verse extends BaseEntity {
  final String id;
  final int verseNumber;
  final String content;
  final String? contentTibetan;
  final String? sanskrit;
  final String? audioUrl;

  const Verse({
    required this.id,
    required this.verseNumber,
    required this.content,
    this.contentTibetan,
    this.sanskrit,
    this.audioUrl,
  });

  @override
  List<Object?> get props => [id, verseNumber, content, contentTibetan, sanskrit, audioUrl];
}
