import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';

/// Fixed English calendar-date labels for plan/series date ranges.
///
/// Format: `1 may 2025 - 2 dec 2025` (day, 3-letter lowercase month, year).
/// Intentionally not localized so the same string appears in every locale.
abstract final class PlanDateFormat {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Formats a single calendar date, e.g. `1 may 2025`.
  static String formatDate(DateTime date) {
    final normalized = PlanUtils.calendarDateOnly(date);
    return '${normalized.day} ${_months[normalized.month - 1]} ${normalized.year}';
  }

  /// Formats an inclusive calendar range, e.g. `1 may 2025 - 2 dec 2025`.
  static String formatRange(DateTime start, DateTime end) {
    return '${formatDate(start)} - ${formatDate(end)}';
  }

  /// Returns null when either bound is missing.
  static String? formatRangeOrNull(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    return formatRange(start, end);
  }

  /// Formats a single date when [end] is null, otherwise a range.
  static String? formatRangeOrSingle(DateTime? start, DateTime? end) {
    if (start == null) return null;
    if (end == null) return formatDate(start);
    return formatRange(start, end);
  }
}
