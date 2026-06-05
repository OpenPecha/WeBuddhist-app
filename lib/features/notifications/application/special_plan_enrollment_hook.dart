import 'package:flutter_pecha/core/storage/plan_metadata_store.dart';
import 'package:flutter_pecha/core/storage/special_plan_started_at_store.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';

final _logger = AppLogger('SpecialPlanEnrollmentHook');

/// The time-of-day threshold (hour, 24h) for the scheduled routine block
/// created server-side during event enrollment. Before this time the
/// scheduled one-shot serves as the day's notification, so we never fire
/// an immediate to avoid duplicates.
const int kRoutineBlockHourThreshold = 9;

/// Caches the plan's day-1 anchor ([plan.effectiveStartDate]) into
/// [SpecialPlanStartedAtStore] so the notification scheduler can compute
/// the correct day-N at fire time.
///
/// Does NOT fire an immediate notification. Permission is only requested after
/// HomeScreen mounts; the actual fire happens via [tryFirePendingSpecialPlanNotifications].
Future<void> onSpecialPlanEnrolled(UserPlansModel plan) async {
  if (!isSpecialPlan(plan.id)) return;

  final anchor = plan.effectiveStartDate;
  await SpecialPlanStartedAtStore.setStartedAt(plan.id, anchor);
  await PlanMetadataStore.setMetadata(
    plan.id,
    effectiveStartDate: anchor,
    totalDays: plan.totalDays,
  );
  _logger.info(
    '[ENROLL-NOTIF-SP] cached ${plan.id} anchor=${anchor.toIso8601String()} '
    'startDate=${plan.startDate?.toIso8601String()} '
    'startedAt=${plan.startedAt.toIso8601String()} totalDays=${plan.totalDays}',
  );
}

/// Fires an immediate notification for any [plans] whose series is active
/// today and whose scheduled block time has already passed.
///
/// Handles:
///   - **Day 1 / new enrol**: anchor == today, past block time → fire Day 1.
///   - **Late enrollment**: anchor in past, today is day-N within series →
///     fire Day-N (e.g. user joined on day 5 → fire Day 5 notification).
///   - **Delete + re-enrol**: anchor in past, still within series → fire
///     current day.
///   - **Anchor in the future** (early enrol): skip — scheduled one-shot
///     handles it on the plan's actual day 1.
///
/// Idempotent: uses a per-date flag so repeated calls on the same day are
/// no-ops even if the user opens the app multiple times.
///
/// Call AFTER notification permission has been granted. Without permission
/// `_plugin.show()` silently no-ops on iOS and Android 13+.
Future<void> tryFirePendingSpecialPlanNotifications(
  Iterable<UserPlansModel> plans,
) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final planList = plans.toList();
  for (final plan in planList) {
    if (!isSpecialPlan(plan.id)) continue;

    final anchorLocal = plan.effectiveStartDate.toLocal();
    final anchorDay = DateTime(
      anchorLocal.year,
      anchorLocal.month,
      anchorLocal.day,
    );

    // Plan hasn't started yet (early enrollment) — the scheduled one-shot
    // will fire on the plan's actual day 1.
    if (anchorDay.isAfter(today)) {
      _logger.info(
        '[ENROLL-NOTIF-SP] skip ${plan.id}: anchor in future '
        '(${anchorDay.toIso8601String()} > ${today.toIso8601String()})',
      );
      continue;
    }

    // Today is on or after day 1 — figure out which day-N we're on so we
    // can fire the right immediate.
    final daysSince = today.difference(anchorDay).inDays;
    final dayNumber = daysSince + 1;

    // Before the block time the scheduled one-shot handles the notification.
    if (now.hour < kRoutineBlockHourThreshold) {
      _logger.info(
        '[ENROLL-NOTIF-SP] skip ${plan.id}: before block time '
        '(${now.hour}h < ${kRoutineBlockHourThreshold}h) day=$dayNumber',
      );
      continue;
    }

    // Idempotency: already shown today?
    if (SpecialPlanStartedAtStore.wasShownOn(plan.id, today)) {
      _logger.info(
        '[ENROLL-NOTIF-SP] skip ${plan.id}: already shown today day=$dayNumber',
      );
      continue;
    }

    // Ensure the cache has the anchor — usually populated by
    // [onSpecialPlanEnrolled] or the bootstrap listener, but be defensive.
    final cached = SpecialPlanStartedAtStore.getStartedAt(plan.id);
    if (cached == null) {
      _logger.info(
        '[ENROLL-NOTIF-SP] cache miss ${plan.id} — priming effectiveStartDate=${plan.effectiveStartDate.toIso8601String()}',
      );
      await SpecialPlanStartedAtStore.setStartedAt(
        plan.id,
        plan.effectiveStartDate,
      );
    }

    final entries = kSpecialPlanNotifications[plan.id]!;
    if (daysSince < entries.length) {
      _logger.info(
        '[ENROLL-NOTIF-SP] firing ${plan.id} day=$dayNumber (custom series) anchor=${anchorDay.toIso8601String()}',
      );
      await RoutineNotificationService().showSpecialPlanCurrentDayImmediate(
        planId: plan.id,
        planTitle: plan.title,
        planImageUrl: plan.imageUrl,
      );
    } else if (daysSince < plan.totalDays &&
        !PlanMetadataStore.wasImmediateShownOn(plan.id, today)) {
      _logger.info(
        '[ENROLL-NOTIF-SP] firing ${plan.id} day=$dayNumber/${plan.totalDays} (general fallback) anchor=${anchorDay.toIso8601String()}',
      );
      final id = await RoutineNotificationService().showPlanDayImmediate(
        planId: plan.id,
        planTitle: plan.title,
        planImageUrl: plan.imageUrl,
        dayNumber: dayNumber,
        totalDays: plan.totalDays,
      );
      if (id != null) {
        await PlanMetadataStore.markImmediateShownOn(plan.id, today);
      }
    } else {
      _logger.info(
        '[ENROLL-NOTIF-SP] skip ${plan.id}: past plan end or already shown day=$dayNumber/${plan.totalDays}',
      );
    }
  }
}
