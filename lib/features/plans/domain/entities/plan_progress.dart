import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Plan progress entity tracking user's progress through a plan.
class PlanProgress extends BaseEntity {
  final String planId;
  final String userId;
  final int currentDay;
  final int currentWeek;
  final DateTime startDate;
  final DateTime? lastPracticeDate;
  final List<CompletedTask> completedTasks;
  final bool isEnrolled;
  final double overallProgress; // 0.0 to 1.0

  const PlanProgress({
    required this.planId,
    required this.userId,
    this.currentDay = 1,
    this.currentWeek = 1,
    required this.startDate,
    this.lastPracticeDate,
    this.completedTasks = const [],
    this.isEnrolled = false,
    this.overallProgress = 0.0,
  });

  @override
  List<Object?> get props => [
    planId,
    userId,
    currentDay,
    currentWeek,
    startDate,
    lastPracticeDate,
    completedTasks,
    isEnrolled,
    overallProgress,
  ];
}

/// Represents a completed task in the plan.
class CompletedTask extends Equatable {
  final String taskId;
  final int dayNumber;
  final DateTime completedAt;

  const CompletedTask({
    required this.taskId,
    required this.dayNumber,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [taskId, dayNumber, completedAt];
}
