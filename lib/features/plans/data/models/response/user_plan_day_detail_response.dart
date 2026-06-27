import 'package:flutter_pecha/features/plans/data/models/plan_video_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';

class UserPlanDayDetailResponse {
  final String id;
  final int dayNumber;
  final List<UserTasksDto> tasks;
  final bool isCompleted;
  final String? audioUrl;
  final int? audioDurationMs;
  final List<PlanVideoModel> videos;

  UserPlanDayDetailResponse({
    required this.id,
    required this.dayNumber,
    required this.tasks,
    required this.isCompleted,
    this.audioUrl,
    this.audioDurationMs,
    this.videos = const [],
  });

  factory UserPlanDayDetailResponse.fromJson(Map<String, dynamic> json) {
    return UserPlanDayDetailResponse(
      id: json['id'] as String,
      dayNumber: json['day_number'] as int,
      tasks:
          (json['tasks'] as List<dynamic>)
              .map(
                (task) => UserTasksDto.fromJson(task as Map<String, dynamic>),
              )
              .toList(),
      isCompleted: json['is_completed'] as bool,
      audioUrl: json['audio_url'] as String?,
      audioDurationMs: json['audio_duration_ms'] as int?,
      videos:
          json['videos'] != null
              ? (json['videos'] as List<dynamic>)
                  .map(
                    (e) => PlanVideoModel.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
              : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_number': dayNumber,
      'tasks': tasks.map((e) => e.toJson()).toList(),
      'is_completed': isCompleted,
      'audio_url': audioUrl,
      'audio_duration_ms': audioDurationMs,
      'videos': videos.map((e) => e.toJson()).toList(),
    };
  }
}
