class PlanUtils {
  static int calculateSelectedDay(DateTime startedAt, int totalDays) {
    final today = DateTime.now();
    final localStartedAt = startedAt.toLocal();

    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedStartedAt = DateTime(
      localStartedAt.year,
      localStartedAt.month,
      localStartedAt.day,
    );

    if (normalizedToday.isAtSameMomentAs(normalizedStartedAt)) {
      return 1;
    } else if (normalizedToday.isAfter(normalizedStartedAt)) {
      final difference =
          normalizedToday.difference(normalizedStartedAt).inDays + 1;
      if (difference > totalDays) {
        return totalDays;
      } else {
        return difference;
      }
    }

    return 1;
  }

  /// Counts past scheduled days (before today) that the user has not completed.
  /// Excludes today — the user still has time to finish it.
  static int calculateMissedDays(
    DateTime startedAt,
    int totalDays,
    Map<int, bool> completionStatus,
  ) {
    final todayDayNumber = calculateSelectedDay(startedAt, totalDays);
    int missedCount = 0;
    for (int day = 1; day < todayDayNumber; day++) {
      if (completionStatus[day] != true) {
        missedCount++;
      }
    }
    return missedCount;
  }
}
