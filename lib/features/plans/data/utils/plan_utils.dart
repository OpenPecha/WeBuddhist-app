/// Utility functions for plan-related calculations
class PlanUtils {
  /// Calculates the selected day based on when the plan started and total days.
  ///
  /// [startedAt] - The date when the plan was started
  /// [totalDays] - Total number of days in the plan
  ///
  /// Returns the current day number (1-indexed) that should be selected.
  /// Returns 1 if today equals startedAt, or if startedAt is in the future.
  /// Returns totalDays if the plan duration has been exceeded.
  static int calculateSelectedDay(DateTime startedAt, int totalDays) {
    final today = DateTime.now();

    // startedAt will never be before today
    if (today == startedAt) {
      return 1;
    } else if (today.isAfter(startedAt)) {
      final difference = today.difference(startedAt).inDays + 1;
      if (difference >= totalDays) {
        return totalDays;
      } else {
        return difference;
      }
    }
    return 1;
  }
}
