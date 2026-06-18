class FeaturedDayResponse {
  final String id;
  final int dayNumber;
  final List<FeaturedDayTask> tasks;

  FeaturedDayResponse({
    required this.id,
    required this.dayNumber,
    required this.tasks,
  });

  factory FeaturedDayResponse.fromJson(Map<String, dynamic> json) {
    return FeaturedDayResponse(
      id: json['id'] as String,
      dayNumber: json['day_number'] as int,
      tasks:
          (json['tasks'] as List<dynamic>)
              .map(
                (task) =>
                    FeaturedDayTask.fromJson(task as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_number': dayNumber,
      'tasks': tasks.map((e) => e.toJson()).toList(),
    };
  }
}

class FeaturedDayTask {
  final String id;
  final String title;
  final int? estimatedTime;
  final int displayOrder;
  final List<FeaturedDaySubtask> subtasks;

  FeaturedDayTask({
    required this.id,
    required this.title,
    this.estimatedTime,
    required this.displayOrder,
    required this.subtasks,
  });

  factory FeaturedDayTask.fromJson(Map<String, dynamic> json) {
    return FeaturedDayTask(
      id: json['id'] as String,
      title: json['title'] as String,
      estimatedTime: json['estimated_time'] as int?,
      displayOrder: json['display_order'] as int,
      subtasks:
          (json['subtasks'] as List<dynamic>)
              .map(
                (subtask) => FeaturedDaySubtask.fromJson(
                  subtask as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'estimated_time': estimatedTime,
      'display_order': displayOrder,
      'subtasks': subtasks.map((e) => e.toJson()).toList(),
    };
  }
}

class FeaturedDaySubtask {
  final String id;
  final String contentType;
  final String content;
  final int? displayOrder;

  FeaturedDaySubtask({
    required this.id,
    required this.contentType,
    required this.content,
    this.displayOrder,
  });

  factory FeaturedDaySubtask.fromJson(Map<String, dynamic> json) {
    return FeaturedDaySubtask(
      id: json['id'] as String,
      contentType: json['content_type'] as String,
      content: json['content'] as String,
      displayOrder: json['display_order'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_type': contentType,
      'content': content,
      'display_order': displayOrder,
    };
  }
}
