import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';

class PresetTimerModel {
  const PresetTimerModel({
    required this.id,
    required this.name,
    required this.durationMs,
    this.audioUrl,
  });

  final String id;
  final String name;
  final int durationMs;
  final String? audioUrl;

  factory PresetTimerModel.fromJson(Map<String, dynamic> json) {
    return PresetTimerModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      durationMs: (json['duration'] as num?)?.toInt() ?? 0,
      audioUrl: json['audio_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'duration': durationMs,
    if (audioUrl != null) 'audio_url': audioUrl,
  };

  PresetTimer toEntity() {
    return PresetTimer(
      id: id,
      name: name,
      durationMs: durationMs,
      audioUrl: audioUrl,
    );
  }
}

class TimersResponseModel {
  const TimersResponseModel({required this.timers, required this.total});

  final List<PresetTimerModel> timers;
  final int total;

  factory TimersResponseModel.fromJson(Map<String, dynamic> json) {
    final timersJson = (json['timers'] as List<dynamic>?) ?? [];
    return TimersResponseModel(
      timers:
          timersJson
              .map((t) => PresetTimerModel.fromJson(t as Map<String, dynamic>))
              .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}
