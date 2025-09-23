import 'package:flutter_pecha/features/plans/models/plan_subtasks_model.dart';

class PlanTasksModel {
  final String id;
  final String title;
  final int? estimatedTime;
  final List<PlanSubtasksModel> subtasks;

  PlanTasksModel({
    required this.id,
    required this.title,
    this.estimatedTime,
    required this.subtasks,
  });

  factory PlanTasksModel.fromJson(Map<String, dynamic> json) {
    return PlanTasksModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtasks:
          (json['subtasks'] as List<dynamic>)
              .map((e) => PlanSubtasksModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      estimatedTime: json['estimated_time'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtasks': subtasks.map((e) => e.toJson()).toList(),
      'estimated_time': estimatedTime,
    };
  }

  /// Create a copy of this plan task with optional field updates
  PlanTasksModel copyWith({
    String? id,
    String? title,
    List<PlanSubtasksModel>? subtasks,
    int? estimatedTime,
  }) {
    return PlanTasksModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtasks: subtasks ?? this.subtasks,
      estimatedTime: estimatedTime ?? this.estimatedTime,
    );
  }

  /// Get task display title with fallback
  String get displayTitle => title;

  /// Check if task has content
  bool get hasContent => subtasks.isNotEmpty;

  /// Check if task has title
  bool get hasTitle => title.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanTasksModel &&
        other.id == id &&
        other.subtasks == subtasks;
  }

  @override
  int get hashCode => Object.hash(id, subtasks);

  @override
  String toString() {
    return 'PlanTasksModel(id: $id, title: $displayTitle, subtasks: $subtasks)';
  }
}
