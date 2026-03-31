import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan_task.dart';

/// Plan day entity representing a single day's practice.
class PlanDay extends Equatable {
  final int dayNumber;
  final String title;
  final String? description;
  final List<PlanTask> tasks;
  final int durationMinutes;
  final bool isRestDay;

  const PlanDay({
    required this.dayNumber,
    required this.title,
    this.description,
    this.tasks = const [],
    this.durationMinutes = 30,
    this.isRestDay = false,
  });

  /// Get total completion time for all tasks.
  int get totalTaskDuration {
    return tasks.fold(0, (sum, task) => sum + task.durationMinutes);
  }

  @override
  List<Object?> get props => [dayNumber, title, description, tasks, durationMinutes, isRestDay];
}
