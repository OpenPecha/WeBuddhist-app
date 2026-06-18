import 'package:equatable/equatable.dart';

class StreakStats extends Equatable {
  final int current;
  final int highest;
  final List<int> week;

  const StreakStats({
    required this.current,
    required this.highest,
    required this.week,
  });

  @override
  List<Object?> get props => [current, highest, week];
}

class UserStats extends Equatable {
  final StreakStats streak;
  final int totalTimerSeconds;
  final int totalAccumulated;
  final int totalPracticeDays;

  const UserStats({
    required this.streak,
    required this.totalTimerSeconds,
    required this.totalAccumulated,
    required this.totalPracticeDays,
  });

  static const empty = UserStats(
    streak: StreakStats(current: 0, highest: 0, week: []),
    totalTimerSeconds: 0,
    totalAccumulated: 0,
    totalPracticeDays: 0,
  );

  @override
  List<Object?> get props => [
    streak,
    totalTimerSeconds,
    totalAccumulated,
    totalPracticeDays,
  ];
}
