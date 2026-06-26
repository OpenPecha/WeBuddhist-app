import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

/// Models for `GET /users/me/bookmarks`.
///
/// The endpoint returns a flat (un-paginated) list of [BookmarkDTO]. Each row
/// embeds the rich object for its type (`plan` / `series` / `accumulator` /
/// `timer`), so cards can show real artwork and dates rather than placeholders.

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

  /// Cover art for PLAN / SERIES bookmarks (`plan.image` / `series.image`).
  final ResponsiveImage? image;

  /// Bead art for ACCUMULATOR bookmarks (`accumulator.mala_image_url`).
  final String? malaImageUrl;

  /// Schedule window for PLAN / SERIES bookmarks (drives the date-range label).
  final DateTime? startDate;
  final DateTime? endDate;

  // Nested titles, preferred over [name] when present.
  final String? planTitle;
  final String? seriesTitle;
  final String? timerName;

  /// Duration (ms) and audio for TIMER bookmarks — enough to open the timer.
  final int? timerDurationMs;
  final String? timerAudioUrl;

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
    this.image,
    this.malaImageUrl,
    this.startDate,
    this.endDate,
    this.planTitle,
    this.seriesTitle,
    this.timerName,
    this.timerDurationMs,
    this.timerAudioUrl,
  });

  /// Lenient parser: returns `null` when the payload is missing required fields
  /// or carries a type this build doesn't understand, so one bad row can't
  /// break the whole list.
  static BookmarkDTO? tryFromJson(Map<String, dynamic> json) {
    final type = BookmarkItemType.tryFromJson(json['type'] as String?);
    final id = json['id'] as String?;
    final sourceId = json['source_id'] as String?;
    final createdAt = _parseDate(json['created_at']);
    if (type == null || id == null || sourceId == null || createdAt == null) {
      return null;
    }

    final plan = json['plan'] as Map<String, dynamic>?;
    final series = json['series'] as Map<String, dynamic>?;
    final accumulator = json['accumulator'] as Map<String, dynamic>?;
    final timer = json['timer'] as Map<String, dynamic>?;

    DateTime? startDate;
    DateTime? endDate;
    if (plan != null) {
      startDate = _parseDate(plan['start_date']);
      endDate = _endFromDuration(startDate, plan['total_days']);
    } else if (series != null) {
      startDate = _parseDate(series['start_date']);
      endDate =
          _parseDate(series['end_date']) ??
          _endFromDuration(startDate, series['total_days']);
    }

    return BookmarkDTO(
      id: id,
      type: type,
      sourceId: sourceId,
      name: json['name'] as String?,
      createdAt: createdAt,
      updatedAt: _parseDate(json['updated_at']) ?? createdAt,
      textId: json['text_id'] as String?,
      textTitle: json['text_title'] as String?,
      segmentId: json['segment_id'] as String?,
      verseId: json['verse_id'] as String?,
      segmentContent: json['segment_content'] as String?,
      image: _responsiveImage(plan?['image']) ?? _responsiveImage(series?['image']),
      malaImageUrl: accumulator?['mala_image_url'] as String?,
      startDate: startDate,
      endDate: endDate,
      planTitle: plan?['title'] as String?,
      seriesTitle: _seriesTitle(series),
      timerName: timer?['name'] as String?,
      timerDurationMs: (timer?['duration'] as num?)?.toInt(),
      timerAudioUrl: timer?['audio_url'] as String?,
    );
  }

  bool get isText =>
      type == BookmarkItemType.text || type == BookmarkItemType.verse;

  /// Title shown on the card, preferring the nested object's title and falling
  /// back to [name], then a type label.
  String get displayTitle {
    final preferred =
        isText
            ? (textTitle ?? name)
            : (name ?? planTitle ?? timerName ?? seriesTitle);
    if (preferred != null && preferred.trim().isNotEmpty) {
      return preferred.trim();
    }
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

  /// Leading artwork, if any. Accumulators render as a round bead; plans and
  /// series render as a rounded square.
  ResponsiveImage? get leadingImage {
    if (type == BookmarkItemType.accumulator) {
      final url = malaImageUrl;
      return (url != null && url.isNotEmpty)
          ? ResponsiveImage.uniform(url)
          : null;
    }
    return image;
  }

  bool get isRoundLeading => type == BookmarkItemType.accumulator;

  // ─── Parse helpers ───

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static DateTime? _endFromDuration(DateTime? start, Object? totalDays) {
    final days = (totalDays as num?)?.toInt();
    if (start == null || days == null || days <= 0) return null;
    return start.add(Duration(days: days - 1));
  }

  static ResponsiveImage? _responsiveImage(Object? obj) {
    if (obj is! Map) return null;
    final t = obj['thumbnail'] as String?;
    final m = obj['medium'] as String?;
    final o = obj['original'] as String?;
    bool blank(String? s) => s == null || s.isEmpty;
    if (blank(t) && blank(m) && blank(o)) return null;
    return ResponsiveImage(thumbnail: t, medium: m, original: o);
  }

  static String? _seriesTitle(Map<String, dynamic>? series) {
    final meta = series?['metadata'];
    if (meta is Map) return meta['title'] as String?;
    if (meta is List && meta.isNotEmpty && meta.first is Map) {
      return (meta.first as Map)['title'] as String?;
    }
    return null;
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
