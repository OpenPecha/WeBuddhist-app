class PlanSubtasksModel {
  final String id;
  final String? label;
  final String contentType;
  final String? content; // Made nullable as per schema
  final int? displayOrder;
  final String? duration;
  final String? sourceTextId;
  final String? pechaSegmentId;

  PlanSubtasksModel({
    required this.id,
    this.label,
    required this.contentType,
    this.content,
    this.displayOrder,
    this.duration,
    this.sourceTextId,
    this.pechaSegmentId,
  });

  factory PlanSubtasksModel.fromJson(Map<String, dynamic> json) {
    return PlanSubtasksModel(
      id: json['id'] as String,
      label: json['label'] as String?,
      contentType: json['content_type'] as String,
      content: json['content'] as String?,
      displayOrder: json['display_order'] as int?,
      duration: json['duration'] as String?,
      sourceTextId: json['source_text_id'] as String?,
      pechaSegmentId: json['pecha_segment_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'content_type': contentType,
      'content': content,
      'display_order': displayOrder,
      'duration': duration,
      'source_text_id': sourceTextId,
      'pecha_segment_id': pechaSegmentId,
    };
  }

  /// Create a copy of this plan subtask with optional field updates
  PlanSubtasksModel copyWith({
    String? id,
    String? label,
    String? contentType,
    String? content,
    int? displayOrder,
    String? duration,
    String? sourceTextId,
    String? pechaSegmentId,
  }) {
    return PlanSubtasksModel(
      id: id ?? this.id,
      label: label ?? this.label,
      contentType: contentType ?? this.contentType,
      content: content ?? this.content,
      displayOrder: displayOrder ?? this.displayOrder,
      duration: duration ?? this.duration,
      sourceTextId: sourceTextId ?? this.sourceTextId,
      pechaSegmentId: pechaSegmentId ?? this.pechaSegmentId,
    );
  }
}
