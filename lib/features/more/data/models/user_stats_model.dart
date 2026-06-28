import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';

class UserStatsModel {
  final StreakStatsModel streak;
  final int totalTimer;
  final int totalAccumulated;
  final int totalPracticeDays;

  const UserStatsModel({
    required this.streak,
    required this.totalTimer,
    required this.totalAccumulated,
    required this.totalPracticeDays,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      streak: StreakStatsModel.fromJson(
        json['streak'] as Map<String, dynamic>? ?? const {},
      ),
      totalTimer: (json['total_timer'] as num?)?.toInt() ?? 0,
      totalAccumulated: (json['total_accumulated'] as num?)?.toInt() ?? 0,
      totalPracticeDays: (json['total_practice_days'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streak': streak.toJson(),
      'total_timer': totalTimer,
      'total_accumulated': totalAccumulated,
      'total_practice_days': totalPracticeDays,
    };
  }

  UserStats toEntity() {
    return UserStats(
      streak: streak.toEntity(),
      totalTimer: totalTimer,
      totalAccumulated: totalAccumulated,
      totalPracticeDays: totalPracticeDays,
    );
  }
}

class StreakStatsModel {
  final int current;
  final int highest;
  final List<int> week;

  const StreakStatsModel({
    required this.current,
    required this.highest,
    required this.week,
  });

  factory StreakStatsModel.fromJson(Map<String, dynamic> json) {
    return StreakStatsModel(
      current: (json['current'] as num?)?.toInt() ?? 0,
      highest: (json['highest'] as num?)?.toInt() ?? 0,
      week:
          (json['week'] as List<dynamic>?)
              ?.map((day) => (day as num).toInt())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'current': current, 'highest': highest, 'week': week};
  }

  StreakStats toEntity() {
    return StreakStats(current: current, highest: highest, week: week);
  }
}
