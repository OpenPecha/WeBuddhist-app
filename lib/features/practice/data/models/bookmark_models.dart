/// Models for `GET /users/me/bookmarks`.
///
/// The endpoint returns a flat (un-paginated) list of [BookmarkDTO]. The DTO
/// carries no image/cover, timer duration, or plan date-range — only [name]
/// (or [textTitle]) plus a [segmentContent] excerpt for verses — so cards are
/// rendered with a type-based icon rather than remote artwork.
library;

/// Every bookmark kind the API can return.
///
/// Note the create endpoint ([BookmarkType]) only supports a subset; this
/// fuller enum is used purely for decoding the list response.
enum BookmarkItemType {
  text,
  plan,
  series,
  accumulator,
  timer,
  verse;

  static BookmarkItemType? tryFromJson(String? value) => switch (value) {
    'TEXT' => BookmarkItemType.text,
    'PLAN' => BookmarkItemType.plan,
    'SERIES' => BookmarkItemType.series,
    'ACCUMULATOR' => BookmarkItemType.accumulator,
    'TIMER' => BookmarkItemType.timer,
    'VERSE' => BookmarkItemType.verse,
    _ => null,
  };
}

/// A single saved bookmark.
class BookmarkDTO {
  /// Bookmark id — the key for `DELETE /users/me/bookmarks/{id}`.
  final String id;
  final BookmarkItemType type;

  /// Id of the bookmarked entity (text, plan, series, timer, …).
  final String sourceId;
  final String? name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? textId;
  final String? textTitle;
  final String? segmentId;
  final String? verseId;
  final String? segmentContent;

  const BookmarkDTO({
    required this.id,
    required this.type,
    required this.sourceId,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.textId,
    this.textTitle,
    this.segmentId,
    this.verseId,
    this.segmentContent,
  });

  /// Lenient parser: returns `null` when the payload is missing required fields
  /// or carries a type this build doesn't understand, so one bad row can't
  /// break the whole list. (`num`/`String` casts stay defensive for Flutter
  /// web, where JSON numbers decode as `double`.)
  static BookmarkDTO? tryFromJson(Map<String, dynamic> json) {
    final type = BookmarkItemType.tryFromJson(json['type'] as String?);
    final id = json['id'] as String?;
    final sourceId = json['source_id'] as String?;
    final createdAt = DateTime.tryParse((json['created_at'] as String?) ?? '');
    if (type == null || id == null || sourceId == null || createdAt == null) {
      return null;
    }
    return BookmarkDTO(
      id: id,
      type: type,
      sourceId: sourceId,
      name: json['name'] as String?,
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse((json['updated_at'] as String?) ?? '') ?? createdAt,
      textId: json['text_id'] as String?,
      textTitle: json['text_title'] as String?,
      segmentId: json['segment_id'] as String?,
      verseId: json['verse_id'] as String?,
      segmentContent: json['segment_content'] as String?,
    );
  }

  bool get isText =>
      type == BookmarkItemType.text || type == BookmarkItemType.verse;

  /// Title shown on the card, with a type-appropriate fallback.
  String get displayTitle {
    final raw = isText ? (textTitle ?? name) : name;
    if (raw != null && raw.trim().isNotEmpty) return raw.trim();
    return switch (type) {
      BookmarkItemType.timer => 'Timer',
      BookmarkItemType.text || BookmarkItemType.verse => 'Untitled text',
      BookmarkItemType.plan => 'Plan',
      BookmarkItemType.series => 'Series',
      BookmarkItemType.accumulator => 'Mala',
    };
  }

  /// Secondary excerpt (verse content), if present.
  String? get excerpt {
    final c = segmentContent?.trim();
    return (c != null && c.isNotEmpty) ? c : null;
  }
}

/// Wrapper for the `{ "bookmarks": [...] }` response body.
class BookmarksResponse {
  final List<BookmarkDTO> bookmarks;

  const BookmarksResponse({required this.bookmarks});

  factory BookmarksResponse.fromJson(Map<String, dynamic> json) {
    final raw = (json['bookmarks'] as List<dynamic>?) ?? const [];
    return BookmarksResponse(
      bookmarks:
          raw
              .whereType<Map<String, dynamic>>()
              .map(BookmarkDTO.tryFromJson)
              .whereType<BookmarkDTO>()
              .toList(),
    );
  }
}
