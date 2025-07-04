class SegmentCommentary {
  final String segmentId;
  final String textId;
  final String title;
  final String source;
  final String language;
  final String content;

  SegmentCommentary({
    required this.segmentId,
    required this.textId,
    required this.title,
    required this.source,
    required this.language,
    required this.content,
  });

  factory SegmentCommentary.fromJson(Map<String, dynamic> json) {
    return SegmentCommentary(
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
