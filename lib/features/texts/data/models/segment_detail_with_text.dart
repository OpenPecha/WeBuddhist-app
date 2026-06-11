class SegmentDetailWithText {
  final String id;
  final String content;
  final String textTitle;

  const SegmentDetailWithText({
    required this.id,
    required this.content,
    required this.textTitle,
  });

  factory SegmentDetailWithText.fromJson(Map<String, dynamic> json) {
    final textJson = json['text'] as Map<String, dynamic>?;
    return SegmentDetailWithText(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      textTitle: textJson?['title'] as String? ?? '',
    );
  }
}
