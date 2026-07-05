import 'dart:async';

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('NotificationSyncBootstrap');

/// Eagerly-instantiated provider that mirrors the server routine into local
/// Hive on login and delegates full reconciliation to [NotificationSyncEngine].
///
/// The engine schedules only local recitation / mala / timer daily-repeats;
/// plan and series reminders are delivered via server push (FCM), so this
/// bootstrap no longer needs the user-plans listener or the plan-metadata
/// mirror it used to run.
///
/// The auth listener is only acted on **after** auth has settled: mounting
/// work earlier triggers a 403 (plus a `LateInitializationError` for the Auth0
/// field) on every cold start. `_hydrateRoutineFromServer` waits for
/// [RoutineNotifier.whenLoaded] before touching `routineProvider`.
final notificationSyncBootstrapProvider = Provider<void>((ref) {
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
        unawaited(() async {
          await ref.read(routineProvider.notifier).whenLoaded;
          // Mirror the server routine into local Hive. The engine reads the
          // LOCAL routine, so without this a fresh install / new device shows
          // the routine in the UI but schedules nothing.
          await _hydrateRoutineFromServer(ref);
          // Reconcile: future recitation/mala/timer slots get scheduled,
          // today's already-passed slot rolls to tomorrow.
          await ref
              .read(notificationSyncEngineProvider)
              .sync(trigger: SyncTrigger.loggedIn);
        }());
      } else {
        // Logged out — manual, token-refresh failure, or account deletion.
        // The desired set is empty while logged out, so one sync cancels
        // every owned pending notification.
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
    final language = ref.read(contentLanguageProvider);
    final result = await ref.read(getUserRoutineUseCaseProvider)(
      language: language,
    );
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
