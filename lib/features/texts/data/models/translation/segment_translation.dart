class SegmentTranslation {
  final String segmentId;
  final String textId;
  final String title;
  final String source;
  final String language;
  final String content;
  final String? license;

  SegmentTranslation({
    required this.segmentId,
    required this.textId,
    required this.title,
    required this.source,
    required this.language,
    required this.content,
    this.license,
  });

  factory SegmentTranslation.fromJson(Map<String, dynamic> json) {
    return SegmentTranslation(
      segmentId: json['segment_id'] as String? ?? '',
      textId: json['text_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      source: json['source'] as String? ?? '',
      language: json['language'] as String? ?? '',
      content: json['content'] as String? ?? '',
      license: json['license'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'segment_id': segmentId,
      'text_id': textId,
      'title': title,
      'source': source,
      'language': language,
      'content': content,
      'license': license,
    };
  }
}
