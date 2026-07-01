import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/config/app_feature_flags.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/storage/plan_metadata_store.dart';
import 'package:flutter_pecha/core/storage/special_plan_started_at_store.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/storage/timer_dismiss_store.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/data/notification_id_scheme.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/notifications/domain/series_plan_schedule.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/user_plans_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart'
    show routineNotificationServiceProvider;
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

final _logger = AppLogger('NotificationSyncEngine');

/// Every notification scheduling decision flows through one of these triggers.
/// Used only for logging — the engine does the same work regardless.
enum SyncTrigger {
  coldStart,
  appResume,
  appLaunch,
  userPlansRefreshed,
  routineSaved,
  blockDeleted,
  planEnrolled,
  planUnenrolled,
  masterToggle,
  routineToggle,
  recitationToggle,
  practiceToggle,
  timerToggle,
  timerDismissed,
  permissionChanged,
  loggedIn,
  loggedOut,
}

/// A single notification the engine has decided should exist.
@immutable
class DesiredNotification {
  /// Stable notification ID. See [NotificationIdScheme].
  final int id;

  /// When this should fire. `null` for daily-repeat (case 4) notifications,
  /// where only `time` matters.
  final tz.TZDateTime? fireAt;

  final String title;
  final String body;
  final String? payload;

  /// Optional Android action button label (special-plan custom days).
  final String? androidActionButtonText;

  /// Source plan item (or null for recitation) — used to load images for the
  /// big-picture style and iOS attachment.
  final RoutineItem? sourceItem;

  /// Enrolled plan id when [sourceItem] is a series routine row. Used for
  /// idempotency stores and special-plan detection on the active plan.
  final String? enrollmentPlanId;

  /// True for recitation: schedule with `matchDateTimeComponents.time`
  /// so it repeats daily forever until cancelled.
  final bool isDailyRepeat;

  /// True for immediate catch-up: deliver via `plugin.show()`, not
  /// `zonedSchedule()`. The engine still records the ID so the diff pass
  /// won't try to cancel a freshly-shown immediate.
  final bool isImmediate;

  /// Case marker for the verification matrix (e.g. "3b", "4", "2a").
  final String debugCase;

  const DesiredNotification({
    required this.id,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.payload,
    required this.sourceItem,
    required this.debugCase,
    this.enrollmentPlanId,
    this.androidActionButtonText,
    this.isDailyRepeat = false,
    this.isImmediate = false,
  });
}

/// Diagnostic result returned by [NotificationSyncEngine.sync].
class NotificationSyncReport {
  final int scheduled;
  final int cancelled;
  final int skipped;
  final int durationMs;
  final Map<String, int> perCase;

  const NotificationSyncReport({
    required this.scheduled,
    required this.cancelled,
    required this.skipped,
    required this.durationMs,
    required this.perCase,
  });

  @override
  String toString() =>
      'scheduled=$scheduled cancelled=$cancelled skipped=$skipped '
      'duration=${durationMs}ms perCase=$perCase';
}

/// Single source of truth for keeping the OS notification schedule in sync
/// with the routine + user-plans + toggle state.
///
/// Every lifecycle event funnels through [sync]. The engine reads the four
/// sources of truth, computes the desired schedule via the pure
/// `_computeForX` helpers, then diffs against `pendingNotificationRequests()`
/// and reconciles via the `flutter_local_notifications` plugin.
class NotificationSyncEngine {
  final RoutineNotificationService _service;
  final NotificationService _notificationService;
  final Ref _ref;

  /// Serialises concurrent triggers so two simultaneous syncs don't race on
  /// the pending-requests diff.
  Future<void> _inFlight = Future.value();

  NotificationSyncEngine({
    required RoutineNotificationService service,
    required NotificationService notificationService,
    required Ref ref,
  })  : _service = service,
        _notificationService = notificationService,
        _ref = ref;

  FlutterLocalNotificationsPlugin get _plugin =>
      _notificationService.notificationsPlugin;

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// The queued-but-not-yet-started sync, if any. A sync that has not
  /// started observes every state change made before `sync()` was called,
  /// so additional triggers can share its result instead of queueing
  /// another full pass: N back-to-back triggers collapse into the running
  /// pass plus exactly one trailing pass.
  Future<NotificationSyncReport>? _queued;

  Future<NotificationSyncReport> sync({required SyncTrigger trigger}) {
    final queued = _queued;
    if (queued != null) {
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} '
        'coalesced into already-queued sync',
      );
      return queued;
    }

    final completer = Completer<NotificationSyncReport>();
    _queued = completer.future;
    final previous = _inFlight;
    _inFlight = completer.future.then<void>((_) {}, onError: (_) {});

    unawaited(() async {
      try {
        await previous;
      } catch (_) {}
      // Starting now — triggers arriving from here on must queue a fresh
      // pass so they observe state written after this point.
      _queued = null;
      try {
        completer.complete(await _runSync(trigger));
      } catch (e, st) {
        completer.completeError(e, st);
      }
    }());

    return completer.future;
  }

  // ─── Engine core ────────────────────────────────────────────────────────────

  Future<NotificationSyncReport> _runSync(SyncTrigger trigger) async {
    final stopwatch = Stopwatch()..start();
    final perCase = <String, int>{};
    void bumpCase(String c) =>
        perCase.update(c, (v) => v + 1, ifAbsent: () => 1);

    if (!_notificationService.isInitialized) {
      _logger.warning(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} skip=service-not-ready',
      );
      return NotificationSyncReport(
        scheduled: 0,
        cancelled: 0,
        skipped: 0,
        durationMs: stopwatch.elapsedMilliseconds,
        perCase: perCase,
      );
    }

    // Auth gate: while auth is still restoring we know nothing — touching the
    // schedule could wipe a valid one. The bootstrap re-triggers a sync as
    // soon as auth settles, so skipping here loses nothing.
    final auth = _ref.read(authProvider);
    if (auth.isLoading) {
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} skip=auth-loading',
      );
      return NotificationSyncReport(
        scheduled: 0,
        cancelled: 0,
        skipped: 0,
        durationMs: stopwatch.elapsedMilliseconds,
        perCase: perCase,
      );
    }
    // Guests cannot have routines, so for scheduling purposes a guest
    // session is signed-out: desired set stays empty and any leftover
    // pending notifications (e.g. from a previous account) get cancelled.
    final loggedIn = auth.isLoggedIn && !auth.isGuest;

    // Routine gate: a failed Hive load must read as "unknown", not "empty" —
    // otherwise the cancel pass would wipe the schedule of a user who still
    // has a routine.
    final routineNotifier = _ref.read(routineProvider.notifier);
    if (routineNotifier.loadFailed) {
      _logger.warning(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} skip=routine-load-failed',
      );
      return NotificationSyncReport(
        scheduled: 0,
        cancelled: 0,
        skipped: 0,
        durationMs: stopwatch.elapsedMilliseconds,
        perCase: perCase,
      );
    }

    final togglePrefs = await SharedPreferences.getInstance();
    final masterOn = togglePrefs.getBool(StorageKeys.notificationMasterEnabled) ?? true;
    final routineOn = togglePrefs.getBool(StorageKeys.notificationRoutineEnabled) ?? true;
    final recitationOn = togglePrefs.getBool(StorageKeys.notificationRecitationEnabled) ?? true;
    final practiceOn = togglePrefs.getBool(StorageKeys.notificationPracticeEnabled) ?? true;
    final timerOn = togglePrefs.getBool(StorageKeys.notificationTimerEnabled) ?? true;
    final osGranted = await _notificationService.areNotificationsEnabled();

    final routineBlocks = _ref.read(routineProvider).blocks;
    // Only consult the plans provider when this sync might schedule
    // something. Reading it mounts/rebuilds the FutureProvider, and doing
    // that while logged out fires an unauthenticated GET /users/me/plans
    // (403 noise on every logged-out cold start). In the cancel-all branch
    // the desired set is empty and cancellation is already permitted, so
    // plans are irrelevant.
    final mightSchedule = loggedIn && masterOn && osGranted;
    final plansById = mightSchedule ? await _readPlansById() : null;
    final plansResolved = plansById != null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final pending = await _plugin.pendingNotificationRequests();
    final ownedPending =
        pending.where((p) => NotificationIdScheme.isOurs(p.id)).toList();
    // planId → notification ID for every "series handed to OS today" marker.
    final todayMarkerByPlan = <String, int>{
      for (final e in PlanMetadataStore.seriesScheduledIdsOn(today).entries)
        e.value: e.key,
    };

    final desired = <int, DesiredNotification>{};
    final seriesPlansCache = <String, List<UserPlansModel>>{};

    Future<List<UserPlansModel>> seriesPlansFor(String seriesId) async {
      final cached = seriesPlansCache[seriesId];
      if (cached != null) return cached;
      final fetched = await _fetchPlansForSeries(seriesId);
      seriesPlansCache[seriesId] = fetched;
      return fetched;
    }

    if (!loggedIn || !masterOn || !osGranted) {
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} loggedIn=$loggedIn '
        'masterOn=$masterOn osGranted=$osGranted -> cancel-all (empty desired)',
      );
      if (!loggedIn) bumpCase('logged-out');
      if (!masterOn) bumpCase('5a');
    } else {
      if (!plansResolved) {
        _logger.warning(
          '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} userPlans state '
          'unknown (offline / loading / failure) — falling back to '
          'PlanMetadataStore and skipping cancel pass to avoid wiping a '
          'valid schedule',
        );
      }
      for (final block in routineBlocks) {
        if (block.items.isEmpty || !block.notificationEnabled) continue;
        // A block may in principle hold both kinds of items — handle each by
        // its own type instead of branching on the first item only.
        final hasRecitation =
            block.items.any((i) => i.type == RoutineItemType.recitation);
        if (hasRecitation) {
          final entries = computeForRecitationBlock(
            block,
            now,
            masterOn: masterOn,
            recitationOn: recitationOn,
          );
          for (final e in entries) {
            desired[e.id] = e;
            bumpCase(e.debugCase);
          }
        }
        final hasAccumulator =
            block.items.any((i) => i.type == RoutineItemType.accumulator);
        if (hasAccumulator) {
          final entries = computeForAccumulatorBlock(
            block,
            now,
            masterOn: masterOn,
            practiceOn: practiceOn,
          );
          for (final e in entries) {
            desired[e.id] = e;
            bumpCase(e.debugCase);
          }
        }
        final hasTimer =
            block.items.any((i) => i.type == RoutineItemType.timer);
        if (hasTimer) {
          final entries = computeForTimerBlock(
            block,
            now,
            masterOn: masterOn,
            timerOn: timerOn,
            isDismissedToday: (id) =>
                TimerDismissStore.isDismissedTodayFrom(togglePrefs, id),
          );
          for (final e in entries) {
            desired[e.id] = e;
            bumpCase(e.debugCase);
          }
        }
        {
          // Plan items — every plan item produces its own desired notifications.
          for (final item in block.items.where((i) => i.type == RoutineItemType.series)) {
            final isSeriesItem = plansById != null
                ? isSeriesRoutineItem(item.id, plansById)
                : item.currentPlanId != null ||
                    PlanMetadataStore.getMetadata(item.id) == null;
            if (isSeriesItem) {
              var seriesPlans = await seriesPlansFor(item.id);
              if (seriesPlans.isEmpty &&
                  item.currentPlanId != null &&
                  plansById != null) {
                final current = plansById[item.currentPlanId!];
                if (current != null) seriesPlans = [current];
              }
              if (seriesPlans.isEmpty && !plansResolved) {
                final cachedPlanId = item.currentPlanId;
                if (cachedPlanId != null) {
                  final cached = PlanMetadataStore.getMetadata(cachedPlanId);
                  if (cached != null) {
                    seriesPlans = [
                      _synthesizePlanFromMetadata(
                        RoutineItem(
                          id: cachedPlanId,
                          title: item.title,
                          type: RoutineItemType.series,
                        ),
                        cached,
                      ),
                    ];
                  }
                }
              }
              if (seriesPlans.isEmpty) {
                _logger.info(
                  '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} block=${block.id} '
                  'series=${item.id} case=1 action=skip reason="no enrolled plans for series"',
                );
                bumpCase('1');
                continue;
              }
              final entries = computeForSeriesBlock(
                block,
                item,
                seriesPlans,
                now,
                masterOn: masterOn,
                routineOn: routineOn,
                seriesScheduledTodayByOS:
                    todayMarkerByPlan.containsKey(item.id),
              );
              for (final e in entries) {
                desired[e.id] = e;
                bumpCase(e.debugCase);
              }
              continue;
            }

            var plan = plansById?[item.id];
            // Cached-metadata fallback is for the UNKNOWN state only
            // (offline / loading). When the server list resolved and the
            // plan is absent, the user unenrolled — falling back to stale
            // cache here would keep scheduling ghost notifications for a
            // plan they left, even though it still sits in a routine block.
            if (plan == null && !plansResolved) {
              final cached = PlanMetadataStore.getMetadata(item.id);
              if (cached != null) {
                plan = _synthesizePlanFromMetadata(item, cached);
              }
            }
            if (plan == null) {
              final reason = plansResolved
                  ? 'no enrolment / not in userPlans'
                  : 'userPlans not loaded; no cached metadata';
              _logger.info(
                '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} block=${block.id} '
                'plan=${item.id} case=1 action=skip reason="$reason"',
              );
              bumpCase('1');
              continue;
            }
            final entries = computeForPlanBlock(
              block,
              item,
              plan,
              now,
              masterOn: masterOn,
              routineOn: routineOn,
              seriesScheduledTodayByOS:
                  todayMarkerByPlan.containsKey(item.id),
            );
            for (final e in entries) {
              desired[e.id] = e;
              bumpCase(e.debugCase);
            }
          }
        }
      }
    }

    // ── Global cap (iOS allows at most 64 pending requests) ──
    // Daily repeats (one per recitation block) and immediates always survive;
    // dated plan-series entries are capped to the soonest remaining slots so
    // iOS never silently drops the notifications that matter most.
    applyGlobalCap(desired, bumpCase);

    // ── Diff against the pending snapshot taken above ──
    var scheduled = 0;
    var cancelled = 0;
    var skipped = 0;

    // Reverse map (notification ID → planId) for every "series handed to OS
    // today" marker, so cancelling today's pending entry also clears its
    // marker — otherwise a later sync would wrongly assume the OS delivered
    // it and suppress the catch-up immediate.
    final todayMarkerIds = {
      for (final e in todayMarkerByPlan.entries) e.value: e.key,
    };

    // Cancel: anything owned that is no longer desired.
    // We preserve the diagnostic test ID untouched (user explicitly schedules it).
    //
    // When `plansResolved` is false we cannot prove whether a pending plan ID is
    // stale or just unverified, so we skip cancellation entirely. The next
    // successful userPlans refresh re-runs sync with a known enrollment set
    // and reconciles any true orphans then. Master-off, logged-out, and
    // permission-revoked still cancel because their desired sets are
    // intentionally empty.
    final canCancel = plansResolved || !loggedIn || !masterOn || !osGranted;
    for (final p in ownedPending) {
      if (p.id == NotificationIdScheme.kDiagnosticTestId) continue;
      if (desired.containsKey(p.id)) continue;
      // Recitation/chants and mala daily-repeats are routine-derived (never
      // plan-derived), so an orphan is unambiguous even when plans are
      // unresolved — reconcile it regardless of additive-only mode. Only
      // plan-range IDs stay protected until enrollment is known.
      final canCancelThis =
          canCancel || NotificationIdScheme.isRoutineDailyRepeat(p.id);
      if (!canCancelThis) {
        skipped++;
        _logger.info(
          '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} action=skip-cancel '
          'id=${p.id} reason="plans state unknown — additive-only mode"',
        );
        continue;
      }
      try {
        await _plugin.cancel(p.id);
        cancelled++;
        final markerPlanId = todayMarkerIds[p.id];
        if (markerPlanId != null) {
          await PlanMetadataStore.clearSeriesScheduledMarker(markerPlanId);
        }
        _logger.info(
          '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} action=cancel id=${p.id} '
          'reason="not in desired set"',
        );
      } catch (e) {
        _logger.warning('cancel id=${p.id} failed: $e');
      }
    }

    // Schedule: every desired entry is (re-)scheduled unconditionally.
    // zonedSchedule with the same ID atomically replaces the existing request,
    // so this is idempotent — and it is the only way to pick up fire-time
    // changes (block time edits, timezone moves) and to re-register alarms
    // that Android dropped (force-stop), since the plugin's pending list
    // exposes IDs but not fire times.
    final scheduleMode = await _resolveAndroidScheduleMode();
    for (final d in desired.values) {
      if (d.isImmediate) {
        final fired = await _fireImmediate(d, trigger);
        if (fired) {
          scheduled++;
        } else {
          skipped++;
        }
        continue;
      }
      final ok = await _scheduleOne(d, trigger, scheduleMode);
      if (ok) {
        scheduled++;
        // Stamp same-day plan entries so the next sync knows the OS owns
        // today's delivery and the catch-up immediate must stay silent.
        final fireAt = d.fireAt;
        if (!d.isDailyRepeat &&
            d.sourceItem != null &&
            fireAt != null &&
            DateTime(fireAt.year, fireAt.month, fireAt.day) == today) {
          await PlanMetadataStore.markSeriesScheduledOn(
            d.sourceItem!.id,
            today,
            d.id,
          );
        }
      } else {
        skipped++;
      }
    }

    stopwatch.stop();
    _logger.info(
      '[NOTIFICATION_NEW_FLOW] sync done trigger=${trigger.name} '
      'scheduled=$scheduled cancelled=$cancelled skipped=$skipped '
      'duration=${stopwatch.elapsedMilliseconds}ms perCase=$perCase',
    );

    return NotificationSyncReport(
      scheduled: scheduled,
      cancelled: cancelled,
      skipped: skipped,
      durationMs: stopwatch.elapsedMilliseconds,
      perCase: perCase,
    );
  }

  /// Global ceiling on scheduled (non-immediate) requests. iOS keeps only
  /// the soonest-firing 64 pending requests and silently discards the rest;
  /// staying under that with headroom makes the behaviour deterministic on
  /// both platforms. The window slides forward on every sync.
  static const int kMaxTotalScheduled = 60;

  /// Drops the farthest-out dated entries when the desired set exceeds
  /// [kMaxTotalScheduled]. Daily repeats (recitations) and immediates are
  /// never dropped — they are few and time-critical.
  @visibleForTesting
  void applyGlobalCap(
    Map<int, DesiredNotification> desired,
    void Function(String) bumpCase,
  ) {
    final reserved = desired.values
        .where((d) => d.isDailyRepeat || d.isImmediate)
        .length;
    final dated = desired.values
        .where((d) => !d.isDailyRepeat && !d.isImmediate && d.fireAt != null)
        .toList()
      ..sort((a, b) => a.fireAt!.compareTo(b.fireAt!));
    final budget = kMaxTotalScheduled - reserved;
    if (dated.length <= budget) return;
    final overflow = dated.sublist(budget < 0 ? 0 : budget);
    for (final d in overflow) {
      desired.remove(d.id);
      bumpCase('cap-dropped');
    }
    _logger.info(
      '[NOTIFICATION_NEW_FLOW] global cap: dropped ${overflow.length} '
      'far-future entries (reserved=$reserved budget=$budget)',
    );
  }

  /// Exact when the OS permits it; otherwise degrade to inexact so the user
  /// still gets the notification (slightly late) instead of nothing at all.
  /// Always exact-capable on iOS/macOS and Android < 12.
  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    final canExact = await _notificationService.canScheduleExactNotifications();
    if (canExact) return AndroidScheduleMode.exactAllowWhileIdle;
    _logger.warning(
      '[NOTIFICATION_NEW_FLOW] exact alarms not permitted — '
      'scheduling inexact so notifications still fire',
    );
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Returns the server-known plans keyed by id, or `null` if
  /// `userPlansFutureProvider` is not in a resolved success state
  /// (AsyncLoading, AsyncError, or `AsyncData(Left(failure))` — the common
  /// offline outcome since the use case wraps network failures in `Left`).
  ///
  /// Callers MUST treat `null` as "unknown" — not as "empty" — and fall back
  /// to [PlanMetadataStore] or skip cancellation. Conflating the two states
  /// silently wipes every scheduled plan/special-plan notification on the
  /// first sync that runs in the unknown window (e.g. a toggle change while
  /// offline).
  Future<Map<String, UserPlansModel>?> _readPlansById() async {
    try {
      final asyncValue = _ref.read(userPlansFutureProvider);
      final value = asyncValue.valueOrNull;
      if (value == null) return null;
      return value.fold(
        (failure) {
          _logger.warning(
            '[NOTIFICATION_NEW_FLOW] userPlansFutureProvider resolved to '
            'Left($failure) — treating plans state as unknown',
          );
          return null;
        },
        (response) => {for (final p in response.userPlans) p.id: p},
      );
    } catch (e) {
      _logger.warning('readPlansById failed: $e');
      return null;
    }
  }

  /// Fetches enrolled plans for [seriesId] via `GET /users/me/plans?series_id=`.
  Future<List<UserPlansModel>> _fetchPlansForSeries(String seriesId) async {
    try {
      final language = _ref.read(contentLanguageProvider);
      final result = await _ref.read(getUserPlansUseCaseProvider)(
        GetUserPlansParams(language: language, seriesId: seriesId),
      );
      return result.fold(
        (failure) {
          _logger.warning(
            '[NOTIFICATION_NEW_FLOW] fetchPlansForSeries($seriesId) failed: '
            '$failure',
          );
          return <UserPlansModel>[];
        },
        (response) => response.userPlans,
      );
    } catch (e) {
      _logger.warning('fetchPlansForSeries($seriesId) threw: $e');
      return <UserPlansModel>[];
    }
  }

  /// Builds a minimal [UserPlansModel] from locally-cached enrollment
  /// metadata. Only [UserPlansModel.effectiveStartDate] and
  /// [UserPlansModel.totalDays] are consumed by [computeForPlanBlock]; the
  /// other fields are placeholders.
  ///
  /// Used when `userPlansFutureProvider` cannot deliver a Right(response)
  /// (offline / loading) so the schedule survives transient unknown windows.
  UserPlansModel _synthesizePlanFromMetadata(
    RoutineItem item,
    PlanMetadata metadata,
  ) {
    return UserPlansModel(
      id: item.id,
      title: item.title,
      description: '',
      language: '',
      difficultyLevel: null,
      startedAt: metadata.effectiveStartDate,
      totalDays: metadata.totalDays,
      tags: null,
    );
  }

  // ─── Pure compute (testable) ────────────────────────────────────────────────

  /// Computes desired notifications for a single plan item inside [block].
  ///
  /// Returns `[]` when:
  ///   - master or routine toggle is OFF (case 5a / 5b)
  ///   - `now` is past plan end (case 3c)
  ///   - block has no items (defensive)
  ///
  /// Otherwise emits one [DesiredNotification] per future day within the
  /// 60-day lookahead window, plus an optional immediate catch-up entry for
  /// today when block time has already passed (case 3b immediate-catchup).
  ///
  /// [seriesScheduledTodayByOS] must be `true` when today's series
  /// notification was already handed to the OS ahead of its fire time (see
  /// [PlanMetadataStore.wasSeriesScheduledOn]). In that case the OS delivered
  /// it (or will) — emitting a catch-up too would duplicate the notification
  /// the user already received in the background. It only suppresses the
  /// catch-up immediate: a future same-day series entry is always honored,
  /// because a past slot can only become future again through an explicit
  /// user action (block re-added or re-timed) — and a deliberately scheduled
  /// fire must fire.
  @visibleForTesting
  List<DesiredNotification> computeForPlanBlock(
    RoutineBlock block,
    RoutineItem item,
    UserPlansModel plan,
    DateTime now, {
    required bool masterOn,
    required bool routineOn,
    bool seriesScheduledTodayByOS = false,
  }) {
    if (!masterOn) return const [];
    if (!routineOn) return const [];
    if (block.items.isEmpty || !block.notificationEnabled) return const [];

    final entries = <DesiredNotification>[];
    final isSpecial = isSpecialPlan(plan.id);
    final specialEntries = kSpecialPlanNotifications[plan.id];
    final anchorLocal = plan.effectiveStartDate.toLocal();
    final anchorDay = DateTime(anchorLocal.year, anchorLocal.month, anchorLocal.day);
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceAnchor = today.difference(anchorDay).inDays;
    final totalDays = plan.totalDays;
    final planEndDay = anchorDay.add(Duration(days: totalDays - 1));

    // Case 3c — plan already ended.
    if (today.isAfter(planEndDay)) {
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] block=${block.id} plan=${item.id} case=3c past-end '
        'action=skip reason="today=${today.toIso8601String()} > planEnd=${planEndDay.toIso8601String()}"',
      );
      return const [];
    }

    final blockHour = block.time.hour;
    final blockMinute = block.time.minute;

    // Anchor day-1 to block time; use Duration to avoid month/year roll-over bugs.
    final seriesStart = tz.TZDateTime(
      tz.local,
      anchorDay.year,
      anchorDay.month,
      anchorDay.day,
      blockHour,
      blockMinute,
    );
    // Wall-clock twin of seriesStart used for "has today's slot passed?"
    // comparisons against the caller's local `now`. Avoids mixing the
    // wall-clock TZDateTime with `tz.TZDateTime.from(now, ...)` which uses
    // `now`'s instant and goes wrong when `tz.local` ≠ system local
    // (notably in tests where `tz.local = UTC`).
    final seriesStartWall = DateTime(
      anchorDay.year,
      anchorDay.month,
      anchorDay.day,
      blockHour,
      blockMinute,
    );

    final payload = _encodeRoutinePayload(
      routineItemId: item.id,
      planId: plan.id,
    );

    var scheduledCount = 0;

    // Cases 2a/2b/2c — special-plan custom + general fallback.
    // Case 3a — future anchor: schedules-only, no today fire.
    // Case 3b — today + future schedules (no backfill).
    for (var day = 1; day <= totalDays; day++) {
      if (scheduledCount >= RoutineNotificationService.kPlanSeriesMaxScheduledDays) {
        break;
      }
      final fireDate = seriesStart.add(Duration(days: day - 1));
      final fireWall = seriesStartWall.add(Duration(days: day - 1));
      if (!fireWall.isAfter(now)) continue;

      final dayLabel = isSpecial && specialEntries != null && day <= specialEntries.length
          ? '2a'
          : (isSpecial ? '2b' : (today.isBefore(anchorDay) ? '3a' : '3b'));

      String title;
      String body;
      String? buttonText;
      if (isSpecial && specialEntries != null) {
        if (day <= specialEntries.length) {
          final content = specialEntries[day - 1];
          title = content.title;
          body = content.body;
          buttonText = content.buttonText;
        } else if (day <= totalDays) {
          title = item.title;
          body = _planDayBody(item.title, day, totalDays);
        } else {
          // Case 2c — past the total-days cap; never emit.
          continue;
        }
      } else {
        // General plan — gated by feature flag (matches legacy
        // `reschedulePlanDurationSeries` behaviour).
        if (!AppFeatureFlags.kSchedulePlanNotifications) continue;
        title = item.title;
        body = _planDayBody(item.title, day, totalDays);
      }

      final id = isSpecial && specialEntries != null && day <= specialEntries.length
          ? NotificationIdScheme.specialPlanSeriesId(plan.id, day)
          : NotificationIdScheme.planSeriesId(plan.id, day);

      entries.add(DesiredNotification(
        id: id,
        fireAt: fireDate,
        title: title,
        body: body,
        payload: payload,
        sourceItem: item,
        enrollmentPlanId: plan.id,
        androidActionButtonText: buttonText,
        debugCase: dayLabel,
      ));
      scheduledCount++;
    }

    // Case 2c — special plan with totalDays < specialEntries.length: log.
    if (isSpecial &&
        specialEntries != null &&
        totalDays < specialEntries.length) {
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] plan=${item.id} case=2c skip-extra '
        'totalDays=$totalDays customEntries=${specialEntries.length}',
      );
    }

    // Case 3b immediate-catch-up:
    // If today's block time has already passed and today's notification
    // hasn't been shown, fire immediately. Idempotency is enforced by the
    // shown-flag stores (see [_fireImmediate]). When the OS already owned
    // today's delivery (notification was scheduled before its fire time and
    // never cancelled), stay silent — the user already got it in the
    // background; one notification per plan per day, from either path.
    if (!today.isBefore(anchorDay) && daysSinceAnchor < totalDays) {
      final todayFireWall = seriesStartWall.add(Duration(days: daysSinceAnchor));
      final isPast = !todayFireWall.isAfter(now);
      final dayNumber = daysSinceAnchor + 1;
      if (isPast && seriesScheduledTodayByOS) {
        _logger.info(
          '[NOTIFICATION_NEW_FLOW] block=${block.id} plan=${item.id} '
          'case=3b action=skip-catchup reason="today\'s series notification '
          'was scheduled with the OS — background delivery owns today"',
        );
        return entries;
      }
      if (isPast) {
        String title;
        String body;
        String? buttonText;
        int id;
        if (isSpecial && specialEntries != null && dayNumber <= specialEntries.length) {
          final content = specialEntries[dayNumber - 1];
          title = content.title;
          body = content.body;
          buttonText = content.buttonText;
          id = NotificationIdScheme.specialPlanOneShotId(dayNumber);
        } else if (AppFeatureFlags.kSchedulePlanNotifications || isSpecial) {
          title = plan.title;
          body = _planDayBody(plan.title, dayNumber, totalDays);
          id = NotificationIdScheme.planOneShotId(plan.id);
        } else {
          // Feature flag off and not a special plan → nothing to fire.
          return entries;
        }

        entries.add(DesiredNotification(
          id: id,
          fireAt: null,
          title: title,
          body: body,
          payload: payload,
          sourceItem: item,
          enrollmentPlanId: plan.id,
          androidActionButtonText: buttonText,
          isImmediate: true,
          debugCase: '3b immediate-catchup',
        ));
      }
    }

    return entries;
  }

  /// Computes desired notifications for a **series** routine item.
  ///
  /// For each upcoming calendar day, resolves which enrolled plan in the
  /// series is active on that date, then schedules a notification for that
  /// plan's day number at [block]'s time.
  @visibleForTesting
  List<DesiredNotification> computeForSeriesBlock(
    RoutineBlock block,
    RoutineItem seriesItem,
    List<UserPlansModel> seriesPlans,
    DateTime now, {
    required bool masterOn,
    required bool routineOn,
    bool seriesScheduledTodayByOS = false,
  }) {
    if (!masterOn) return const [];
    if (!routineOn) return const [];
    if (block.items.isEmpty || !block.notificationEnabled) return const [];
    if (seriesPlans.isEmpty) return const [];

    final entries = <DesiredNotification>[];
    final today = DateTime(now.year, now.month, now.day);
    final blockHour = block.time.hour;
    final blockMinute = block.time.minute;

    final slots = buildUpcomingSeriesSlots(
      enrolledPlans: seriesPlans,
      now: now,
      maxSlots: RoutineNotificationService.kPlanSeriesMaxScheduledDays,
      preferredPlanIdForToday: seriesItem.currentPlanId,
    );

    for (final slot in slots) {
      final plan = slot.plan;
      final day = slot.dayNumber;
      final cal = slot.calendarDate;
      final fireWall = DateTime(cal.year, cal.month, cal.day, blockHour, blockMinute);
      if (!fireWall.isAfter(now)) continue;

      final isSpecial = isSpecialPlan(plan.id);
      final specialEntries = kSpecialPlanNotifications[plan.id];
      final dayLabel = isSpecial && specialEntries != null && day <= specialEntries.length
          ? '2a'
          : (isSpecial ? '2b' : (cal.isAfter(today) ? '3a' : '3b'));

      String title;
      String body;
      String? buttonText;
      if (isSpecial && specialEntries != null && day <= specialEntries.length) {
        final content = specialEntries[day - 1];
        title = content.title;
        body = content.body;
        buttonText = content.buttonText;
      } else {
        if (!AppFeatureFlags.kSchedulePlanNotifications && !isSpecial) continue;
        title = plan.title;
        body = _planDayBody(plan.title, day, plan.totalDays);
      }

      final id = isSpecial && specialEntries != null && day <= specialEntries.length
          ? NotificationIdScheme.specialPlanSeriesId(plan.id, day)
          : NotificationIdScheme.planSeriesId(plan.id, day);

      final fireDate = tz.TZDateTime(
        tz.local,
        cal.year,
        cal.month,
        cal.day,
        blockHour,
        blockMinute,
      );

      entries.add(DesiredNotification(
        id: id,
        fireAt: fireDate,
        title: title,
        body: body,
        payload: _encodeRoutinePayload(
          routineItemId: seriesItem.id,
          planId: plan.id,
        ),
        sourceItem: seriesItem,
        enrollmentPlanId: plan.id,
        androidActionButtonText: buttonText,
        debugCase: dayLabel,
      ));
    }

    // Immediate catch-up for today's active plan.
    final todayPlan = resolveActivePlanForDate(
      seriesPlans,
      today,
      preferredPlanId: seriesItem.currentPlanId,
    );
    if (todayPlan != null) {
      final dayNumber = PlanUtils.dayNumberFor(
        todayPlan.effectiveStartDate,
        today,
        todayPlan.totalDays,
      );
      if (dayNumber >= 1) {
        final todayFireWall = DateTime(
          today.year,
          today.month,
          today.day,
          blockHour,
          blockMinute,
        );
        final isPast = !todayFireWall.isAfter(now);
        if (isPast && seriesScheduledTodayByOS) {
          _logger.info(
            '[NOTIFICATION_NEW_FLOW] block=${block.id} series=${seriesItem.id} '
            'plan=${todayPlan.id} case=3b action=skip-catchup reason="today\'s '
            'notification was scheduled with the OS"',
          );
          return entries;
        }
        if (isPast) {
          final isSpecial = isSpecialPlan(todayPlan.id);
          final specialEntries = kSpecialPlanNotifications[todayPlan.id];
          String title;
          String body;
          String? buttonText;
          int id;
          if (isSpecial &&
              specialEntries != null &&
              dayNumber <= specialEntries.length) {
            final content = specialEntries[dayNumber - 1];
            title = content.title;
            body = content.body;
            buttonText = content.buttonText;
            id = NotificationIdScheme.specialPlanOneShotId(dayNumber);
          } else if (AppFeatureFlags.kSchedulePlanNotifications || isSpecial) {
            title = todayPlan.title;
            body = _planDayBody(todayPlan.title, dayNumber, todayPlan.totalDays);
            id = NotificationIdScheme.planOneShotId(todayPlan.id);
          } else {
            return entries;
          }

          entries.add(DesiredNotification(
            id: id,
            fireAt: null,
            title: title,
            body: body,
            payload: _encodeRoutinePayload(
              routineItemId: seriesItem.id,
              planId: todayPlan.id,
            ),
            sourceItem: seriesItem,
            enrollmentPlanId: todayPlan.id,
            androidActionButtonText: buttonText,
            isImmediate: true,
            debugCase: '3b immediate-catchup',
          ));
        }
      }
    }

    return entries;
  }

  /// Computes the single daily-repeat [DesiredNotification] for a recitation
  /// block (case 4). Returns `[]` when toggles are off or block is empty.
  @visibleForTesting
  List<DesiredNotification> computeForRecitationBlock(
    RoutineBlock block,
    DateTime now, {
    required bool masterOn,
    required bool recitationOn,
  }) {
    if (!masterOn) return const [];
    if (!recitationOn) return const [];
    if (block.items.isEmpty || !block.notificationEnabled) return const [];

    final firstItem = block.items.first;
    final nowTz = tz.TZDateTime.from(now, tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      nowTz.year,
      nowTz.month,
      nowTz.day,
      block.time.hour,
      block.time.minute,
    );
    if (scheduledDate.isBefore(nowTz)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final payload = jsonEncode({
      'itemId': firstItem.id,
      'itemType': firstItem.type.name,
    });

    return [
      DesiredNotification(
        id: block.notificationId,
        fireAt: scheduledDate,
        title: firstItem.title,
        body: _recitationBody(block),
        payload: payload,
        sourceItem: firstItem,
        isDailyRepeat: true,
        debugCase: '4 daily-repeat',
      ),
    ];
  }

  /// Computes the single daily-repeat [DesiredNotification] for a mala
  /// (accumulator) block. Mirrors [computeForRecitationBlock] but is gated by
  /// the Practice sub-toggle and uses [NotificationIdScheme.accumulatorBlockId]
  /// so it never collides with a recitation daily-repeat in the same block.
  ///
  /// The title is the mala's own name (the user's stored preset title) and the
  /// body is a consistent default. Returns `[]` when toggles are off or the
  /// block holds no accumulator items.
  @visibleForTesting
  List<DesiredNotification> computeForAccumulatorBlock(
    RoutineBlock block,
    DateTime now, {
    required bool masterOn,
    required bool practiceOn,
  }) {
    if (!masterOn) return const [];
    if (!practiceOn) return const [];
    if (block.items.isEmpty || !block.notificationEnabled) return const [];

    final accumulators =
        block.items.where((i) => i.type == RoutineItemType.accumulator).toList();
    if (accumulators.isEmpty) return const [];

    final firstItem = accumulators.first;
    final nowTz = tz.TZDateTime.from(now, tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      nowTz.year,
      nowTz.month,
      nowTz.day,
      block.time.hour,
      block.time.minute,
    );
    if (scheduledDate.isBefore(nowTz)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final payload = jsonEncode({
      'itemId': firstItem.id,
      'itemType': firstItem.type.name,
    });

    return [
      DesiredNotification(
        id: NotificationIdScheme.accumulatorBlockId(block.notificationId),
        fireAt: scheduledDate,
        title: firstItem.title,
        body: _accumulatorBody(accumulators),
        payload: payload,
        sourceItem: firstItem,
        isDailyRepeat: true,
        debugCase: '4 daily-repeat-mala',
      ),
    ];
  }

  /// Computes the two daily-repeat [DesiredNotification]s for a timer block:
  /// a "started" reminder at block time and a "timer up" reminder at block
  /// time + the timer's duration. Both mirror the recitation/mala daily-repeat
  /// mechanism (plain [DesiredNotification]s scheduled with
  /// `matchDateTimeComponents.time`) — there is deliberately no live foreground
  /// countdown. Gated by the Timer sub-toggle. Distinct
  /// [NotificationIdScheme.timerStartId] / [NotificationIdScheme.timerEndId]
  /// ranges keep them from colliding with any recitation/mala daily-repeat in
  /// the same block.
  ///
  /// Returns `[]` when toggles are off, the block is empty, or it holds no
  /// timer item with a positive [RoutineItem.durationMs].
  @visibleForTesting
  List<DesiredNotification> computeForTimerBlock(
    RoutineBlock block,
    DateTime now, {
    required bool masterOn,
    required bool timerOn,
    bool Function(String itemId)? isDismissedToday,
  }) {
    if (!masterOn) return const [];
    if (!timerOn) return const [];
    if (block.items.isEmpty || !block.notificationEnabled) return const [];

    final timers = block.items
        .where((i) =>
            i.type == RoutineItemType.timer && (i.durationMs ?? 0) > 0)
        .toList();
    if (timers.isEmpty) return const [];
    final timer = timers.first;
    final durationMs = timer.durationMs!;

    // When the user dismissed today's occurrence, skip it: both reminders roll
    // to tomorrow's occurrence (the daily-repeat resumes then). The marker is
    // date-scoped, so tomorrow's sync computes normally.
    final skipToday = isDismissedToday?.call(timer.id) ?? false;

    final nowTz = tz.TZDateTime.from(now, tz.local);
    final title = timer.title.isNotEmpty ? timer.title : 'Timer';
    // Both reminders deep-link to the timer screen, which syncs its remaining
    // time from the block's scheduled time-of-day + duration against the wall
    // clock (no backend, no foreground service): open mid-way → correct time
    // left; open after it ended → finished. `durationMs` and `startMinuteOfDay`
    // are embedded so the tap works without re-resolving the routine item
    // (which may have lost its durationMs on a server round-trip, or not be
    // loaded yet on a cold start).
    final payload = jsonEncode({
      'itemId': timer.id,
      'itemType': timer.type.name,
      'durationMs': durationMs,
      'startMinuteOfDay': block.time.hour * 60 + block.time.minute,
    });

    // Next occurrence of block time (roll to tomorrow if already past, or if
    // today is dismissed).
    var startAt = tz.TZDateTime(
      tz.local,
      nowTz.year,
      nowTz.month,
      nowTz.day,
      block.time.hour,
      block.time.minute,
    );
    if (startAt.isBefore(nowTz) || skipToday) {
      startAt = startAt.add(const Duration(days: 1));
    }

    // The "timer up" fire is start + duration. Computed independently (rolled
    // to its own next occurrence) so each daily-repeat matches its own
    // time-of-day component correctly.
    var endAt = tz.TZDateTime(
      tz.local,
      nowTz.year,
      nowTz.month,
      nowTz.day,
      block.time.hour,
      block.time.minute,
    ).add(Duration(milliseconds: durationMs));
    if (endAt.isBefore(nowTz) || skipToday) {
      endAt = endAt.add(const Duration(days: 1));
    }

    return [
      DesiredNotification(
        id: NotificationIdScheme.timerStartId(block.notificationId),
        fireAt: startAt,
        title: title,
        body: _timerStartBody(durationMs),
        payload: payload,
        sourceItem: timer,
        isDailyRepeat: true,
        debugCase: '4 daily-repeat-timer-start',
      ),
      DesiredNotification(
        id: NotificationIdScheme.timerEndId(block.notificationId),
        fireAt: endAt,
        title: title,
        body: 'Your timer is up.',
        payload: payload,
        sourceItem: timer,
        isDailyRepeat: true,
        debugCase: '4 daily-repeat-timer-end',
      ),
    ];
  }

  // ─── Scheduling primitives ──────────────────────────────────────────────────

  Future<bool> _scheduleOne(
    DesiredNotification d,
    SyncTrigger trigger,
    AndroidScheduleMode scheduleMode,
  ) async {
    final fireAt = d.fireAt;
    if (fireAt == null) return false;
    try {
      // Build only the platform-relevant pieces — each unused style is a
      // wasted image download/disk hit per notification.
      final isApple = Platform.isIOS || Platform.isMacOS;
      final androidStyle = isApple
          ? null
          : await _service.buildBigPictureStyle(
              d.sourceItem,
              overrideTitle: d.title,
              overrideBody: d.body,
            );
      final largeIcon =
          isApple ? null : await _service.getLargeIcon(d.sourceItem);
      final iosDetails = isApple
          ? await _service.buildIOSNotificationDetails(d.sourceItem)
          : null;

      final details = NotificationChannels.routineBlockDetails(
        styleInformation: androidStyle,
        largeIcon: largeIcon,
        iOSDetails: iosDetails,
        androidActionButtonText: d.androidActionButtonText,
      );

      Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
            d.id,
            d.title,
            d.body,
            fireAt,
            details,
            androidScheduleMode: mode,
            matchDateTimeComponents:
                d.isDailyRepeat ? DateTimeComponents.time : null,
            payload: d.payload,
          );

      try {
        await schedule(scheduleMode);
      } on PlatformException catch (e) {
        // Permission can be revoked between the per-sync check and this call
        // (or the check itself can be unreliable on some OEMs). Degrade to
        // inexact rather than dropping the notification entirely.
        if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
          _logger.warning(
            '[NOTIFICATION_NEW_FLOW] exact schedule failed for id=${d.id} '
            '(${e.code}) — retrying inexact',
          );
          await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
        } else {
          rethrow;
        }
      }
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} action=schedule '
        'id=${d.id} case=${d.debugCase} fireAt=${fireAt.toIso8601String()}',
      );
      return true;
    } catch (e, st) {
      _logger.error('schedule id=${d.id} failed', e, st);
      return false;
    }
  }

  /// Fires an immediate (catch-up) notification, gated by the shown-flag
  /// stores so a relaunch on the same day does not double-fire.
  Future<bool> _fireImmediate(DesiredNotification d, SyncTrigger trigger) async {
    final item = d.sourceItem;
    if (item == null) return false;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final planId = d.enrollmentPlanId ?? item.id;

    final isSpecial = isSpecialPlan(planId);
    if (isSpecial) {
      if (SpecialPlanStartedAtStore.wasShownOn(planId, todayDate)) {
        _logger.info(
          '[NOTIFICATION_NEW_FLOW] action=skip case=${d.debugCase} id=${d.id} '
          'reason="special-plan already shown today"',
        );
        return false;
      }
    } else {
      if (PlanMetadataStore.wasImmediateShownOn(planId, todayDate)) {
        _logger.info(
          '[NOTIFICATION_NEW_FLOW] action=skip case=${d.debugCase} id=${d.id} '
          'reason="plan already shown today"',
        );
        return false;
      }
    }

    try {
      final isApple = Platform.isIOS || Platform.isMacOS;
      final androidStyle = isApple
          ? null
          : await _service.buildBigPictureStyle(
              item,
              overrideTitle: d.title,
              overrideBody: d.body,
            );
      final largeIcon = isApple ? null : await _service.getLargeIcon(item);
      final iosDetails =
          isApple ? await _service.buildIOSNotificationDetails(item) : null;

      await _plugin.show(
        d.id,
        d.title,
        d.body,
        NotificationChannels.routineBlockDetails(
          styleInformation: androidStyle,
          largeIcon: largeIcon,
          iOSDetails: iosDetails,
          androidActionButtonText: d.androidActionButtonText,
        ),
        payload: d.payload,
      );
      if (isSpecial) {
        await SpecialPlanStartedAtStore.markShownOn(planId, todayDate);
      } else {
        await PlanMetadataStore.markImmediateShownOn(planId, todayDate);
      }
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} action=schedule-immediate '
        'id=${d.id} case=${d.debugCase}',
      );
      return true;
    } catch (e, st) {
      _logger.error('immediate id=${d.id} failed', e, st);
      return false;
    }
  }

  // ─── Body templates ─────────────────────────────────────────────────────────

  String _planDayBody(String planTitle, int day, int totalDays) =>
      'Day $day of $totalDays — check out $planTitle.';

  String _encodeRoutinePayload({
    required String routineItemId,
    required String planId,
  }) =>
      jsonEncode({
        'itemId': routineItemId,
        'itemType': RoutineItemType.series.name,
        'planId': planId,
      });

  String _recitationBody(RoutineBlock block) {
    if (block.items.isEmpty) return 'Check your daily routine';
    final firstItem = block.items.first.title;
    final remaining = block.items.length - 1;
    if (remaining == 1) return '$firstItem and 1 other';
    if (remaining > 1) return '$firstItem and $remaining others';
    return firstItem;
  }

  /// Consistent default body for a mala (accumulator) reminder. The title
  /// already carries the mala's name, so the body stays generic.
  String _accumulatorBody(List<RoutineItem> items) {
    final remaining = items.length - 1;
    if (remaining == 1) return 'Time for your mala practice and 1 more';
    if (remaining > 1) return 'Time for your mala practice and $remaining more';
    return 'Time for your mala practice';
  }

  /// "Started now" body for a timer reminder. Formats [durationMs] as minutes,
  /// promoting to hours when ≥ 60 minutes (e.g. "30 minutes", "1 hour",
  /// "1 hour 30 minutes"). Hardcoded English, matching the other body helpers.
  String _timerStartBody(int durationMs) =>
      "You've set a timer for ${_formatTimerDuration(durationMs)}, starting now.";

  String _formatTimerDuration(int durationMs) {
    final totalMinutes = (durationMs / 60000).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final parts = <String>[];
    if (hours > 0) parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');
    }
    if (parts.isEmpty) return '0 minutes';
    return parts.join(' ');
  }
}

/// App-wide engine provider.
final notificationSyncEngineProvider = Provider<NotificationSyncEngine>((ref) {
  return NotificationSyncEngine(
    service: ref.watch(routineNotificationServiceProvider),
    notificationService: NotificationService(),
    ref: ref,
  );
});
