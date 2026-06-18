import 'dart:convert';

import 'package:flutter_pecha/features/meditation_of_day/domain/entities/meditation.dart';

/// Meditation data model with JSON serialization.
class MeditationModel {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String imageUrl;
  final int durationMinutes;
  final DateTime date;
  final bool isCompleted;

  const MeditationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.imageUrl,
    required this.durationMinutes,
    required this.date,
    this.isCompleted = false,
  });

  /// Convert Meditation entity to MeditationModel.
  static MeditationModel fromEntity(Meditation entity) {
    return MeditationModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      audioUrl: entity.audioUrl,
      imageUrl: entity.imageUrl,
      durationMinutes: entity.durationMinutes,
      date: entity.date,
      isCompleted: entity.isCompleted,
    );
  }

  /// Convert MeditationModel to Meditation entity.
  Meditation toEntity() {
    return Meditation(
      id: id,
      title: title,
      description: description,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      durationMinutes: durationMinutes,
      date: date,
      isCompleted: isCompleted,
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
        'durationMinutes': durationMinutes,
        'date': date.toIso8601String(),
        'isCompleted': isCompleted,
      };

  /// Deserialize from JSON.
  factory MeditationModel.fromJson(Map<String, dynamic> json) {
    return MeditationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      audioUrl: json['audioUrl'] as String,
      imageUrl: json['imageUrl'] as String,
      durationMinutes: json['durationMinutes'] as int? ?? 10,
      date: DateTime.parse(json['date'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string.
  factory MeditationModel.fromJsonString(String jsonString) {
    return MeditationModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
