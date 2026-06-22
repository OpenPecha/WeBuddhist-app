import 'dart:async';

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
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
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
  bool? lastSeenLoggedIn;

  ref.listen<AuthState>(
    authProvider,
    (_, next) {
      if (next.isLoading) return;
      // Guests count as isLoggedIn but cannot have routines (the Practice
      // tab blocks them), so for notification purposes a guest session is a
      // signed-out session. This also stops a "logout → continue as guest"
      // session from re-scheduling the previous account's leftover blocks.
      final loggedIn = next.isLoggedIn && !next.isGuest;
      if (loggedIn == lastSeenLoggedIn) return;
      lastSeenLoggedIn = loggedIn;

      if (loggedIn) {
        if (!plansListenerAttached) {
          plansListenerAttached = true;
          _logger.info(
            '[NOTIFICATION_NEW_FLOW] auth ready (logged in) — attaching user-plans listener',
          );
          _attachUserPlansListener(ref);
        }
        unawaited(() async {
          await ref.read(routineProvider.notifier).whenLoaded;
          // 1. Mirror the server routine into local Hive. The engine reads
          //    the LOCAL routine, so without this a fresh install / new
          //    device shows the routine in the UI but schedules nothing.
          await _hydrateRoutineFromServer(ref);
          // 2. Force a fresh plans fetch for THIS login. Without this the
          //    provider can hold the previous session's plans (it only
          //    watches locale), which would rebuild the old schedule — or a
          //    different user's. The refetch resolves → metadata mirror runs
          //    against the hydrated routine → engine syncs: future slots get
          //    scheduled, today's already-passed slot fires one immediate,
          //    missed days are never backfilled.
          ref.invalidate(userPlansFutureProvider);
          // 3. Sync right away as well: if the refetch fails (offline cold
          //    start) the plans listener never fires, but the engine can
          //    still rebuild recitations + cached-metadata plans in
          //    additive-only mode.
          await ref
              .read(notificationSyncEngineProvider)
              .sync(trigger: SyncTrigger.loggedIn);
        }());
      } else {
        // Logged out — manual, token-refresh failure, or account deletion.
        // The desired set is empty while logged out, so one sync cancels
        // every owned pending notification.
        //
        // Deliberately NO userPlansFutureProvider invalidation here: a
        // rebuild while logged out fires an unauthenticated
        // GET /users/me/plans → 403 on every logged-out cold start. Stale
        // data can't leak — the engine never reads the provider while
        // logged out, and the login branch above invalidates before the
        // next session schedules anything.
        _logger.info(
          '[NOTIFICATION_NEW_FLOW] auth signed out — cancelling all notifications',
        );
        unawaited(
          ref
              .read(notificationSyncEngineProvider)
              .sync(trigger: SyncTrigger.loggedOut),
        );
      }
    },
    fireImmediately: true,
  );
});

/// Mirrors the server-truth routine into local Hive on login.
///
/// `Right(null)` means "this user has no routine on the server" — local
/// blocks (e.g. a previous account's leftovers) are cleared so they cannot
/// schedule notifications. A failed fetch keeps the local routine untouched:
/// offline relaunch must not wipe a valid schedule.
Future<void> _hydrateRoutineFromServer(Ref ref) async {
  try {
    final result = await ref.read(getUserRoutineUseCaseProvider)();
    await result.fold(
      (failure) async => _logger.warning(
        '[NOTIFICATION_NEW_FLOW] routine hydration failed: $failure — '
        'keeping local routine',
      ),
      (serverRoutine) async {
        await ref
            .read(routineProvider.notifier)
            .hydrateFromServer(serverRoutine ?? const RoutineData());
        _logger.info(
          '[NOTIFICATION_NEW_FLOW] routine hydrated from server '
          '(${serverRoutine?.blocks.length ?? 0} blocks)',
        );
      },
    );
  } catch (e) {
    _logger.warning(
      '[NOTIFICATION_NEW_FLOW] routine hydration threw: $e — keeping local routine',
    );
  }
}

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
  // Drop cached metadata for plans the user is no longer enrolled in
  // (unenrolled on this or another device). The response is the full,
  // un-paginated enrollment list, so absence here is authoritative.
  // Without this, stale cache could resurrect notifications for a plan
  // that still sits in a routine block after unenrollment.
  final enrolledIds = plans.map((p) => p.id).toSet();
  for (final cachedId in PlanMetadataStore.getAllPlanIds()) {
    if (enrolledIds.contains(cachedId)) continue;
    // Metadata only — per-day delivery records survive the day so a
    // same-day re-enrol cannot duplicate an already-received notification.
    await PlanMetadataStore.clearEnrollmentMetadata(cachedId);
    if (isSpecialPlan(cachedId)) {
      await SpecialPlanStartedAtStore.clearStartedAtOnly(cachedId);
    }
    _logger.info(
      '[NOTIFICATION_NEW_FLOW] _syncMetadata cleared $cachedId (no longer enrolled)',
    );
  }

  for (final plan in plans) {
    final inRoutine = routineBlocks.any(
      (block) => block.items.any(
        (item) => item.id == plan.id && item.type == RoutineItemType.series,
      ),
    );
    if (!inRoutine) {
      // Metadata only — see above. A committed block removal followed by a
      // same-day re-add must not re-fire today's notification.
      if (isSpecialPlan(plan.id)) {
        await SpecialPlanStartedAtStore.clearStartedAtOnly(plan.id);
      }
      await PlanMetadataStore.clearEnrollmentMetadata(plan.id);
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
