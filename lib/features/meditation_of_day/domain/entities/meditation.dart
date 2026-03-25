import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Meditation entity for meditation of the day feature.
class Meditation extends BaseEntity {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String imageUrl;
  final int durationMinutes;
  final DateTime date;
  final bool isCompleted;

  const Meditation({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.imageUrl,
    required this.durationMinutes,
    required this.date,
    this.isCompleted = false,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        audioUrl,
        imageUrl,
        durationMinutes,
        date,
        isCompleted,
      ];

  Meditation copyWith({
    String? id,
    String? title,
    String? description,
    String? audioUrl,
    String? imageUrl,
    int? durationMinutes,
    DateTime? date,
    bool? isCompleted,
  }) {
    return Meditation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
