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

/// Caches [plan.startedAt] (server truth) into [SpecialPlanStartedAtStore]
/// so the notification scheduler can compute the correct day-N at fire time.
///
/// Does NOT fire an immediate notification. Permission is only requested after
/// HomeScreen mounts; the actual fire happens via [tryFirePendingSpecialPlanNotifications].
Future<void> onSpecialPlanEnrolled(UserPlansModel plan) async {
  if (!isSpecialPlan(plan.id)) return;

  final anchor = plan.effectiveStartDate;
  await SpecialPlanStartedAtStore.setStartedAt(plan.id, anchor);
  _logger.info(
    '[SP-HOOK] cached anchor for ${plan.id} = ${anchor.toIso8601String()} '
    '(startDate=${plan.startDate?.toIso8601String()}, startedAt=${plan.startedAt.toIso8601String()})',
  );
}

/// Fires an immediate notification for any [plans] whose series is active
/// today and whose scheduled block time (09:00) has already passed.
///
/// Handles all three cases:
///   - **Day 1 / new enrol**: startedAt == today, past 09:00 → fire Day 1.
///   - **Delete + re-enrol**: startedAt is in the past, still within series,
///     past 09:00 → fire the current day's content.
///   - **Start date in the future**: skip — scheduled one-shot handles it.
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
  final planList = plans.toList();
  for (final plan in planList) {
    if (!isSpecialPlan(plan.id)) continue;

    final anchorLocal = plan.effectiveStartDate.toLocal();
    final isPlanDay1 = DateTime(
          anchorLocal.year,
          anchorLocal.month,
          anchorLocal.day,
        ) ==
        DateTime(now.year, now.month, now.day);

    if (!isPlanDay1) {
      continue;
    }

    // Before 09:00 the scheduled one-shot handles the notification.
    if (now.hour < kRoutineBlockHourThreshold) {
      _logger.info('skip ${plan.id}: before block time (${now.hour}h < ${kRoutineBlockHourThreshold}h)');
      continue;
    }

    // Idempotency: already shown today?
    if (SpecialPlanStartedAtStore.wasShownOn(plan.id, today)) {
      _logger.info('skip ${plan.id}: already shown today');
      continue;
    }

    // Ensure the cache has the startedAt — usually populated by
    // [onSpecialPlanEnrolled] or the bootstrap listener, but be defensive.
    final cached = SpecialPlanStartedAtStore.getStartedAt(plan.id);
    _logger.info('[SP-DAY1-HOOK] cache lookup ${plan.id} cached=$cached');
    if (cached == null) {
      _logger.info('[SP-DAY1-HOOK] cache miss ${plan.id} — priming effectiveStartDate');
      await SpecialPlanStartedAtStore.setStartedAt(plan.id, plan.effectiveStartDate);
    }

    _logger.info('Firing day ${daysSince + 1} immediate for ${plan.id}');
    await RoutineNotificationService().showSpecialPlanCurrentDayImmediate(
      planId: plan.id,
      planTitle: plan.title,
      planImageUrl: plan.imageUrl,
    );
  }
}
