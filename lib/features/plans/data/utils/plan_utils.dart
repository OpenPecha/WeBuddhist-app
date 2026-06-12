import 'package:flutter_pecha/core/utils/app_logger.dart';

final _logger = AppLogger('PlanUtils');

class PlanUtils {
  /// Parses a backend calendar-date string (e.g. `2026-05-14T00:00:00.000Z`)
  /// into a local-midnight DateTime preserving the calendar day.
  ///
  /// Backend sends plan start dates as UTC midnight, but these represent
  /// **calendar dates**, not instants. A naive `.toLocal()` shifts the day
  /// in negative-offset zones (e.g. May 14 UTC midnight → May 13 20:00 in
  /// Toronto), producing off-by-one day-N calculations. This helper extracts
  /// the UTC year/month/day and rebuilds at local midnight so the calendar
  /// day is preserved everywhere downstream.
  static DateTime? parseCalendarDate(String? iso) {
    if (iso == null) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) {
      _logger.warning('[CAL-DATE] failed to parse: $iso');
      return null;
    }
    final utc = parsed.toUtc();
    final normalized = DateTime(utc.year, utc.month, utc.day);
    _logger.info(
      '[CAL-DATE] raw=$iso utc=${utc.toIso8601String()} '
      'localMidnight=${normalized.toIso8601String()}',
    );
    return normalized;
  }

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

  /// Returns the plan day-number (1-based) for [forDate], using
  /// [planStartDate] as the anchor for Day 1. Clamped to `[1, totalDays]`.
  /// Returns 0 if [forDate] is before the plan started.
  static int dayNumberFor(
    DateTime planStartDate,
    DateTime forDate,
    int totalDays,
  ) {
    final start = planStartDate.toLocal();
    final target = forDate.toLocal();
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedTarget = DateTime(target.year, target.month, target.day);
    if (normalizedTarget.isBefore(normalizedStart)) return 0;
    final diff = normalizedTarget.difference(normalizedStart).inDays + 1;
    if (diff > totalDays) return totalDays;
    return diff;
  }

  /// Counts past scheduled days (from Day 1) the user has not completed.
  ///
  /// Always counts from Day 1 regardless of when the user enrolled, so late
  /// joiners see the full backlog they need to catch up on. Excludes today —
  /// the user still has time to finish it.
  ///
  /// [planStartDate]: Day 1 anchor (= `plan.startDate ?? plan.startedAt`).
  static int calculateMissedDays(
    DateTime planStartDate,
    int totalDays,
    Map<int, bool> completionStatus,
  ) {
    final todayDayNumber = dayNumberFor(planStartDate, DateTime.now(), totalDays);

    int missedCount = 0;
    for (int day = 1; day < todayDayNumber; day++) {
      if (completionStatus[day] != true) missedCount++;
    }

    _logger.info(
      '[ENROLL-MISSED] planStart=${planStartDate.toIso8601String()} '
      'todayDay=$todayDayNumber missed=$missedCount',
    );
    return missedCount;
  }
}
