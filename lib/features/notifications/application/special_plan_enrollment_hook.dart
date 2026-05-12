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
  await SpecialPlanStartedAtStore.setStartedAt(plan.id, plan.startedAt);
  _logger.info('Cached startedAt for ${plan.id}: ${plan.startedAt.toIso8601String()}');
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
  final today = DateTime(now.year, now.month, now.day);

  for (final plan in plans) {
    if (!isSpecialPlan(plan.id)) continue;

    final entries = kSpecialPlanNotifications[plan.id]!;
    final startedLocal = plan.startedAt.toLocal();
    final startedDay = DateTime(
      startedLocal.year,
      startedLocal.month,
      startedLocal.day,
    );
    final daysSince = today.difference(startedDay).inDays;

    // Must be within the active series window.
    if (daysSince < 0 || daysSince >= entries.length) {
      _logger.info('skip ${plan.id}: daysSince=$daysSince outside series');
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

    // Ensure startedAt is cached before firing (defensive — normally set by
    // onSpecialPlanEnrolled or the bootstrap listener).
    if (SpecialPlanStartedAtStore.getStartedAt(plan.id) == null) {
      await SpecialPlanStartedAtStore.setStartedAt(plan.id, plan.startedAt);
    }

    _logger.info('Firing day ${daysSince + 1} immediate for ${plan.id}');
    await RoutineNotificationService().showSpecialPlanCurrentDayImmediate(
      planId: plan.id,
      planTitle: plan.title,
      planImageUrl: plan.imageUrl,
    );
  }
}
