import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';

class MissedDaysBadge extends StatelessWidget {
  /// Day-1 anchor of the plan (= `plan.startDate ?? plan.startedAt`).
  final DateTime planStartDate;
  final int totalDays;
  final Map<int, bool> completionStatus;

  /// Called when the badge is tapped. Receives the first missed day number.
  final void Function(int firstMissedDay)? onTap;

  const MissedDaysBadge({
    super.key,
    required this.planStartDate,
    required this.totalDays,
    required this.completionStatus,
    this.onTap,
  });

  int? _findFirstMissedDay() {
    final now = DateTime.now();
    final normalizedToday = DateTime(now.year, now.month, now.day);
    final todayDayNumber = PlanUtils.dayNumberFor(planStartDate, now, totalDays);

    final start = planStartDate.toLocal();
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final lastPlanDay = normalizedStart.add(Duration(days: totalDays - 1));

    final isPlanOver = normalizedToday.isAfter(lastPlanDay);
    final upperBound = isPlanOver ? totalDays : todayDayNumber - 1;

    for (int day = 1; day <= upperBound; day++) {
      if (completionStatus[day] != true) return day;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final missedDays = PlanUtils.calculateMissedDays(
      planStartDate,
      totalDays,
      completionStatus,
    );

    if (missedDays <= 0) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final firstMissedDay = _findFirstMissedDay();

    return GestureDetector(
      onTap: firstMissedDay != null ? () => onTap?.call(firstMissedDay) : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: onTap != null ? 10 : 12,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onTap != null) ...[
              Icon(Icons.arrow_back, size: 10, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              context.l10n.missedDaysCount(missedDays),
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
