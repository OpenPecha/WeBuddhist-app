import 'package:flutter_pecha/core/storage/plan_metadata_store.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('PlanNotificationBootstrap');

/// Eagerly-instantiated provider that keeps [PlanMetadataStore] and the OS
/// notification schedule in sync with the server's plan list.
///
/// Fires whenever [userPlansFutureProvider] resolves. For each non-special plan:
///   - If the plan is **not** in the local routine → clears cached metadata.
///   - If the plan **is** in the routine → updates metadata if stale, then
///     reschedules the duration-based one-shot series (idempotent).
///
/// Special plans (e.g. ITCC) are handled by [specialPlanBootstrapProvider].
final planNotificationBootstrapProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<dynamic>>(userPlansFutureProvider, (_, next) {
    next.whenData((either) {
      either.fold(
        (failure) => _logger.warning('[ENROLL-NOTIF] userPlans fetch failed: $failure'),
        (response) async {
          for (final plan in response.userPlans) {
            if (!isSpecialPlan(plan.id)) await _bootstrap(ref, plan);
          }
        },
      );
    });
  });
});

Future<void> _bootstrap(Ref ref, UserPlansModel plan) async {
  // Determine whether the plan is in the user's current local routine.
  final routineBlocks = ref.read(routineProvider).blocks;

  // Guard against a timing window where userPlansFutureProvider resolves
  // before routineProvider has loaded its Hive data. An empty routine is
  // ambiguous (might mean "not yet loaded"), so skip the cleanup to avoid
  // incorrectly wiping metadata; the next bootstrap fire will catch up.
  if (routineBlocks.isEmpty) return;

  final matchingBlockOrNull = routineBlocks.cast<RoutineBlock?>().firstWhere(
    (block) => block!.items.any(
      (item) => item.id == plan.id && item.type == RoutineItemType.plan,
    ),
    orElse: () => null,
  );

  if (matchingBlockOrNull == null) {
    // Plan was removed from the routine — clear stale metadata so
    // re-enrolment is treated as fresh.
    _logger.info('[ENROLL-NOTIF] ${plan.id} not in routine — clearing cached metadata');
    await PlanMetadataStore.clear(plan.id);
    return;
  }

  // Keep the cached metadata in sync with server truth.
  final anchor = plan.effectiveStartDate;
  final cached = PlanMetadataStore.getMetadata(plan.id);
  final isUpToDate =
      cached?.effectiveStartDate.toIso8601String() == anchor.toIso8601String() &&
      cached?.totalDays == plan.totalDays;

  if (!isUpToDate) {
    _logger.info(
      '[ENROLL-NOTIF] ${plan.id} metadata changed — updating cache '
      '(cached=${cached?.toString()}, anchor=${anchor.toIso8601String()}, '
      'startDate=${plan.startDate?.toIso8601String()}, startedAt=${plan.startedAt.toIso8601String()})',
    );
    await PlanMetadataStore.setMetadata(
      plan.id,
      effectiveStartDate: anchor,
      totalDays: plan.totalDays,
    );
  }

  // Reschedule is idempotent: cancels prior IDs first, then rebuilds the
  // future one-shot series. Survives reinstall and re-login.
  try {
    await ref.read(routineNotificationServiceProvider).reschedulePlanDurationSeries(
      planId: plan.id,
      planTitle: plan.title,
      planImageUrl: plan.imageUrl,
      blockHour: matchingBlockOrNull.time.hour,
      blockMinute: matchingBlockOrNull.time.minute,
    );
  } catch (e, st) {
    _logger.error('[ENROLL-NOTIF] Failed to reschedule ${plan.id}', e, st);
  }
}
