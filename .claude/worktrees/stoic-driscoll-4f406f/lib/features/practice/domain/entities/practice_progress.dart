import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';
import 'routine.dart';

/// Practice progress tracking entity.
class PracticeProgress extends BaseEntity {
  final String userId;
  final Map<RoutineType, int> weeklyGoalMinutes;
  final Map<RoutineType, int> currentWeekMinutes;
  final List<Routine> activeRoutines;
  final int totalSessionsThisWeek;
  final int totalSessionsThisMonth;
  final DateTime lastPracticeDate;

  const PracticeProgress({
    required this.userId,
    required this.weeklyGoalMinutes,
    required this.currentWeekMinutes,
    required this.activeRoutines,
    this.totalSessionsThisWeek = 0,
    this.totalSessionsThisMonth = 0,
    required this.lastPracticeDate,
  });

  /// Calculate overall progress percentage.
  double get overallProgress {
    if (weeklyGoalMinutes.isEmpty) return 0.0;
    int totalGoal = weeklyGoalMinutes.values.fold(0, (a, b) => a + b);
    int totalCurrent = currentWeekMinutes.values.fold(0, (a, b) => a + b);
    if (totalGoal == 0) return 0.0;
    return totalCurrent / totalGoal;
  }

  @override
  List<Object?> get props => [
    userId,
    weeklyGoalMinutes,
    currentWeekMinutes,
    activeRoutines,
    totalSessionsThisWeek,
    totalSessionsThisMonth,
    lastPracticeDate,
  ];
}
