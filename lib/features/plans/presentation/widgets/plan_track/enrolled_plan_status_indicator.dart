import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/missed_days_badge.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/on_track_badge.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/plan_date_range_label.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Right-side status indicator for an enrolled plan. Decision tree:
///
/// - Future range (today < `dateRange.start`) -> nothing.
/// - All days complete -> compact check icon.
/// - Today within range, zero missed -> [OnTrackBadge].
/// - Today within range with missed days OR range fully in the past with
///   missed days -> [MissedDaysBadge] (self-hides when count is 0).
///
/// Watches [userPlanDaysCompletionStatusProvider] per [planId]. Loading
/// and error states render nothing so the host row stays stable — this is
/// decorative state, never blocking.
class EnrolledPlanStatusIndicator extends ConsumerWidget {
  final String planId;
  final PlanDateRange dateRange;

  /// When the user enrolled in the plan (= `userPlan.startedAt`). Used to
  /// skip pre-enrollment days when counting missed days.
  final DateTime userJoinDate;

  const EnrolledPlanStatusIndicator({
    super.key,
    required this.planId,
    required this.dateRange,
    required this.userJoinDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (today.isBefore(dateRange.start)) return const SizedBox.shrink();

    final asyncStatus = ref.watch(
      userPlanDaysCompletionStatusProvider(planId),
    );

    return asyncStatus.when(
      data: (either) => either.fold(
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
    if (allCompleted) return const _CompletedTickIcon();

    final missed = PlanUtils.calculateMissedDays(
      dateRange.start,
      userJoinDate,
      totalDays,
      completion,
    );

    if (dateRange.isCurrent && missed == 0) return const OnTrackBadge();

    return MissedDaysBadge(
      planStartDate: dateRange.start,
      userJoinDate: userJoinDate,
      totalDays: totalDays,
      completionStatus: completion,
    );
  }
}

/// Compact check icon shown when every day of an enrolled plan is complete.
class _CompletedTickIcon extends StatelessWidget {
  const _CompletedTickIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.check,
      size: 18,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
