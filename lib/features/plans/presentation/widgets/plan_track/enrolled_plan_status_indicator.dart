import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/missed_days_badge.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/on_track_badge.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/plan_date_range_label.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Right-side status indicator for an enrolled plan. Decision tree:
///
/// - Future range (today < `dateRange.start`) → nothing.
/// - All days complete → nothing.
/// - Ongoing (today within range) + zero missed → [OnTrackBadge].
/// - Ongoing with missed days OR past with missed days → [MissedDaysBadge]
///   (self-hides when count is 0).
///
/// Missed days are counted from Day 1 of the plan, so late joiners see the
/// full backlog they need to catch up on.
///
/// Watches [userPlanDaysCompletionStatusProvider] per [planId]. Loading
/// and error states render nothing so the host row stays stable — this is
/// decorative state, never blocking.
class EnrolledPlanStatusIndicator extends ConsumerWidget {
  final String planId;
  final PlanDateRange dateRange;

  const EnrolledPlanStatusIndicator({
    super.key,
    required this.planId,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (today.isBefore(dateRange.start)) return const SizedBox.shrink();

    final asyncStatus = ref.watch(userPlanDaysCompletionStatusProvider(planId));

    return asyncStatus.when(
      data:
          (either) => either.fold(
            (_) => const SizedBox.shrink(),
            (completion) => _resolveBadge(completion),
          ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _resolveBadge(Map<int, bool> completion) {
    final totalDays = dateRange.totalDays;
    final allCompleted = List<int>.generate(
      totalDays,
      (i) => i + 1,
    ).every((d) => completion[d] == true);
    if (allCompleted) return const SizedBox.shrink();

    final missed = PlanUtils.calculateMissedDays(
      dateRange.start,
      totalDays,
      completion,
    );

    if (dateRange.isCurrent && missed == 0) return const OnTrackBadge();

    return MissedDaysBadge(
      planStartDate: dateRange.start,
      totalDays: totalDays,
      completionStatus: completion,
    );
  }
}
