import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';

/// Fixed English calendar-date labels for plan/series date ranges.
///
/// Format: `1 May 2025 - 2 Dec 2025` (day, 3-letter uppercase month, year).
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

  /// Formats a single calendar date, e.g. `1 May 2025`.
  static String formatDate(DateTime date, {bool includeYear = true}) {
    final normalized = PlanUtils.calendarDateOnly(date);
    final month = _months[normalized.month - 1];
    if (!includeYear) return '${normalized.day} $month';
    return '${normalized.day} $month ${normalized.year}';
  }

  /// Formats an inclusive calendar range, e.g. `1 May 2025 - 2 Dec 2025`.
  static String formatRange(
    DateTime start,
    DateTime end, {
    bool includeYear = true,
  }) {
    return '${formatDate(start, includeYear: includeYear)} - ${formatDate(end, includeYear: includeYear)}';
  }

  /// Returns null when either bound is missing.
  static String? formatRangeOrNull(
    DateTime? start,
    DateTime? end, {
    bool includeYear = true,
  }) {
    if (start == null || end == null) return null;
    return formatRange(start, end, includeYear: includeYear);
  }

  /// Formats a single date when [end] is null, otherwise a range.
  static String? formatRangeOrSingle(
    DateTime? start,
    DateTime? end, {
    bool includeYear = true,
  }) {
    if (start == null) return null;
    if (end == null) return formatDate(start, includeYear: includeYear);
    return formatRange(start, end, includeYear: includeYear);
  }
}
