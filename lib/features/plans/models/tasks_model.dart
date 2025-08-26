enum ContentType { text, audio, video, image, sourceReference }

class TasksModel {
  final String id;
  final String planItemId;
  final String title;
  final ContentType contentTye;
  final String content;
  final int displayOrder;
  final DateTime? estimatedTime;
  final bool isRequired;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TasksModel({
    required this.id,
    required this.planItemId,
    required this.title,
    required this.contentTye,
    required this.content,
    required this.displayOrder,
    this.estimatedTime,
    this.isRequired = true,
    this.createdAt,
    this.updatedAt,
  });

  factory TasksModel.fromJson(Map<String, dynamic> json) {
    return TasksModel(
      id: json['id'],
      planItemId: json['plan_item_id'],
      title: json['title'],
      contentTye: ContentType.values.byName(json['content_type']),
      content: json['content'],
      displayOrder: json['display_order'],
      estimatedTime: json['estimated_time'],
      isRequired: json['is_required'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_item_id': planItemId,
      'title': title,
      'content_type': contentTye.name,
      'content': content,
      'display_order': displayOrder,
      'estimated_time': estimatedTime,
      'is_required': isRequired,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
