import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';

class PlanDaysModel {
  final String id;
  final int dayNumber;
  final String? title;
  final List<PlanTasksModel>? tasks;
  final String? audioUrl;
  final int? audioDurationMs;

  PlanDaysModel({
    required this.id,
    required this.dayNumber,
    this.title,
    this.tasks,
    this.audioUrl,
    this.audioDurationMs,
  });

  bool get hasAudio => audioUrl != null;

  factory PlanDaysModel.fromJson(Map<String, dynamic> json) {
    return PlanDaysModel(
      id: json['id'] as String,
      dayNumber: json['day_number'] as int,
      title: json['title'] as String?,
      tasks: json['tasks'] != null
          ? (json['tasks'] as List<dynamic>)
              .map((e) => PlanTasksModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      audioUrl: json['audio_url'] as String?,
      audioDurationMs: json['audio_duration_ms'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_number': dayNumber,
      'title': title,
      'tasks': tasks?.map((e) => e.toJson()).toList(),
      'audio_url': audioUrl,
      'audio_duration_ms': audioDurationMs,
    };
  }

  PlanDaysModel copyWith({
    String? id,
    int? dayNumber,
    String? title,
    List<PlanTasksModel>? tasks,
    String? audioUrl,
    int? audioDurationMs,
  }) {
    return PlanDaysModel(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      tasks: tasks ?? this.tasks,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDurationMs: audioDurationMs ?? this.audioDurationMs,
    );
  }

  bool get isDeleted => false;
  bool get isActive => !isDeleted;
  String get dayLabel => 'Day $dayNumber';
  bool get isFirstDay => dayNumber == 1;
  bool get isValidDayNumber => dayNumber > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanDaysModel &&
        other.id == id &&
        other.dayNumber == dayNumber;
  }

  @override
  int get hashCode => Object.hash(id, dayNumber);

  @override
  String toString() =>
      'PlanDaysModel(id: $id, dayNumber: $dayNumber, hasAudio: $hasAudio)';
}
