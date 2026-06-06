import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/config/app_feature_flags.dart';
import 'package:flutter_pecha/core/storage/plan_metadata_store.dart';
import 'package:flutter_pecha/core/storage/special_plan_started_at_store.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/data/notification_id_scheme.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
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
  permissionChanged,
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

  Future<NotificationSyncReport> sync({required SyncTrigger trigger}) async {
    // Chain onto the in-flight tail so concurrent triggers serialise.
    final completer = Completer<NotificationSyncReport>();
    final previous = _inFlight;
    _inFlight = completer.future.then<void>((_) {}, onError: (_) {});

    try {
      await previous;
    } catch (_) {}

    try {
      final report = await _runSync(trigger);
      completer.complete(report);
      return report;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    }
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

    final togglePrefs = await SharedPreferences.getInstance();
    final masterOn = togglePrefs.getBool(StorageKeys.notificationMasterEnabled) ?? true;
    final routineOn = togglePrefs.getBool(StorageKeys.notificationRoutineEnabled) ?? true;
    final recitationOn = togglePrefs.getBool(StorageKeys.notificationRecitationEnabled) ?? true;
    final osGranted = await _notificationService.areNotificationsEnabled();

    final routineBlocks = _ref.read(routineProvider).blocks;
    final plansById = await _readPlansById();
    final now = DateTime.now();

    final desired = <int, DesiredNotification>{};

    if (!masterOn || !osGranted) {
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} masterOn=$masterOn '
        'osGranted=$osGranted -> cancel-all (empty desired)',
      );
      if (!masterOn) bumpCase('5a');
    } else {
      for (final block in routineBlocks) {
        if (block.items.isEmpty || !block.notificationEnabled) continue;
        final firstItem = block.items.first;
        if (firstItem.type == RoutineItemType.recitation) {
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
        } else {
          // Plan block — every plan item produces its own desired notifications.
          for (final item in block.items.where((i) => i.type == RoutineItemType.plan)) {
            final plan = plansById[item.id];
            if (plan == null) {
              _logger.info(
                '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} block=${block.id} '
                'plan=${item.id} case=1 action=skip reason="no enrolment / not in userPlans"',
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
            );
            for (final e in entries) {
              desired[e.id] = e;
              bumpCase(e.debugCase);
            }
          }
        }
      }
    }

    // ── Diff against currently pending ──
    final pending = await _plugin.pendingNotificationRequests();
    final ownedPending = pending.where((p) => NotificationIdScheme.isOurs(p.id)).toList();
    final ownedPendingIds = ownedPending.map((p) => p.id).toSet();

    var scheduled = 0;
    var cancelled = 0;
    var skipped = 0;

    // Cancel: anything owned that is no longer desired.
    // We preserve the diagnostic test ID untouched (user explicitly schedules it).
    for (final p in ownedPending) {
      if (p.id == NotificationIdScheme.kDiagnosticTestId) continue;
      if (desired.containsKey(p.id)) continue;
      try {
        await _plugin.cancel(p.id);
        cancelled++;
        _logger.info(
          '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} action=cancel id=${p.id} '
          'reason="not in desired set"',
        );
      } catch (e) {
        _logger.warning('cancel id=${p.id} failed: $e');
      }
    }

    // Schedule: anything desired that isn't already pending (or is immediate).
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
      if (ownedPendingIds.contains(d.id)) {
        skipped++;
        continue;
      }
      final ok = await _scheduleOne(d, trigger);
      if (ok) {
        scheduled++;
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

  Future<Map<String, UserPlansModel>> _readPlansById() async {
    try {
      final asyncValue = _ref.read(userPlansFutureProvider);
      final value = asyncValue.valueOrNull;
      if (value == null) return const {};
      return value.fold(
        (_) => const {},
        (response) => {for (final p in response.userPlans) p.id: p},
      );
    } catch (e) {
      _logger.warning('readPlansById failed: $e');
      return const {};
    }
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
  @visibleForTesting
  List<DesiredNotification> computeForPlanBlock(
    RoutineBlock block,
    RoutineItem item,
    UserPlansModel plan,
    DateTime now, {
    required bool masterOn,
    required bool routineOn,
  }) {
    if (!masterOn) return const [];
    if (!routineOn) return const [];
    if (block.items.isEmpty || !block.notificationEnabled) return const [];

    final entries = <DesiredNotification>[];
    final isSpecial = isSpecialPlan(item.id);
    final specialEntries = kSpecialPlanNotifications[item.id];
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

    final payload = jsonEncode({
      'itemId': item.id,
      'itemType': RoutineItemType.plan.name,
    });

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
          ? NotificationIdScheme.specialPlanSeriesId(item.id, day)
          : NotificationIdScheme.planSeriesId(item.id, day);

      entries.add(DesiredNotification(
        id: id,
        fireAt: fireDate,
        title: title,
        body: body,
        payload: payload,
        sourceItem: item,
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
    // shown-flag stores (see [_fireImmediate]).
    if (!today.isBefore(anchorDay) && daysSinceAnchor < totalDays) {
      final todayFireWall = seriesStartWall.add(Duration(days: daysSinceAnchor));
      final isPast = !todayFireWall.isAfter(now);
      final dayNumber = daysSinceAnchor + 1;
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
          title = item.title;
          body = _planDayBody(item.title, dayNumber, totalDays);
          id = NotificationIdScheme.planOneShotId(item.id);
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
          androidActionButtonText: buttonText,
          isImmediate: true,
          debugCase: '3b immediate-catchup',
        ));
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

  // ─── Scheduling primitives ──────────────────────────────────────────────────

  Future<bool> _scheduleOne(DesiredNotification d, SyncTrigger trigger) async {
    final fireAt = d.fireAt;
    if (fireAt == null) return false;
    try {
      final androidStyle = await _service.buildBigPictureStyle(
        d.sourceItem,
        overrideTitle: d.title,
        overrideBody: d.body,
      );
      final iosDetails = await _service.buildIOSNotificationDetails(d.sourceItem);
      final largeIcon = await _service.getLargeIcon(d.sourceItem);

      await _plugin.zonedSchedule(
        d.id,
        d.title,
        d.body,
        fireAt,
        NotificationChannels.routineBlockDetails(
          styleInformation: androidStyle,
          largeIcon: largeIcon,
          iOSDetails: iosDetails,
          androidActionButtonText: d.androidActionButtonText,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
            d.isDailyRepeat ? DateTimeComponents.time : null,
        payload: d.payload,
      );
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

    final isSpecial = isSpecialPlan(item.id);
    if (isSpecial) {
      if (SpecialPlanStartedAtStore.wasShownOn(item.id, todayDate)) {
        _logger.info(
          '[NOTIFICATION_NEW_FLOW] action=skip case=${d.debugCase} id=${d.id} '
          'reason="special-plan already shown today"',
        );
        return false;
      }
    } else {
      if (PlanMetadataStore.wasImmediateShownOn(item.id, todayDate)) {
        _logger.info(
          '[NOTIFICATION_NEW_FLOW] action=skip case=${d.debugCase} id=${d.id} '
          'reason="plan already shown today"',
        );
        return false;
      }
    }

    try {
      final androidStyle = await _service.buildBigPictureStyle(
        item,
        overrideTitle: d.title,
        overrideBody: d.body,
      );
      final iosDetails = await _service.buildIOSNotificationDetails(item);
      final largeIcon = await _service.getLargeIcon(item);

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
        await SpecialPlanStartedAtStore.markShownOn(item.id, todayDate);
      } else {
        await PlanMetadataStore.markImmediateShownOn(item.id, todayDate);
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

  String _recitationBody(RoutineBlock block) {
    if (block.items.isEmpty) return 'Check your daily routine';
    final firstItem = block.items.first.title;
    final remaining = block.items.length - 1;
    if (remaining == 1) return '$firstItem and 1 other';
    if (remaining > 1) return '$firstItem and $remaining others';
    return firstItem;
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
