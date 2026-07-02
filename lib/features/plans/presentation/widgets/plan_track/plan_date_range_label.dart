import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_date_format.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';

/// Immutable value type encapsulating a plan's `[start, end]` calendar
/// window along with its pre-formatted label and a `today within range`
/// flag. Centralises the math/formatting so screens can render and compare
/// consistently without recomputing dates.
class PlanDateRange {
  /// Day 1 anchor (local midnight).
  final DateTime start;

  /// Last day of the plan (local midnight, inclusive).
  final DateTime end;

  /// Total number of plan days (`end - start + 1`).
  final int totalDays;

  /// True when `DateUtils.dateOnly(DateTime.now())` is within `[start, end]`.
  final bool isCurrent;

  /// Pre-formatted "1 May 2025 - 2 Dec 2025" label (not localized).
  final String formatted;

  const PlanDateRange({
    required this.start,
    required this.end,
    required this.totalDays,
    required this.isCurrent,
    required this.formatted,
  });

  /// Returns null for flexible plans (no [startDate]) or non-positive
  /// [totalDays], so callers can branch on a single null check.
  static PlanDateRange? tryCreate({
    required DateTime? startDate,
    required int totalDays,
    bool includeYear = true,
  }) {
    if (startDate == null || totalDays <= 0) return null;

    final start = PlanUtils.calendarDateOnly(startDate);
    final end = start.add(Duration(days: totalDays - 1));
    final today = DateUtils.dateOnly(DateTime.now());
    final isCurrent = !today.isBefore(start) && !today.isAfter(end);

    final formatted = PlanDateFormat.formatRange(
      start,
      end,
      includeYear: includeYear,
    );

    return PlanDateRange(
      start: start,
      end: end,
      totalDays: totalDays,
      isCurrent: isCurrent,
      formatted: formatted,
    );
  }
}

/// Renders a [PlanDateRange] as either:
///
/// - an **inverted filled pill** (`onSurface` / `surface`) when the range
///   contains today's date (dark pill in light mode, light pill in dark
///   mode), or
/// - a **muted subtitle text** otherwise (past or future ranges).
///
/// The widget intentionally sizes to its content and aligns left, so it
/// composes cleanly inside `Expanded` / `Flexible` rows alongside trailing
/// status indicators.
class PlanDateRangeLabel extends StatelessWidget {
  final PlanDateRange dateRange;

  /// Optional line-height multiplier applied to the muted-text variant.
  /// The chip variant ignores this (its layout is fixed).
  final double? lineHeight;

  const PlanDateRangeLabel({
    super.key,
    required this.dateRange,
    this.lineHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (dateRange.isCurrent) {
      final colorScheme = Theme.of(context).colorScheme;
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.onSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            dateRange.formatted,
            style: TextStyle(
              color: colorScheme.surface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Text(
      dateRange.formatted,
      style: TextStyle(
        fontSize: 13,
        height: lineHeight,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
