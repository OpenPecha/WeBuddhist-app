import 'package:flutter_pecha/core/storage/special_plan_started_at_store.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('SpecialPlanBootstrap');

/// Eagerly-instantiated provider that mirrors `UserPlansModel.startedAt` for
/// any plan ID in [kSpecialPlanNotifications] into [SpecialPlanStartedAtStore]
/// each time `userPlansFutureProvider` resolves, then directly reschedules the
/// per-day series via [RoutineNotificationService.rescheduleSpecialPlanSeries].
///
/// Why: the day-N notifications are deterministic one-shots keyed off
/// `startedAt`. After uninstall+reinstall, login on a new device, or a
/// timezone/clock change, those one-shots may be missing from the OS schedule.
/// Rescheduling here — independent of the local Hive routine state — is
/// idempotent (cancels first) and guarantees the next day's fire is registered
/// even when `_loadRoutines` hasn't populated the routine block yet.
final specialPlanBootstrapProvider = Provider<void>((ref) {
  _logger.info('[SP-BOOT] specialPlanBootstrapProvider initialized — listening to userPlansFutureProvider');
  ref.listen<AsyncValue<dynamic>>(userPlansFutureProvider, (previous, next) {
    _logger.info('[SP-BOOT] userPlansFutureProvider state changed: ${next.runtimeType}');
    next.whenData((either) async {
      either.fold(
        (failure) => _logger.warning(
          '[SP-BOOT] userPlans fetch failed — cannot bootstrap: $failure',
        ),
        (response) async {
          _logger.info(
            '[SP-BOOT] userPlans loaded: ${response.userPlans.length} plans',
          );
          for (final plan in response.userPlans) {
            if (!isSpecialPlan(plan.id)) continue;
            await _bootstrapPlan(ref, plan);
          }
          _logger.info('[SP-BOOT] iteration done');
        },
      );
    });
  });
});

Future<void> _bootstrapPlan(Ref ref, UserPlansModel plan) async {
  final cached = SpecialPlanStartedAtStore.getStartedAt(plan.id);
  _logger.info(
    '[SP-BOOT] special plan ${plan.id} cached=$cached '
    'serverStartedAt=${plan.startedAt.toIso8601String()}',
  );
  if (cached?.toIso8601String() != plan.startedAt.toIso8601String()) {
    await SpecialPlanStartedAtStore.setStartedAt(plan.id, plan.startedAt);
    _logger.info(
      '[SP-BOOT] wrote startedAt for ${plan.id} = ${plan.startedAt.toIso8601String()}',
    );
  } else {
    _logger.info('[SP-BOOT] cache up-to-date for ${plan.id} — no write');
  }

  // Always reschedule (idempotent) so the OS schedule survives uninstall +
  // reinstall and re-login, regardless of whether the routine-block Hive
  // state has loaded yet.
  try {
    final notifService = ref.read(routineNotificationServiceProvider);
    await notifService.rescheduleSpecialPlanSeries(
      planId: plan.id,
      planTitle: plan.title,
      planImageUrl: plan.imageUrl,
    );
  } catch (e, st) {
    _logger.error('[SP-BOOT] rescheduleSpecialPlanSeries failed for ${plan.id}', e, st);
  }
}
