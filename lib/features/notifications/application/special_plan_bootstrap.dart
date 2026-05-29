import 'package:flutter_pecha/core/storage/special_plan_started_at_store.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('SpecialPlanBootstrap');

/// Eagerly-instantiated provider that keeps [SpecialPlanStartedAtStore] and
/// the OS notification schedule in sync with the server's plan list.
///
/// Fires whenever [userPlansFutureProvider] resolves. For each special plan:
///   - If the plan is **not** in the local routine → clears cached metadata
///     (user removed it from their routine).
///   - If the plan **is** in the routine → updates startedAt if stale, then
///     reschedules the day-N one-shot series (idempotent, survives reinstall).
///
/// Special plans are identified by [isSpecialPlan]. All other plans are
/// handled by [planNotificationBootstrapProvider].
final specialPlanBootstrapProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<dynamic>>(userPlansFutureProvider, (_, next) {
    next.whenData((either) {
      either.fold(
        (failure) => _logger.warning('userPlans fetch failed: $failure'),
        (response) async {
          for (final plan in response.userPlans) {
            if (isSpecialPlan(plan.id)) await _bootstrap(ref, plan);
          }
        },
      );
    });
  });
});

Future<void> _bootstrap(Ref ref, UserPlansModel plan) async {
  _logger.info(
    '[ENROLL-NOTIF-SP] bootstrap ${plan.id} '
    'startDate=${plan.startDate?.toIso8601String()} '
    'startedAt=${plan.startedAt.toIso8601String()} '
    'effective=${plan.effectiveStartDate.toIso8601String()}',
  );

  // Determine whether the plan is in the user's current local routine.
  final routineBlocks = ref.read(routineProvider).blocks;

  // Guard against a timing window where userPlansFutureProvider resolves
  // before routineProvider has loaded its Hive data. An empty routine is
  // ambiguous (might mean "not yet loaded"), so skip the cleanup to avoid
  // incorrectly wiping metadata; the next bootstrap fire will catch up.
  if (routineBlocks.isEmpty) {
    _logger.info(
      '[ENROLL-NOTIF-SP] bootstrap ${plan.id} — routine empty/not loaded yet, skip',
    );
    return;
  }

  final inRoutine = routineBlocks.any(
    (block) => block.items.any(
      (item) => item.id == plan.id && item.type == RoutineItemType.plan,
    ),
  );

  if (!inRoutine) {
    // Plan was removed from the routine — clear stale metadata so
    // re-enrolment is treated as fresh.
    _logger.info('${plan.id} not in routine — clearing cached metadata');
    await SpecialPlanStartedAtStore.clear(plan.id);
    return;
  }

  // Keep the cached anchor in sync with server truth. We store the plan's
  // day-1 anchor (effectiveStartDate = startDate ?? startedAt) so that late
  // joiners see the correct day-N notification (e.g. "Day 6" content), not
  // Day 1 from their enrollment time.
  final anchor = plan.effectiveStartDate;
  final cached = SpecialPlanStartedAtStore.getStartedAt(plan.id);
  if (cached?.toIso8601String() != anchor.toIso8601String()) {
    _logger.info(
      '[ENROLL-NOTIF-SP] ${plan.id} anchor changed — updating cache '
      '(cached=${cached?.toIso8601String()}, '
      'anchor=${anchor.toIso8601String()}, '
      'startDate=${plan.startDate?.toIso8601String()}, '
      'startedAt=${plan.startedAt.toIso8601String()})',
    );
    await SpecialPlanStartedAtStore.setStartedAt(plan.id, anchor);
  }

  // Find the matching routine block to use its scheduled time.
  final matchingBlock = routineBlocks.firstWhere(
    (block) => block.items.any(
      (item) => item.id == plan.id && item.type == RoutineItemType.plan,
    ),
  );

  // Reschedule is idempotent: cancels prior IDs first, then rebuilds the
  // future one-shot series. Survives reinstall and re-login.
  _logger.info(
    '[ENROLL-NOTIF-SP] bootstrap ${plan.id} — reschedule with '
    'block=${matchingBlock.time.hour}:${matchingBlock.time.minute.toString().padLeft(2, '0')}',
  );
  try {
    await ref.read(routineNotificationServiceProvider).rescheduleSpecialPlanSeries(
      planId: plan.id,
      planTitle: plan.title,
      planImageUrl: plan.imageUrl,
      blockHour: matchingBlock.time.hour,
      blockMinute: matchingBlock.time.minute,
    );
  } catch (e, st) {
    _logger.error('[ENROLL-NOTIF-SP] reschedule failed for ${plan.id}', e, st);
  }
}
