import 'package:flutter_pecha/features/plans/models/plan_tasks_model.dart';

enum ContentType { text, audio, video, image, sourceReference }

class PlanSubtasksModel {
  final String id;
  final ContentType contentType;
  final String? content; // Made nullable as per schema
  final int? displayOrder;

  PlanSubtasksModel({
    required this.id,
    required this.contentType,
    this.content,
    this.displayOrder,
  });

  factory PlanSubtasksModel.fromJson(Map<String, dynamic> json) {
    return PlanSubtasksModel(
      id: json['id'] as String,
      contentType: ContentType.values.byName(
        (json['content_type'] as String).toLowerCase(),
      ),
      content: json['content'] as String?,
      displayOrder: json['display_order'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_type': contentType.name,
      'content': content,
      'display_order': displayOrder,
    };
  }

  /// Create a copy of this plan subtask with optional field updates
  PlanSubtasksModel copyWith({
    String? id,
    ContentType? contentType,
    String? content,
    int? displayOrder,
  }) {
    return PlanSubtasksModel(
      id: id ?? this.id,
      contentType: contentType ?? this.contentType,
      content: content ?? this.content,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
