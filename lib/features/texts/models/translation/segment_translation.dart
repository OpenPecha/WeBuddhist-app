class SegmentTranslation {
  final String segmentId;
  final String textId;
  final String title;
  final String source;
  final String language;
  final String content;

  SegmentTranslation({
    required this.segmentId,
    required this.textId,
    required this.title,
    required this.source,
    required this.language,
    required this.content,
  });

  factory SegmentTranslation.fromJson(Map<String, dynamic> json) {
    return SegmentTranslation(
      segmentId: json['segment_id'],
      textId: json['text_id'],
      title: json['title'],
      source: json['source'],
      language: json['language'],
      content: json['content'],
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
    };
  }
}
