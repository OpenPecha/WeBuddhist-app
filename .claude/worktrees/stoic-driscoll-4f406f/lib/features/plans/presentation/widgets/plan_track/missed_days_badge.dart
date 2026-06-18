import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';

class MissedDaysBadge extends StatelessWidget {
  final DateTime startDate;
  final int totalDays;
  final Map<int, bool> completionStatus;

  const MissedDaysBadge({
    super.key,
    required this.startDate,
    required this.totalDays,
    required this.completionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final missedDays = PlanUtils.calculateMissedDays(
      startDate,
      totalDays,
      completionStatus,
    );

    if (missedDays <= 0) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        context.l10n.missedDaysCount(missedDays),
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontFamily: "Inter",
        ),
      ),
    );
  }
}
