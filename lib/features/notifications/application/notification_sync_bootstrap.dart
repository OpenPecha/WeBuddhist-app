import 'package:flutter_pecha/core/storage/plan_metadata_store.dart';
import 'package:flutter_pecha/core/storage/special_plan_started_at_store.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('NotificationSyncBootstrap');

/// Eagerly-instantiated provider that:
///   1. Mirrors server-truth plan metadata (`effectiveStartDate`, `totalDays`)
///      into [PlanMetadataStore] and [SpecialPlanStartedAtStore] whenever
///      [userPlansFutureProvider] resolves.
///   2. Delegates full reconciliation to [NotificationSyncEngine].
///
/// Two guards prevent noisy startup failures:
///   * The user-plans listener is only attached **after** auth has settled
///     into a logged-in state. Mounting it earlier triggers a 403 (plus a
///     `LateInitializationError` for the Auth0 field) on every cold start.
///   * `_syncMetadata` waits for [RoutineNotifier.whenLoaded] before reading
///     `routineProvider.state.blocks`. Otherwise the Hive load races with
///     the API response and we'd skip the metadata reconciliation pass
///     (leaving stale entries for plans the user already removed).
///
/// Replaces the legacy pair `planNotificationBootstrapProvider` +
/// `specialPlanBootstrapProvider`.
final notificationSyncBootstrapProvider = Provider<void>((ref) {
  var plansListenerAttached = false;

  ref.listen<AuthState>(
    authProvider,
    (_, next) {
      if (next.isLoading) return;
      if (!next.isLoggedIn) return;
      if (plansListenerAttached) return;
      plansListenerAttached = true;
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] auth ready (logged in) — attaching user-plans listener',
      );
      _attachUserPlansListener(ref);
    },
    fireImmediately: true,
  );
});

void _attachUserPlansListener(Ref ref) {
  ref.listen<AsyncValue<dynamic>>(userPlansFutureProvider, (_, next) {
    next.whenData((either) {
      either.fold(
        (failure) => _logger.warning(
          '[NOTIFICATION_NEW_FLOW] userPlans fetch failed: $failure',
        ),
        (response) async {
          await ref.read(routineProvider.notifier).whenLoaded;
          final routineBlocks = ref.read(routineProvider).blocks;
          await _syncMetadata(response.userPlans, routineBlocks);
          await ref.read(notificationSyncEngineProvider).sync(
                trigger: SyncTrigger.userPlansRefreshed,
              );
        },
      );
    });
  });
}

/// Writes plan metadata to the synchronous stores so the engine's pure
/// compute functions can read it without awaiting.
///
/// - For plans in the routine: cache (or refresh) the anchor + totalDays.
/// - For plans NOT in the routine: clear cached metadata so a re-add starts
///   fresh, matching the legacy bootstrap behaviour.
Future<void> _syncMetadata(
  List<UserPlansModel> plans,
  List<RoutineBlock> routineBlocks,
) async {
  for (final plan in plans) {
    final inRoutine = routineBlocks.any(
      (block) => block.items.any(
        (item) => item.id == plan.id && item.type == RoutineItemType.plan,
      ),
    );
    if (!inRoutine) {
      if (isSpecialPlan(plan.id)) {
        await SpecialPlanStartedAtStore.clear(plan.id);
      }
      await PlanMetadataStore.clear(plan.id);
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] _syncMetadata cleared ${plan.id} (not in routine)',
      );
      continue;
    }
    final anchor = plan.effectiveStartDate;
    await PlanMetadataStore.setMetadata(
      plan.id,
      effectiveStartDate: anchor,
      totalDays: plan.totalDays,
    );
    if (isSpecialPlan(plan.id)) {
      await SpecialPlanStartedAtStore.setStartedAt(plan.id, anchor);
    }
  }
}
