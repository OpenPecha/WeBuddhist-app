import 'package:flutter_pecha/core/storage/special_plan_started_at_store.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';

final _logger = AppLogger('SpecialPlanEnrollmentHook');

/// 09:00 — the routine block time used by event-enrollments. If the user
/// enrolls before this time, the regular daily routine notification will
/// serve as Day 1, so the immediate fire is skipped to avoid duplicates.
const int kRoutineBlockHourThreshold = 9;

/// Call after a user has been (newly or repeatedly) enrolled in [plan].
/// Persists `plan.startedAt` (server truth) into [SpecialPlanStartedAtStore]
/// so the routine notification scheduler can compute day-N at fire time.
///
/// Does NOT fire the immediate Day 1 notification — that requires the
/// notification permission, which is only requested after the home screen
/// mounts (post-onboarding). The actual fire happens via
/// [tryFirePendingSpecialPlanDay1Notifications], called from the home screen
/// once permission has been granted.
Future<void> onSpecialPlanEnrolled(UserPlansModel plan) async {
  _logger.info(
    '[SP-HOOK] onSpecialPlanEnrolled called: planId=${plan.id} '
    'title="${plan.title}" startedAt=${plan.startedAt.toIso8601String()} '
    'startedAtLocal=${plan.startedAt.toLocal()}',
  );
  if (!isSpecialPlan(plan.id)) {
    _logger.info('[SP-HOOK] planId=${plan.id} is NOT a special plan — skip');
    return;
  }

  await SpecialPlanStartedAtStore.setStartedAt(plan.id, plan.startedAt);
  _logger.info(
    '[SP-HOOK] cached startedAt for ${plan.id} = ${plan.startedAt.toIso8601String()}',
  );
}

/// Fires the Day 1 immediate notification for any [plans] whose:
///   - id is in [kSpecialPlanNotifications],
///   - startedAt date == today (local),
///   - current local hour ≥ 09:00 (otherwise the scheduled 09:00 fire serves
///     as Day 1, so skipping avoids duplicates),
///   - and Day 1 has not already been shown today (idempotency flag).
///
/// Call this AFTER notification permission has been requested/granted, e.g.
/// from `HomeScreen._requestNotificationPermissionsIfNeeded`. Without
/// permission, `flutter_local_notifications.show()` silently no-ops on iOS
/// and Android 13+ — so we cannot fire from inside the onboarding flow.
Future<void> tryFirePendingSpecialPlanDay1Notifications(
  Iterable<UserPlansModel> plans,
) async {
  final now = DateTime.now();
  final planList = plans.toList();
  _logger.info(
    '[SP-DAY1-HOOK] tryFirePendingSpecialPlanDay1Notifications called '
    'plans=${planList.length} now=$now (local) hour=${now.hour} '
    'threshold=$kRoutineBlockHourThreshold',
  );
  for (final plan in planList) {
    _logger.info(
      '[SP-DAY1-HOOK] evaluating planId=${plan.id} title="${plan.title}" '
      'startedAt=${plan.startedAt} startedAtLocal=${plan.startedAt.toLocal()}',
    );
    if (!isSpecialPlan(plan.id)) {
      _logger.info('[SP-DAY1-HOOK] skip ${plan.id}: not a special plan');
      continue;
    }

    final startedLocal = plan.startedAt.toLocal();
    final isEnrollmentDay = DateTime(
          startedLocal.year,
          startedLocal.month,
          startedLocal.day,
        ) ==
        DateTime(now.year, now.month, now.day);
    _logger.info(
      '[SP-DAY1-HOOK] enrollment-day check planId=${plan.id} '
      'startedLocal=${startedLocal.year}-${startedLocal.month}-${startedLocal.day} '
      'now=${now.year}-${now.month}-${now.day} isEnrollmentDay=$isEnrollmentDay',
    );
    if (!isEnrollmentDay) {
      _logger.info(
        '[SP-DAY1-HOOK] skip ${plan.id}: not enrollment day '
        '(startedAt=${plan.startedAt}, now=$now)',
      );
      continue;
    }

    if (now.hour < kRoutineBlockHourThreshold) {
      _logger.info(
        '[SP-DAY1-HOOK] skip ${plan.id}: now hour=${now.hour} < $kRoutineBlockHourThreshold '
        '— scheduled 09:00 routine fire will serve as Day 1',
      );
      continue;
    }

    // Ensure the cache has the startedAt — usually populated by
    // [onSpecialPlanEnrolled] or the bootstrap listener, but be defensive.
    final cached = SpecialPlanStartedAtStore.getStartedAt(plan.id);
    _logger.info('[SP-DAY1-HOOK] cache lookup ${plan.id} cached=$cached');
    if (cached == null) {
      _logger.info('[SP-DAY1-HOOK] cache miss ${plan.id} — priming startedAt');
      await SpecialPlanStartedAtStore.setStartedAt(plan.id, plan.startedAt);
    }

    _logger.info('[SP-DAY1-HOOK] firing Day 1 immediate for ${plan.id}');
    final id = await RoutineNotificationService().showSpecialPlanDay1Immediate(
      planId: plan.id,
      planTitle: plan.title,
      planImageUrl: plan.imageUrl,
    );
    _logger.info('[SP-DAY1-HOOK] Day 1 fire for ${plan.id} returned id=$id');
  }
  _logger.info('[SP-DAY1-HOOK] done iterating ${planList.length} plans');
}
