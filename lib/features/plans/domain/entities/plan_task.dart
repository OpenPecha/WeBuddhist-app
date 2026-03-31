import 'package:equatable/equatable.dart';

/// Plan task entity representing a single task within a day.
class PlanTask extends Equatable {
  final String id;
  final String title;
  final String? description;
  final TaskType type;
  final int durationMinutes;
  final String? contentId; // ID of text/recitation to practice
  final int order;

  const PlanTask({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.durationMinutes = 10,
    this.contentId,
    this.order = 0,
  });

  @override
  List<Object?> get props => [id, title, description, type, durationMinutes, contentId, order];
}

/// Type of task.
enum TaskType {
  reading,
  recitation,
  meditation,
  reflection,
  chanting,
}
