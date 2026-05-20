import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/config/app_feature_flags.dart';
import 'package:flutter_pecha/core/storage/plan_metadata_store.dart';
import 'package:flutter_pecha/core/storage/special_plan_started_at_store.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;

final _logger = AppLogger('RoutineNotificationService');

// ─────────────────────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────────────────────

class NotificationResult {
  final bool success;
  final String? errorMessage;
  final int? notificationId;

  const NotificationResult._({
    required this.success,
    this.errorMessage,
    this.notificationId,
  });

  factory NotificationResult.success(int notificationId) =>
      NotificationResult._(success: true, notificationId: notificationId);

  factory NotificationResult.failure(String message) =>
      NotificationResult._(success: false, errorMessage: message);

  factory NotificationResult.skipped(String reason) =>
      NotificationResult._(success: true, errorMessage: reason);
}

class NotificationSyncResult {
  final int scheduled;
  final int failed;
  final int cancelled;
  final List<String> errors;

  const NotificationSyncResult({
    this.scheduled = 0,
    this.failed = 0,
    this.cancelled = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isFullySuccessful => failed == 0 && errors.isEmpty;
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class RoutineNotificationService {
  static final RoutineNotificationService _instance =
      RoutineNotificationService._internal();

  factory RoutineNotificationService() => _instance;
  RoutineNotificationService._internal();

  FlutterLocalNotificationsPlugin? _testPlugin;

  @visibleForTesting
  factory RoutineNotificationService.withPlugin(
    FlutterLocalNotificationsPlugin plugin,
  ) {
    final svc = RoutineNotificationService._internal();
    svc._testPlugin = plugin;
    return svc;
  }

  FlutterLocalNotificationsPlugin get _plugin =>
      _testPlugin ?? NotificationService().notificationsPlugin;

  bool get _isReady => NotificationService().isInitialized;

  // ─── Block-level scheduling ───────────────────────────────────────────────

  /// Schedules a notification for [block].
  ///
  /// - **Plan blocks** (special or general): delegate to the appropriate
  ///   series scheduler. These are finite one-shots keyed off `startedAt`,
  ///   never repeating indefinitely.
  /// - **Non-plan blocks** (recitation, etc.): schedule a daily repeat at
  ///   the block's time using `matchDateTimeComponents`.
  Future<NotificationResult> scheduleBlockNotification(
    RoutineBlock block,
  ) async {
    if (!block.notificationEnabled) {
      return NotificationResult.skipped('Notifications disabled for block');
    }
    if (block.items.isEmpty) {
      return NotificationResult.skipped('Block has no items');
    }
    if (!_isReady) {
      _logger.warning('scheduleBlockNotification: service not initialised for block ${block.id}');
      return NotificationResult.failure('Notification service not initialized');
    }

    try {
      final firstItem = block.items.firstOrNull;

      if (firstItem != null && firstItem.type == RoutineItemType.plan) {
        // Cancel any stale daily-repeat schedule before replacing with one-shots.
        await _plugin.cancel(block.notificationId);

        if (isSpecialPlan(firstItem.id)) {
          await rescheduleSpecialPlanSeries(
            planId: firstItem.id,
            planTitle: firstItem.title,
            planImageUrl: firstItem.imageUrl,
            blockHour: block.time.hour,
            blockMinute: block.time.minute,
          );
          return NotificationResult.success(block.notificationId);
        }

        final metadata = PlanMetadataStore.getMetadata(firstItem.id);
        if (metadata != null) {
          await reschedulePlanDurationSeries(
            planId: firstItem.id,
            planTitle: firstItem.title,
            planImageUrl: firstItem.imageUrl,
            blockHour: block.time.hour,
            blockMinute: block.time.minute,
          );
          return NotificationResult.success(block.notificationId);
        }

        // Metadata not yet written (plan added via EditRoutine before server
        // sync). The bootstrap will schedule after the next plans fetch.
        return NotificationResult.skipped('Plan metadata pending — bootstrap will reschedule');
      }

      // Non-plan block: daily repeating schedule.
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        block.time.hour,
        block.time.minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final payload = firstItem != null
          ? jsonEncode({'itemId': firstItem.id, 'itemType': firstItem.type.name})
          : null;
      final androidStyle = await _buildBigPictureStyle(firstItem);
      final iosDetails = await _buildIOSNotificationDetails(firstItem);
      final largeIcon = await _getLargeIcon(firstItem);

      await _plugin.zonedSchedule(
        block.notificationId,
        firstItem?.title ?? 'Time for your practice',
        _getNotificationBody(block),
        scheduledDate,
        NotificationChannels.routineBlockDetails(
          styleInformation: androidStyle,
          largeIcon: largeIcon,
          iOSDetails: iosDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      return NotificationResult.success(block.notificationId);
    } catch (e, st) {
      _logger.error('scheduleBlockNotification failed for block ${block.id}', e, st);
      return NotificationResult.failure(e.toString());
    }
  }

  /// Cancels the notification for [block], including any associated plan
  /// series one-shots.
  Future<void> cancelBlockNotification(RoutineBlock block) async {
    if (!_isReady) return;
    try {
      await _plugin.cancel(block.notificationId);
      final firstItem = block.items.firstOrNull;
      if (firstItem != null && firstItem.type == RoutineItemType.plan) {
        if (isSpecialPlan(firstItem.id)) {
          await _cancelSpecialPlanSeries(firstItem.id);
        } else {
          await _cancelPlanDurationSeries(firstItem.id);
        }
      }
    } catch (e) {
      _logger.warning('cancelBlockNotification failed for block ${block.notificationId}: $e');
    }
  }

  /// Synchronises OS notifications with the current [blocks] list.
  ///
  /// Schedules enabled blocks first, then cancels disabled/removed ones so
  /// that a crash mid-sync leaves notifications in a better state.
  Future<NotificationSyncResult> syncNotifications(
    List<RoutineBlock> blocks,
  ) async {
    if (!_isReady) {
      _logger.warning('syncNotifications: service not initialised');
      return const NotificationSyncResult(
        errors: ['Notification service not initialized'],
      );
    }

    var scheduled = 0;
    var failed = 0;
    var cancelled = 0;
    final errors = <String>[];

    try {
      final activeBlocks =
          blocks.where((b) => b.notificationEnabled && b.items.isNotEmpty).toList();
      final activeIds = <int>{};

      for (final block in activeBlocks) {
        activeIds.add(block.notificationId);
        final result = await scheduleBlockNotification(block);
        if (result.success && result.notificationId != null) {
          scheduled++;
        } else if (!result.success) {
          failed++;
          if (result.errorMessage != null) {
            errors.add('Block ${block.formattedTime}: ${result.errorMessage}');
          }
        }
      }

      for (final block in blocks) {
        if (!activeIds.contains(block.notificationId)) {
          await cancelBlockNotification(block);
          cancelled++;
        }
      }

      _logger.info(
        'syncNotifications: $scheduled scheduled, $cancelled cancelled, $failed failed',
      );
    } catch (e, st) {
      _logger.error('syncNotifications failed', e, st);
      errors.add('Sync error: $e');
    }

    return NotificationSyncResult(
      scheduled: scheduled,
      failed: failed,
      cancelled: cancelled,
      errors: errors,
    );
  }

  // ─── Special-plan series ──────────────────────────────────────────────────

  // Notification ID allocation for special plans:
  //
  // Immediate one-shots: 800 + (dayIndex - 1)  → range 800–807 for 8-day series.
  // Daily scheduled:     810 + slot * 10 + (dayIndex - 1)
  //                      slot = position of planId in kSpecialPlanNotifications.keys
  //                      ITCC (slot 0) → 810..817; next plan (slot 1) → 820..827; etc.
  //
  // Using a fixed slot per plan keeps IDs stable when new plans are added.
  static const int _specialPlanOneShotIdBase = 800;
  static const int _specialPlanSeriesIdBase = 810;
  static const int _specialPlanSeriesSlotSize = 10;

  int _specialPlanSeriesNotifId(String planId, int dayIndex) {
    final slot = kSpecialPlanNotifications.keys.toList().indexOf(planId);
    if (slot < 0) throw ArgumentError('$planId is not a special plan');
    return _specialPlanSeriesIdBase + (slot * _specialPlanSeriesSlotSize) + (dayIndex - 1);
  }

  Future<void> _cancelSpecialPlanSeries(String planId) async {
    final entries = kSpecialPlanNotifications[planId];
    if (entries == null) return;
    for (var day = 1; day <= entries.length; day++) {
      await _plugin.cancel(_specialPlanSeriesNotifId(planId, day));
      await _plugin.cancel(_specialPlanOneShotIdBase + (day - 1));
    }
  }

  /// Cancels all scheduled special-plan notifications across every plan.
  /// Call on logout so a signing-in user does not inherit another's schedules.
  Future<void> cancelAllSpecialPlanSchedules() async {
    if (!_isReady) return;
    for (final planId in kSpecialPlanNotifications.keys) {
      await _cancelSpecialPlanSeries(planId);
    }
    _logger.info('Cancelled all special-plan schedules');
  }

  /// Reschedules the full day-N one-shot series for [planId].
  ///
  /// Reads `startedAt` from [SpecialPlanStartedAtStore] (written by
  /// [onSpecialPlanEnrolled] or the bootstrap). For each future day,
  /// schedules a `zonedSchedule` with that day's title/body baked in
  /// (no repeat — each fires exactly once). Past days are skipped.
  ///
  /// After scheduling, checks whether today's fire time has already passed
  /// and fires an immediate catch-up if needed (covers delete + re-enrol
  /// where `startedAt` is in the past but the series is still active).
  ///
  /// Idempotent: cancels prior IDs before rebuilding. Safe to call on every
  /// app launch or plans-list refresh.
  Future<void> rescheduleSpecialPlanSeries({
    required String planId,
    required String planTitle,
    required String? planImageUrl,
    int blockHour = kSpecialPlanFireHour,
    int blockMinute = kSpecialPlanFireMinute,
  }) async {
    if (!_isReady) {
      _logger.warning('rescheduleSpecialPlanSeries: service not ready for $planId');
      return;
    }
    final entries = kSpecialPlanNotifications[planId];
    if (entries == null) {
      _logger.warning('rescheduleSpecialPlanSeries: $planId is not a special plan');
      return;
    }
    final startedAt = SpecialPlanStartedAtStore.getStartedAt(planId);
    if (startedAt == null) {
      _logger.warning('[NOTIF-SCHEDULE-SP] no cached startedAt for $planId');
      return;
    }

    await _cancelSpecialPlanSeries(planId);

    final startedLocal = startedAt.toLocal();
    _logger.info(
      '[NOTIF-SCHEDULE-SP] $planId begin — cachedAnchor=${startedAt.toIso8601String()} '
      'startedLocal=${startedLocal.toIso8601String()} '
      'block=$blockHour:${blockMinute.toString().padLeft(2, '0')} '
      'entries=${entries.length}',
    );
    final pseudoItem = RoutineItem(
      id: planId,
      title: planTitle,
      imageUrl: planImageUrl,
      type: RoutineItemType.plan,
    );
    final iosDetails = await _buildIOSNotificationDetails(pseudoItem);
    final largeIcon = await _getLargeIcon(pseudoItem);
    final payload = jsonEncode({
      'itemId': planId,
      'itemType': RoutineItemType.plan.name,
    });

    final now = tz.TZDateTime.now(tz.local);

    // Anchor Day 1 to the scheduled time, then add Duration(days:) per day.
    // Using Duration avoids invalid dates when months/years roll over.
    final seriesStart = tz.TZDateTime(
      tz.local,
      startedLocal.year,
      startedLocal.month,
      startedLocal.day,
      blockHour,
      blockMinute,
    );

    _logger.info(
      '[NOTIF-SCHEDULE-SP] $planId seriesStart=${seriesStart.toIso8601String()} '
      'now=${now.toIso8601String()}',
    );

    var scheduledCount = 0;
    var skippedPast = 0;
    for (var day = 1; day <= entries.length; day++) {
      final fireDate = seriesStart.add(Duration(days: day - 1));
      if (!fireDate.isAfter(now)) {
        skippedPast++;
        _logger.info(
          '[NOTIF-SCHEDULE-SP] $planId day=$day fireDate=${fireDate.toIso8601String()} — PAST, skipping',
        );
        continue;
      }
      _logger.info(
        '[NOTIF-SCHEDULE-SP] $planId day=$day fireDate=${fireDate.toIso8601String()} — scheduling',
      );

      final dayContent = entries[day - 1];
      final notifId = _specialPlanSeriesNotifId(planId, day);
      final androidStyle = await _buildBigPictureStyle(
        pseudoItem,
        overrideTitle: dayContent.title,
        overrideBody: dayContent.body,
      );

      try {
        await _plugin.zonedSchedule(
          notifId,
          dayContent.title,
          dayContent.body,
          fireDate,
          NotificationChannels.routineBlockDetails(
            styleInformation: androidStyle,
            largeIcon: largeIcon,
            iOSDetails: iosDetails,
            androidActionButtonText: dayContent.buttonText,
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
        scheduledCount++;
      } catch (e, st) {
        _logger.error('rescheduleSpecialPlanSeries: failed to schedule day=$day for $planId', e, st);
      }
    }

    _logger.info(
      '[NOTIF-SCHEDULE-SP] $planId DONE — scheduled=$scheduledCount past=$skippedPast '
      'total=${entries.length}',
    );

    // Immediate catch-up: if today's scheduled fire has already passed and
    // the notification hasn't been shown yet, fire it now. This covers:
    //   - Enrol after 09:00 on Day 1.
    //   - Delete + re-enrol on Day 4 after 09:00.
    await _fireSpecialPlanCurrentDayIfOverdue(
      planId: planId,
      planTitle: planTitle,
      planImageUrl: planImageUrl,
      seriesStart: seriesStart,
      entries: entries,
      startedLocal: startedLocal,
    );
  }

  /// Checks whether today's special-plan notification is overdue and fires
  /// an immediate if so.
  Future<void> _fireSpecialPlanCurrentDayIfOverdue({
    required String planId,
    required String planTitle,
    required String? planImageUrl,
    required tz.TZDateTime seriesStart,
    required List<DayNotification> entries,
    required DateTime startedLocal,
  }) async {
    final nowLocal = DateTime.now();
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final startedDay = DateTime(
      startedLocal.year,
      startedLocal.month,
      startedLocal.day,
    );
    final daysSince = today.difference(startedDay).inDays;
    _logger.info(
      '[NOTIF-SCHEDULE-SP] $planId overdue check — '
      'today=${today.toIso8601String()} startedDay=${startedDay.toIso8601String()} '
      'daysSince=$daysSince entries=${entries.length}',
    );

    if (daysSince < 0 || daysSince >= entries.length) {
      _logger.info(
        '[NOTIF-SCHEDULE-SP] $planId overdue: outside series — skip',
      );
      return;
    }
    if (SpecialPlanStartedAtStore.wasShownOn(planId, today)) {
      _logger.info('[NOTIF-SCHEDULE-SP] $planId overdue: already shown today — skip');
      return;
    }

    final todayFireTz = seriesStart.add(Duration(days: daysSince));
    if (todayFireTz.isAfter(tz.TZDateTime.now(tz.local))) {
      _logger.info(
        '[NOTIF-SCHEDULE-SP] $planId overdue: not yet due '
        '(fireAt=${todayFireTz.toIso8601String()}) — skip',
      );
      return;
    }
    _logger.info(
      '[NOTIF-SCHEDULE-SP] $planId overdue: firing immediate day=${daysSince + 1}',
    );

    await showSpecialPlanCurrentDayImmediate(
      planId: planId,
      planTitle: planTitle,
      planImageUrl: planImageUrl,
    );
  }

  /// Fires an immediate (non-scheduled) notification for whichever day of
  /// [planId]'s series is current.
  ///
  /// Handles Day 1 on enrol day AND any later day after delete + re-enrol.
  /// Idempotent: keyed by today's calendar date — multiple calls on the same
  /// day are no-ops.
  ///
  /// Returns the notification ID, or `null` when skipped or not ready.
  Future<int?> showSpecialPlanCurrentDayImmediate({
    required String planId,
    required String planTitle,
    required String? planImageUrl,
  }) async {
    if (!_isReady) return null;

    final startedAt = SpecialPlanStartedAtStore.getStartedAt(planId);
    if (startedAt == null) {
      _logger.warning('showSpecialPlanCurrentDayImmediate: no cached startedAt for $planId');
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (SpecialPlanStartedAtStore.wasShownOn(planId, today)) {
      _logger.info(
        '[ENROLL-NOTIF-SP] showImmediate $planId — already shown today, skip',
      );
      return null;
    }

    final dayContent = resolveSpecialPlanNotification(
      planId: planId,
      startedAt: startedAt,
      now: now,
    );
    if (dayContent == null) {
      _logger.warning(
        '[ENROLL-NOTIF-SP] showImmediate $planId — no day content resolved '
        '(anchor=${startedAt.toIso8601String()} now=${now.toIso8601String()})',
      );
      return null;
    }

    final dayIndex = specialPlanDayIndex(
      planId: planId,
      startedAt: startedAt,
      now: now,
    );
    if (dayIndex == null) {
      _logger.warning('[ENROLL-NOTIF-SP] showImmediate $planId — dayIndex null');
      return null;
    }
    _logger.info(
      '[ENROLL-NOTIF-SP] showImmediate $planId day=$dayIndex title="${dayContent.title}"',
    );

    // Guard: if permission is not yet granted, _plugin.show() silently no-ops
    // on Android 13+ and iOS. Do NOT mark wasShownOn in that case — the
    // HomeScreen will retry after the permission dialog resolves.
    final hasPermission = await NotificationService().areNotificationsEnabled();
    if (!hasPermission) {
      _logger.warning('showSpecialPlanCurrentDayImmediate: no permission — will retry after grant for $planId');
      return null;
    }

    try {
      final pseudoItem = RoutineItem(
        id: planId,
        title: planTitle,
        imageUrl: planImageUrl,
        type: RoutineItemType.plan,
      );
      final androidStyle = await _buildBigPictureStyle(
        pseudoItem,
        overrideTitle: dayContent.title,
        overrideBody: dayContent.body,
      );
      final notifId = _specialPlanOneShotIdBase + (dayIndex - 1);
      final payload = jsonEncode({
        'itemId': planId,
        'itemType': RoutineItemType.plan.name,
      });

      await _plugin.show(
        notifId,
        dayContent.title,
        dayContent.body,
        NotificationChannels.routineBlockDetails(
          styleInformation: androidStyle,
          largeIcon: await _getLargeIcon(pseudoItem),
          iOSDetails: await _buildIOSNotificationDetails(pseudoItem),
          androidActionButtonText: dayContent.buttonText,
        ),
        payload: payload,
      );

      await SpecialPlanStartedAtStore.markShownOn(planId, today);
      _logger.info('showSpecialPlanCurrentDayImmediate: fired day=$dayIndex for $planId id=$notifId');
      return notifId;
    } catch (e, st) {
      _logger.error('showSpecialPlanCurrentDayImmediate: failed for $planId', e, st);
      return null;
    }
  }

  // ─── General plan duration-based series ──────────────────────────────────

  // Notification ID allocation for general plans:
  //
  // Series one-shots: 10,000,000 + (slot * 500) + (dayIndex - 1)
  //                   slot = planId.hashCode.abs() % 10000
  //                   Range: 10,000,000 – ~15,004,999
  // Immediate:        9,000,000 + planId.hashCode.abs() % 10000
  //
  // Well above routine-block hashes (1000–999999) and special-plan IDs, so
  // they never collide.
  //
  // iOS allows at most 64 pending scheduled notifications. We cap the lookahead
  // window at [kPlanSeriesMaxScheduledDays]. The bootstrap re-runs on every app
  // launch so the window slides forward automatically.
  static const int kPlanSeriesMaxScheduledDays = 60;
  static const int kPlanSeriesDefaultHour = 9;
  static const int _planSeriesIdBase = 10000000;
  static const int _planSeriesSlotSize = 500;
  static const int _planOneShotIdBase = 9000000;

  int _planDaySeriesNotifId(String planId, int dayIndex) {
    final slot = planId.hashCode.abs() % 10000;
    return _planSeriesIdBase + (slot * _planSeriesSlotSize) + (dayIndex - 1);
  }

  int _planOneShotNotifId(String planId) =>
      _planOneShotIdBase + planId.hashCode.abs() % 10000;

  String _planDayBody(String planTitle, int dayNumber, int totalDays) =>
      'Day $dayNumber of $totalDays — check out $planTitle.';

  Future<void> _cancelPlanDurationSeries(String planId) async {
    for (var day = 1; day <= kPlanSeriesMaxScheduledDays; day++) {
      await _plugin.cancel(_planDaySeriesNotifId(planId, day));
    }
    await _plugin.cancel(_planOneShotNotifId(planId));
  }

  /// Cancels all pending duration-series schedules across every enrolled plan.
  /// Call on logout so a signing-in user does not inherit another's schedules.
  Future<void> cancelAllPlanDurationSchedules() async {
    if (!_isReady) return;
    for (final planId in PlanMetadataStore.getAllPlanIds()) {
      await _cancelPlanDurationSeries(planId);
    }
    _logger.info('Cancelled all general plan duration schedules');
  }

  /// Reschedules the duration-based one-shot series for [planId].
  ///
  /// Reads metadata from [PlanMetadataStore]. For each future day within the
  /// next [kPlanSeriesMaxScheduledDays], schedules a `zonedSchedule` (no
  /// repeat — fires exactly once). Past days are skipped. After scheduling,
  /// fires an immediate catch-up if today's block time has already passed.
  ///
  /// Idempotent: cancels prior IDs first. Safe to call on every app launch.
  Future<void> reschedulePlanDurationSeries({
    required String planId,
    required String planTitle,
    required String? planImageUrl,
    int blockHour = kPlanSeriesDefaultHour,
    int blockMinute = 0,
  }) async {
    if (!_isReady) {
      _logger.warning('reschedulePlanDurationSeries: service not ready for $planId');
      return;
    }

    // Feature flag gate: when general-plan notifications are disabled we
    // still want existing schedules on user devices to be torn down — the
    // bootstrap calls this method on every userPlans fetch, so this branch
    // cleans up alarms from prior installs before returning. Special plans
    // and recitations go through different code paths and are unaffected.
    if (!AppFeatureFlags.kSchedulePlanNotifications) {
      await _cancelPlanDurationSeries(planId);
      _logger.info(
        'reschedulePlanDurationSeries: skipped for $planId — '
        'kSchedulePlanNotifications=false (prior schedule cancelled)',
      );
      return;
    }

    final metadata = PlanMetadataStore.getMetadata(planId);
    if (metadata == null) {
      _logger.warning('reschedulePlanDurationSeries: no metadata for $planId');
      return;
    }

    await _cancelPlanDurationSeries(planId);

    // Anchor day-numbering to the plan's day-1 (effectiveStartDate).
    // For fixed-date plans where the user joined late, this is the plan's
    // scheduled start, NOT the user's enrollment timestamp — so they see
    // the correct day-N notification (e.g. "Day 5 of 10") instead of Day 1.
    final startedLocal = metadata.effectiveStartDate.toLocal();
    final nowTz = tz.TZDateTime.now(tz.local);
    final pseudoItem = RoutineItem(
      id: planId,
      title: planTitle,
      imageUrl: planImageUrl,
      type: RoutineItemType.plan,
    );
    final iosDetails = await _buildIOSNotificationDetails(pseudoItem);
    final largeIcon = await _getLargeIcon(pseudoItem);
    final payload = jsonEncode({
      'itemId': planId,
      'itemType': RoutineItemType.plan.name,
    });

    // Anchor Day 1 to the scheduled time, then add Duration(days:) per day.
    final seriesStart = tz.TZDateTime(
      tz.local,
      startedLocal.year,
      startedLocal.month,
      startedLocal.day,
      blockHour,
      blockMinute,
    );

    var scheduledCount = 0;
    for (var day = 1; day <= metadata.totalDays; day++) {
      final fireDate = seriesStart.add(Duration(days: day - 1));
      if (!fireDate.isAfter(nowTz)) continue; // past — skip
      if (scheduledCount >= kPlanSeriesMaxScheduledDays) break;

      final body = _planDayBody(planTitle, day, metadata.totalDays);
      final androidStyle = await _buildBigPictureStyle(
        pseudoItem,
        overrideTitle: planTitle,
        overrideBody: body,
      );

      try {
        await _plugin.zonedSchedule(
          _planDaySeriesNotifId(planId, day),
          planTitle,
          body,
          fireDate,
          NotificationChannels.routineBlockDetails(
            styleInformation: androidStyle,
            largeIcon: largeIcon,
            iOSDetails: iosDetails,
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
        scheduledCount++;
      } catch (e, st) {
        _logger.error('reschedulePlanDurationSeries: failed day=$day for $planId', e, st);
      }
    }

    _logger.info(
      '[NOTIF-SCHEDULE] $planId — anchor=${startedLocal.toIso8601String()} '
      'block=$blockHour:${blockMinute.toString().padLeft(2, '0')} '
      '$scheduledCount future days scheduled of ${metadata.totalDays} total',
    );

    // Immediate catch-up: fire today's notification if the block time has
    // already passed and it hasn't been shown yet. Day-N is computed from
    // the plan anchor (effectiveStartDate) so late joiners see the correct
    // day number.
    final nowLocal = DateTime.now();
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final startedDay = DateTime(startedLocal.year, startedLocal.month, startedLocal.day);
    final daysSince = today.difference(startedDay).inDays;
    final todayDayNumber = daysSince + 1;

    if (daysSince >= 0 &&
        todayDayNumber <= metadata.totalDays &&
        !PlanMetadataStore.wasImmediateShownOn(planId, today)) {
      final todayFireTz = seriesStart.add(Duration(days: daysSince));
      if (!todayFireTz.isAfter(nowTz)) {
        final id = await showPlanDayImmediate(
          planId: planId,
          planTitle: planTitle,
          planImageUrl: planImageUrl,
          dayNumber: todayDayNumber,
          totalDays: metadata.totalDays,
        );
        if (id != null) {
          await PlanMetadataStore.markImmediateShownOn(planId, today);
          _logger.info('[NOTIF-SCHEDULE] fired immediate day=$todayDayNumber for $planId id=$id');
        }
      }
    }
  }

  /// Fires an immediate (non-scheduled) notification for [planId] at [dayNumber].
  ///
  /// Used when today's block time has already passed and the scheduled one-shot
  /// is in the past. The caller is responsible for idempotency checks before
  /// calling, and for persisting the shown flag afterwards.
  ///
  /// Returns the notification ID on success, or `null` on failure or not ready.
  Future<int?> showPlanDayImmediate({
    required String planId,
    required String planTitle,
    required String? planImageUrl,
    required int dayNumber,
    required int totalDays,
  }) async {
    if (!_isReady) return null;

    // Guard: don't mark shown flag if permission isn't granted yet.
    final hasPermission = await NotificationService().areNotificationsEnabled();
    if (!hasPermission) {
      _logger.warning('showPlanDayImmediate: no permission — will retry after grant for $planId');
      return null;
    }

    try {
      final body = _planDayBody(planTitle, dayNumber, totalDays);
      final pseudoItem = RoutineItem(
        id: planId,
        title: planTitle,
        imageUrl: planImageUrl,
        type: RoutineItemType.plan,
      );
      final androidStyle = await _buildBigPictureStyle(
        pseudoItem,
        overrideTitle: planTitle,
        overrideBody: body,
      );
      final notifId = _planOneShotNotifId(planId);
      final payload = jsonEncode({
        'itemId': planId,
        'itemType': RoutineItemType.plan.name,
      });

      await _plugin.show(
        notifId,
        planTitle,
        body,
        NotificationChannels.routineBlockDetails(
          styleInformation: androidStyle,
          largeIcon: await _getLargeIcon(pseudoItem),
          iOSDetails: await _buildIOSNotificationDetails(pseudoItem),
        ),
        payload: payload,
      );
      return notifId;
    } catch (e, st) {
      _logger.error('showPlanDayImmediate: failed for $planId', e, st);
      return null;
    }
  }

  // ─── Bulk cancel helpers ──────────────────────────────────────────────────

  Future<void> cancelAllBlockNotifications(List<RoutineBlock> blocks) async {
    if (!_isReady) return;
    for (final block in blocks) {
      await cancelBlockNotification(block);
    }
  }

  Future<void> cancelNotificationById(int notificationId) async {
    if (!_isReady) return;
    try {
      await _plugin.cancel(notificationId);
    } catch (e) {
      _logger.warning('cancelNotificationById failed for id=$notificationId: $e');
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  String _getNotificationBody(RoutineBlock block) {
    if (block.items.isEmpty) return 'Check your daily routine';
    final firstItem = block.items.first.title;
    final remaining = block.items.length - 1;
    if (remaining == 1) return '$firstItem and 1 other';
    if (remaining > 1) return '$firstItem and $remaining others';
    return firstItem;
  }

  /// Builds [BigPictureStyleInformation] for Android if an image is available,
  /// falling back to [BigTextStyleInformation] otherwise.
  ///
  /// Pass [overrideTitle]/[overrideBody] for day-N copy on plan blocks so
  /// Android renders the day-specific text inside the expanded style instead
  /// of the plan's generic static title.
  Future<StyleInformation> _buildBigPictureStyle(
    RoutineItem? item, {
    String? overrideTitle,
    String? overrideBody,
  }) async {
    final title = overrideTitle ?? item?.title ?? 'Time for your practice';
    final body = overrideBody ?? item?.title ?? 'Time for your practice';

    if (item?.imageUrl case final String url when url.isNotEmpty) {
      try {
        final imagePath = await _downloadAndCacheImage(url);
        if (imagePath != null) {
          return BigPictureStyleInformation(
            FilePathAndroidBitmap(imagePath),
            largeIcon: await _getLargeIcon(item),
            contentTitle: title,
            summaryText: body,
            htmlFormatContentTitle: true,
            htmlFormatSummaryText: true,
          );
        }
      } catch (e) {
        _logger.warning('_buildBigPictureStyle: image load failed: $e');
      }
    }

    return BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );
  }

  Future<DarwinNotificationDetails> _buildIOSNotificationDetails(
    RoutineItem? item,
  ) async {
    if (item?.imageUrl case final String url when url.isNotEmpty) {
      try {
        final imagePath = await _downloadAndCacheImage(url);
        if (imagePath != null) {
          return DarwinNotificationDetails(
            attachments: [DarwinNotificationAttachment(imagePath)],
            threadIdentifier: 'routine_notifications',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );
        }
      } catch (e) {
        _logger.warning('_buildIOSNotificationDetails: image attach failed: $e');
      }
    }
    return const DarwinNotificationDetails(
      threadIdentifier: 'routine_notifications',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
  }

  /// Downloads [imageUrl] to a content-addressed temp file and returns its
  /// path. Returns `null` on any error. Cached by content hash so repeated
  /// calls for the same URL are cheap.
  Future<String?> _downloadAndCacheImage(String imageUrl) async {
    try {
      final hash = imageUrl.hashCode.toString();
      final ext = imageUrl.contains('.png') ? '.png' : '.jpg';
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/notification_images/notif_$hash$ext';
      final file = File(filePath);

      if (await file.exists()) return filePath;

      await file.parent.create(recursive: true);
      final request = await HttpClient().getUrl(Uri.parse(imageUrl));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.toList();
        await file.writeAsBytes(bytes.expand((b) => b).toList());
        return filePath;
      }
    } catch (e) {
      _logger.warning('_downloadAndCacheImage: failed for $imageUrl: $e');
    }
    return null;
  }

  Future<FilePathAndroidBitmap?> _getLargeIcon(RoutineItem? item) async {
    if (item?.imageUrl case final String url when url.isNotEmpty) {
      try {
        final path = await _downloadAndCacheImage(url);
        if (path != null) return FilePathAndroidBitmap(path);
      } catch (e) {
        _logger.warning('_getLargeIcon: failed: $e');
      }
    }
    return null;
  }
}
