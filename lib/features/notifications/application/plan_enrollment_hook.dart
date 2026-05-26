import 'package:flutter_pecha/core/config/app_feature_flags.dart';
import 'package:flutter_pecha/core/storage/plan_metadata_store.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';

final _logger = AppLogger('PlanEnrollmentHook');

/// Default hour for the routine block created during event enrollment.
/// Mirrors [kRoutineBlockHourThreshold] in special_plan_enrollment_hook.dart.
const int kPlanBlockHour = 9;
const int kPlanBlockMinute = 0;

/// Caches [plan.startedAt] and [plan.totalDays] into [PlanMetadataStore]
/// so the notification scheduler can compute fire dates synchronously.
///
/// Skips special plans — those are handled by [onSpecialPlanEnrolled].
Future<void> onPlanEnrolled(UserPlansModel plan) async {
  if (isSpecialPlan(plan.id)) return;
  await PlanMetadataStore.setMetadata(
    plan.id,
    startedAt: plan.startedAt,
    totalDays: plan.totalDays,
  );
  _logger.info('Cached metadata for ${plan.id}: startedAt=${plan.startedAt.toIso8601String()} totalDays=${plan.totalDays}');
}

/// Fires an immediate notification for any [plans] where today's scheduled
/// block time has already passed and the notification has not yet been shown.
///
/// Handles all three cases:
///   - **startedAt == today**: Day 1 immediate if block time has passed.
///   - **startedAt in the past**: Day-N immediate if block time has passed.
///   - **startedAt in the future**: skip — scheduled one-shot handles it.
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
      'tryFirePendingPlanDayNotifications: skipped — kSchedulePlanNotifications=false',
    );
    return;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var firedCount = 0;

  for (final plan in plans) {
    if (isSpecialPlan(plan.id)) continue;

    final startedLocal = plan.startedAt.toLocal();
    final startedDay = DateTime(
      startedLocal.year,
      startedLocal.month,
      startedLocal.day,
    );

    // Plan hasn't started yet.
    if (startedDay.isAfter(today)) continue;

    // Look up the actual scheduled time from the routine block.
    final matchingBlock = routineBlocks.cast<RoutineBlock?>().firstWhere(
      (block) => block!.items.any(
        (item) => item.id == plan.id && item.type == RoutineItemType.plan,
      ),
      orElse: () => null,
    );

    final blockHour = matchingBlock?.time.hour ?? kPlanBlockHour;
    final blockMinute = matchingBlock?.time.minute ?? kPlanBlockMinute;
    final blockTimePassed =
        now.hour > blockHour || (now.hour == blockHour && now.minute >= blockMinute);

    if (!blockTimePassed) continue;

    final daysSince = today.difference(startedDay).inDays;
    final todayDayNumber = daysSince + 1;

    if (todayDayNumber > plan.totalDays) continue;
    if (PlanMetadataStore.wasImmediateShownOn(plan.id, today)) continue;

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
    _logger.info('Fired $firedCount immediate plan day notifications');
  }
}
