import 'package:flutter_pecha/core/config/app_feature_flags.dart';
import 'package:flutter_pecha/core/storage/plan_metadata_store.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';

final _logger = AppLogger('PlanEnrollmentHook');


/// Caches the plan's day-1 anchor (`plan.effectiveStartDate`) and totalDays
/// into [PlanMetadataStore] so the notification scheduler can compute fire
/// dates synchronously.
///
/// For fixed-date plans, `effectiveStartDate == plan.startDate` (plan's
/// scheduled start), NOT the user's enrollment time. This ensures users who
/// join late see the correct day-N notification (e.g. "Day 5 of N") instead
/// of being treated as Day 1.
///
/// Skips special plans — those are handled by [onSpecialPlanEnrolled].
Future<void> onPlanEnrolled(UserPlansModel plan) async {
  if (isSpecialPlan(plan.id)) return;
  final anchor = plan.effectiveStartDate;
  await PlanMetadataStore.setMetadata(
    plan.id,
    effectiveStartDate: anchor,
    totalDays: plan.totalDays,
  );
  _logger.info(
    '[ENROLL-NOTIF] cached ${plan.id} anchor=${anchor.toIso8601String()} '
    'startDate=${plan.startDate?.toIso8601String()} '
    'startedAt=${plan.startedAt.toIso8601String()} totalDays=${plan.totalDays}',
  );
}

/// Fires an immediate notification for any [plans] where today's scheduled
/// block time has already passed and the notification has not yet been shown.
///
/// Handles all three cases:
///   - **anchor == today**: Day 1 immediate if block time has passed.
///   - **anchor in the past**: Day-N immediate based on plan day-number.
///   - **anchor in the future** (early enrollment): skip — scheduled
///     one-shot handles it on the plan's actual start date.
///
/// [routineBlocks] provides the actual block time per plan, so we never fire
/// early (e.g. a 10:30 plan is not fired at 09:15).
///
/// Call AFTER notification permission has been granted.
Future<void> tryFirePendingPlanDayNotifications(
  Iterable<UserPlansModel> plans,
  List<RoutineBlock> routineBlocks,
) async {
  // Feature flag gate: when general-plan notifications are disabled we
  // never fire today's catch-up immediate either. Special plans are
  // handled by `tryFirePendingSpecialPlanNotifications` and are unaffected.
  if (!AppFeatureFlags.kSchedulePlanNotifications) {
    _logger.info(
      '[ENROLL-NOTIF] tryFirePending: skipped — kSchedulePlanNotifications=false',
    );
    return;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var firedCount = 0;

  for (final plan in plans) {
    if (isSpecialPlan(plan.id)) continue;

    final anchorLocal = plan.effectiveStartDate.toLocal();
    final anchorDay = DateTime(
      anchorLocal.year,
      anchorLocal.month,
      anchorLocal.day,
    );

    // Plan hasn't started yet (early enrollment) — scheduled one-shot
    // will fire on day 1.
    if (anchorDay.isAfter(today)) {
      _logger.info(
        '[ENROLL-NOTIF] tryFirePending skip ${plan.id}: anchor in future '
        '(${anchorDay.toIso8601String()} > ${today.toIso8601String()})',
      );
      continue;
    }

    // Only fire for plans that are in a routine block with a user-set time.
    // Enrolled plans (subscriptions) with no routine block must not trigger
    // notifications — notifications are tied to routine blocks, not enrollments.
    final matchingBlock = routineBlocks.cast<RoutineBlock?>().firstWhere(
      (block) => block!.items.any(
        (item) => item.id == plan.id && item.type == RoutineItemType.plan,
      ),
      orElse: () => null,
    );

    if (matchingBlock == null) {
      _logger.info(
        '[ENROLL-NOTIF] tryFirePending skip ${plan.id}: not in any routine block',
      );
      continue;
    }

    final blockHour = matchingBlock.time.hour;
    final blockMinute = matchingBlock.time.minute;
    final blockTimePassed =
        now.hour > blockHour || (now.hour == blockHour && now.minute >= blockMinute);

    if (!blockTimePassed) continue;

    final daysSince = today.difference(anchorDay).inDays;
    final todayDayNumber = daysSince + 1;

    if (todayDayNumber > plan.totalDays) continue;
    if (PlanMetadataStore.wasImmediateShownOn(plan.id, today)) continue;

    _logger.info(
      '[ENROLL-NOTIF] tryFirePending firing ${plan.id} day=$todayDayNumber/${plan.totalDays}',
    );
    final id = await RoutineNotificationService().showPlanDayImmediate(
      planId: plan.id,
      planTitle: plan.title,
      planImageUrl: plan.imageUrl,
      dayNumber: todayDayNumber,
      totalDays: plan.totalDays,
    );
    if (id == null) continue; // no permission yet — will retry after grant
    await PlanMetadataStore.markImmediateShownOn(plan.id, today);
    firedCount++;
  }

  if (firedCount > 0) {
    _logger.info(
      '[ENROLL-NOTIF] tryFirePending: fired $firedCount immediate plan-day notifications',
    );
  }
}
