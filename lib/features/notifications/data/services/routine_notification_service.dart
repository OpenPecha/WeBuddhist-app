import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/storage/special_plan_started_at_store.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;

final _logger = AppLogger('RoutineNotificationService');

/// Result of a notification scheduling operation.
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

/// Result of a batch notification sync operation.
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

class RoutineNotificationService {
  static final RoutineNotificationService _instance =
      RoutineNotificationService._internal();
  factory RoutineNotificationService() => _instance;
  RoutineNotificationService._internal();

  // Allows injecting a mock plugin in tests without breaking the public API.
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

  /// Schedule a daily repeating notification for a single block.
  Future<NotificationResult> scheduleBlockNotification(
    RoutineBlock block,
  ) async {
    _logger.info(
      '[NOTIF-SCHEDULE] block=${block.id} time=${block.formattedTime} '
      'notificationEnabled=${block.notificationEnabled} '
      'items=${block.items.length} notificationId=${block.notificationId}',
    );

    if (!block.notificationEnabled) {
      _logger.info('[NOTIF-SCHEDULE] SKIPPED: notifications disabled for block');
      return NotificationResult.skipped('Notifications disabled for block');
    }

    if (block.items.isEmpty) {
      _logger.info('[NOTIF-SCHEDULE] SKIPPED: block has no items');
      return NotificationResult.skipped('Block has no items');
    }

    _logger.info('[NOTIF-SCHEDULE] _isReady=$_isReady');
    if (!_isReady) {
      _logger.warning('[NOTIF-SCHEDULE] FAILED: NotificationService not initialized');
      return NotificationResult.failure('Notification service not initialized');
    }

    try {
      final firstItem = block.items.firstOrNull;

      // Special-plan path: each day in the series has unique copy/button, so
      // we cannot use a single `matchDateTimeComponents: time` repeating
      // schedule (the OS would replay the same payload every day). Replace it
      // with N deterministic one-shots, one per remaining day. The block's
      // notificationId is cancelled to prevent duplicate fires from any
      // previously-scheduled daily-repeat for the same block.
      if (firstItem != null &&
          firstItem.type == RoutineItemType.plan &&
          isSpecialPlan(firstItem.id)) {
        _logger.info(
          '[SP-SCHEDULE] delegating to series scheduler for planId=${firstItem.id} '
          'block=${block.id} notificationId=${block.notificationId}',
        );
        await _plugin.cancel(block.notificationId);
        await rescheduleSpecialPlanSeries(
          planId: firstItem.id,
          planTitle: firstItem.title,
          planImageUrl: firstItem.imageUrl,
          blockHour: block.time.hour,
          blockMinute: block.time.minute,
        );
        return NotificationResult.success(block.notificationId);
      }

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

      _logger.info(
        '[NOTIF-SCHEDULE] now=$now  scheduledFor=$scheduledDate  '
        'tz=${tz.local.name}',
      );

      final payload = firstItem != null
          ? jsonEncode({'itemId': firstItem.id, 'itemType': firstItem.type.name})
          : null;

      final title = firstItem?.title ?? 'Time for your practice';
      final body = _getNotificationBody(block);

      final androidStyle = await _buildBigPictureStyle(firstItem);
      final iosDetails = await _buildIOSNotificationDetails(firstItem);
      final largeIcon = await _getLargeIcon(firstItem);

      await _plugin.zonedSchedule(
        block.notificationId,
        title,
        body,
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

      _logger.info(
        '[NOTIF-SCHEDULE] SUCCESS  id=${block.notificationId}  '
        'fires=$scheduledDate  body="$body"',
      );

      return NotificationResult.success(block.notificationId);
    } catch (e, stackTrace) {
      _logger.error(
        '[NOTIF-SCHEDULE] ERROR scheduling block ${block.id}',
        e,
        stackTrace,
      );
      return NotificationResult.failure(e.toString());
    }
  }

  /// Cancel notification for a single block.
  Future<void> cancelBlockNotification(RoutineBlock block) async {
    if (!_isReady) return;
    try {
      await _plugin.cancel(block.notificationId);
      _logger.info('Cancelled routine notification ID=${block.notificationId}');
      // Special-plan blocks fan out into N one-shot schedules — cancel those
      // too so disabling/removing the block stops the whole series.
      final firstItem = block.items.firstOrNull;
      if (firstItem != null &&
          firstItem.type == RoutineItemType.plan &&
          isSpecialPlan(firstItem.id)) {
        await _cancelSpecialPlanSeriesForPlan(firstItem.id);
      }
    } catch (e) {
      _logger.warning(
        'Failed to cancel notification ${block.notificationId}: $e',
      );
    }
  }

  /// Synchronize notifications with the current block list.
  ///
  /// Schedules active blocks first, then cancels inactive ones — so if the
  /// app crashes mid-sync, notifications are more likely to remain scheduled.
  Future<NotificationSyncResult> syncNotifications(
    List<RoutineBlock> blocks,
  ) async {
    _logger.info('[NOTIF-SYNC] starting sync for ${blocks.length} blocks, _isReady=$_isReady');

    if (!_isReady) {
      _logger.warning('[NOTIF-SYNC] FAILED: NotificationService not initialized');
      return const NotificationSyncResult(
        errors: ['Notification service not initialized'],
      );
    }

    int scheduled = 0;
    int failed = 0;
    int cancelled = 0;
    final errors = <String>[];

    try {
      final activeBlocks = blocks
          .where((b) => b.notificationEnabled && b.items.isNotEmpty)
          .toList();

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
        'Notification sync complete: $scheduled scheduled, '
        '$cancelled cancelled, $failed failed',
      );
    } catch (e, st) {
      _logger.error('Sync failed', e, st);
      errors.add('Sync error: $e');
    }

    return NotificationSyncResult(
      scheduled: scheduled,
      failed: failed,
      cancelled: cancelled,
      errors: errors,
    );
  }

  /// Notification ID range reserved for one-shot special-plan immediate fires.
  /// Sits below the routine-block hash range (1000-999999) and above the
  /// flutter_local_notifications system reservation (0-99). 800 + dayIndex - 1
  /// → range 800–807 for an 8-day series.
  static const int _specialPlanOneShotIdBase = 800;

  /// Notification ID range reserved for the daily 09:00 special-plan series.
  /// Each plan in [kSpecialPlanNotifications] gets a contiguous slot of
  /// [_specialPlanSeriesSlotSize] IDs starting at this base. ITCC (slot 0)
  /// → 810..817. Future plans can claim slot 1 (820..827) etc.
  static const int _specialPlanSeriesIdBase = 810;
  static const int _specialPlanSeriesSlotSize = 10;

  /// Returns a stable notification ID for [planId] day [dayIndex] (1-based).
  /// Each special plan owns a 10-ID slot; the position inside [kSpecialPlanNotifications.keys]
  /// determines the slot, so adding a new plan does not perturb existing IDs.
  int _specialPlanSeriesNotifId(String planId, int dayIndex) {
    final keys = kSpecialPlanNotifications.keys.toList();
    final slot = keys.indexOf(planId);
    if (slot < 0) {
      throw ArgumentError('Plan $planId is not in kSpecialPlanNotifications');
    }
    return _specialPlanSeriesIdBase +
        (slot * _specialPlanSeriesSlotSize) +
        (dayIndex - 1);
  }

  /// Cancels every reserved one-shot ID for [planId]'s series (both immediate
  /// 800-range and daily 810+-range). Used when the block is disabled or the
  /// user logs out.
  Future<void> _cancelSpecialPlanSeriesForPlan(String planId) async {
    final entries = kSpecialPlanNotifications[planId];
    if (entries == null) return;
    _logger.info('[SP-SERIES] cancel series for planId=$planId days=${entries.length}');
    for (var day = 1; day <= entries.length; day++) {
      await _plugin.cancel(_specialPlanSeriesNotifId(planId, day));
      await _plugin.cancel(_specialPlanOneShotIdBase + (day - 1));
    }
  }

  /// Cancels every special-plan schedule across every plan. Called on logout
  /// so a different user signing in does not inherit pending notifications.
  Future<void> cancelAllSpecialPlanSchedules() async {
    _logger.info(
      '[SP-SERIES] cancelAllSpecialPlanSchedules — '
      '${kSpecialPlanNotifications.length} plan(s)',
    );
    if (!_isReady) return;
    for (final planId in kSpecialPlanNotifications.keys) {
      await _cancelSpecialPlanSeriesForPlan(planId);
    }
  }

  /// Reschedules the full N-day special-plan series for [planId] using the
  /// server-truth `startedAt` from [SpecialPlanStartedAtStore]. For each day
  /// 1..N where the 09:00 fire is still in the future, schedules a one-shot
  /// `zonedSchedule` with that day's title/body/button baked in. Days already
  /// in the past are skipped (no `matchDateTimeComponents` — these never
  /// repeat). Always cancels prior series IDs first, so calling repeatedly is
  /// idempotent.
  ///
  /// Required from caller:
  ///   - cache must already have `startedAt` for [planId] (bootstrap listener
  ///     or onSpecialPlanEnrolled writes it).
  ///   - [planTitle] and [planImageUrl] are used for the notification image
  ///     and large icon — pass values from [UserPlansModel] or [RoutineItem].
  Future<void> rescheduleSpecialPlanSeries({
    required String planId,
    required String planTitle,
    required String? planImageUrl,
    int blockHour = kSpecialPlanFireHour,
    int blockMinute = kSpecialPlanFireMinute,
  }) async {
    _logger.info(
      '[SP-SERIES] rescheduleSpecialPlanSeries ENTER planId=$planId '
      'fire=$blockHour:${blockMinute.toString().padLeft(2, '0')} _isReady=$_isReady',
    );
    if (!_isReady) {
      _logger.warning('[SP-SERIES] notification service not ready — abort');
      return;
    }
    final entries = kSpecialPlanNotifications[planId];
    if (entries == null) {
      _logger.warning('[SP-SERIES] planId=$planId not a special plan — abort');
      return;
    }
    final startedAt = SpecialPlanStartedAtStore.getStartedAt(planId);
    if (startedAt == null) {
      _logger.warning(
        '[SP-SERIES] no cached startedAt for $planId — abort. Bootstrap '
        'listener should write it before this is called.',
      );
      return;
    }

    // Always wipe prior schedules first so we don't end up with duplicate
    // fires from a previous (possibly incorrect) series.
    await _cancelSpecialPlanSeriesForPlan(planId);

    final startedLocal = startedAt.toLocal();
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
    var scheduledCount = 0;
    var skippedPast = 0;

    for (var day = 1; day <= entries.length; day++) {
      final fireDate = tz.TZDateTime(
        tz.local,
        startedLocal.year,
        startedLocal.month,
        startedLocal.day + (day - 1),
        blockHour,
        blockMinute,
      );

      if (!fireDate.isAfter(now)) {
        _logger.info(
          '[SP-SERIES] day=$day fire=$fireDate is in the past — skip',
        );
        skippedPast++;
        continue;
      }

      final dayContent = entries[day - 1];
      final notifId = _specialPlanSeriesNotifId(planId, day);

      // Build a fresh style per day so contentTitle/summaryText carry the
      // day-N copy (Android style ignores the title/body args otherwise).
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
        _logger.info(
          '[SP-SERIES] scheduled day=$day id=$notifId fires=$fireDate '
          'title="${dayContent.title}" button="${dayContent.buttonText}"',
        );
      } catch (e, st) {
        _logger.error(
          '[SP-SERIES] failed to schedule day=$day id=$notifId',
          e,
          st,
        );
      }
    }

    _logger.info(
      '[SP-SERIES] rescheduleSpecialPlanSeries DONE planId=$planId '
      'scheduled=$scheduledCount skippedPast=$skippedPast '
      'totalDays=${entries.length}',
    );
  }

  /// Fires an immediate (non-scheduled) one-shot notification with Day 1
  /// content for [planId]. Idempotent: respects [SpecialPlanStartedAtStore]'s
  /// `wasDay1Shown` flag — calling twice on the same day is a no-op. Requires
  /// the startedAt to already be cached in the store (caller's responsibility).
  ///
  /// Returns the notification ID on success, or null when skipped.
  Future<int?> showSpecialPlanDay1Immediate({
    required String planId,
    required String planTitle,
    required String? planImageUrl,
  }) async {
    _logger.info(
      '[SP-DAY1] showSpecialPlanDay1Immediate ENTER planId=$planId '
      'title="$planTitle" imageUrl=$planImageUrl _isReady=$_isReady',
    );
    if (!_isReady) {
      _logger.warning('[SP-DAY1] FAILED: NotificationService not initialized');
      return null;
    }

    final startedAt = SpecialPlanStartedAtStore.getStartedAt(planId);
    _logger.info('[SP-DAY1] cached startedAt=$startedAt');
    if (startedAt == null) {
      _logger.warning('[SP-DAY1] no cached startedAt for $planId — skip');
      return null;
    }

    final wasShown = SpecialPlanStartedAtStore.wasDay1Shown(planId, startedAt);
    _logger.info('[SP-DAY1] wasDay1Shown=$wasShown');
    if (wasShown) {
      _logger.info(
        '[SP-DAY1] day1 already shown for $planId on '
        '${startedAt.toIso8601String()} — skip (idempotent)',
      );
      return null;
    }

    final now = DateTime.now();
    final dayContent = resolveSpecialPlanNotification(
      planId: planId,
      startedAt: startedAt,
      now: now,
    );
    if (dayContent == null) {
      _logger.info('[SP-DAY1] resolveSpecialPlanNotification returned null — skip');
      return null;
    }
    final dayIndex = specialPlanDayIndex(
      planId: planId,
      startedAt: startedAt,
      now: now,
    );
    _logger.info('[SP-DAY1] resolved dayIndex=$dayIndex title="${dayContent.title}"');
    if (dayIndex != 1) {
      _logger.info('[SP-DAY1] not currently day 1 (resolved=$dayIndex) — skip');
      return null;
    }

    try {
      // Build the same image-rich style as the daily routine notification,
      // but with the day-N title/body baked into the style (otherwise Android
      // would render the plan's static title + a generic summary).
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
      final iosDetails = await _buildIOSNotificationDetails(pseudoItem);
      final largeIcon = await _getLargeIcon(pseudoItem);

      // dayIndex is non-null here (we early-returned when it was != 1).
      final notifId = _specialPlanOneShotIdBase + (dayIndex! - 1);
      final payload = jsonEncode({
        'itemId': planId,
        'itemType': RoutineItemType.plan.name,
      });

      _logger.info(
        '[SP-DAY1] calling _plugin.show id=$notifId title="${dayContent.title}" '
        'body="${dayContent.body}" button="${dayContent.buttonText}"',
      );
      await _plugin.show(
        notifId,
        dayContent.title,
        dayContent.body,
        NotificationChannels.routineBlockDetails(
          styleInformation: androidStyle,
          largeIcon: largeIcon,
          iOSDetails: iosDetails,
          androidActionButtonText: dayContent.buttonText,
        ),
        payload: payload,
      );

      await SpecialPlanStartedAtStore.markDay1Shown(planId, startedAt);

      _logger.info(
        '[SP-DAY1] SUCCESS id=$notifId planId=$planId '
        'title="${dayContent.title}" markedDay1Shown=true',
      );
      return notifId;
    } catch (e, st) {
      _logger.error('[SP-DAY1] error showing day 1 for $planId', e, st);
      return null;
    }
  }

  /// Cancel all routine block notifications.
  Future<void> cancelAllBlockNotifications(List<RoutineBlock> blocks) async {
    if (!_isReady) return;
    for (final block in blocks) {
      await cancelBlockNotification(block);
    }
    _logger.info('Cancelled all routine block notifications');
  }

  /// Cancel a notification by ID directly.
  Future<void> cancelNotificationById(int notificationId) async {
    if (!_isReady) return;
    try {
      await _plugin.cancel(notificationId);
      _logger.info('Cancelled notification ID=$notificationId');
    } catch (e) {
      _logger.warning('Failed to cancel notification $notificationId: $e');
    }
  }

  String _getNotificationBody(RoutineBlock block) {
    if (block.items.isEmpty) return 'Check your daily routine';
    final firstItem = block.items.first.title;
    final remaining = block.items.length - 1;
    if (remaining == 1) return '$firstItem and 1 other';
    if (remaining > 1) return '$firstItem and $remaining others';
    return firstItem;
  }

  /// Builds Android BigPictureStyle for rich image notifications.
  ///
  /// [overrideTitle]/[overrideBody] take precedence over [item]'s defaults —
  /// pass the special-plan day-N copy here so Android renders that text inside
  /// the style instead of the plan's static title and a generic summary.
  Future<StyleInformation> _buildBigPictureStyle(
    RoutineItem? item, {
    String? overrideTitle,
    String? overrideBody,
  }) async {
    final effectiveTitle = overrideTitle ?? item?.title ?? 'Time for your practice';
    final effectiveBody = overrideBody ?? item?.title ?? 'Time for your practice';
    _logger.info(
      '[SP-STYLE] _buildBigPictureStyle title="$effectiveTitle" '
      'body="$effectiveBody" imageUrl=${item?.imageUrl}',
    );

    if (item == null || item.imageUrl == null || item.imageUrl!.isEmpty) {
      _logger.info('[SP-STYLE] no image — using BigTextStyle');
      return BigTextStyleInformation(
        effectiveBody,
        htmlFormatBigText: true,
        contentTitle: effectiveTitle,
        htmlFormatContentTitle: true,
      );
    }

    try {
      final imagePath = await _downloadAndCacheImage(item.imageUrl!);
      if (imagePath != null) {
        _logger.info('[SP-STYLE] using BigPictureStyle imagePath=$imagePath');
        return BigPictureStyleInformation(
          FilePathAndroidBitmap(imagePath),
          largeIcon: await _getLargeIcon(item),
          contentTitle: effectiveTitle,
          summaryText: effectiveBody,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        );
      }
    } catch (e) {
      _logger.warning('[SP-STYLE] Failed to load image: $e');
    }

    _logger.info('[SP-STYLE] image failed — falling back to BigTextStyle');
    return BigTextStyleInformation(
      effectiveBody,
      htmlFormatBigText: true,
      contentTitle: effectiveTitle,
      htmlFormatContentTitle: true,
    );
  }

  /// Builds iOS notification details with attachments.
  Future<DarwinNotificationDetails> _buildIOSNotificationDetails(
    RoutineItem? item,
  ) async {
    if (item?.imageUrl != null && item!.imageUrl!.isNotEmpty) {
      try {
        final imagePath = await _downloadAndCacheImage(item.imageUrl!);
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
        _logger.warning('Failed to attach image for iOS notification: $e');
      }
    }

    return const DarwinNotificationDetails(
      threadIdentifier: 'routine_notifications',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
  }

  /// Downloads and caches an image URL to local storage.
  Future<String?> _downloadAndCacheImage(String imageUrl) async {
    try {
      // Generate a safe filename using hash to avoid length issues
      final imageHash = imageUrl.hashCode.toString();
      final extension = imageUrl.contains('.jpg') ? '.jpg' :
                       imageUrl.contains('.png') ? '.png' : '.jpg';
      final filename = 'notif_$imageHash$extension';

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/notification_images/$filename';

      // Check if already cached
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }

      // Create directory if it doesn't exist
      await file.parent.create(recursive: true);

      // Download the image
      final request = await HttpClient().getUrl(Uri.parse(imageUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await response.toList();
        await file.writeAsBytes(bytes.expand((b) => b).toList());
        return filePath;
      }
    } catch (e) {
      _logger.warning('Error downloading image: $e');
    }
    return null;
  }

  /// Gets the large icon for Android notification.
  Future<FilePathAndroidBitmap?> _getLargeIcon(RoutineItem? item) async {
    if (item?.imageUrl == null || item!.imageUrl!.isEmpty) {
      return null;
    }

    try {
      final imagePath = await _downloadAndCacheImage(item.imageUrl!);
      if (imagePath != null) {
        return FilePathAndroidBitmap(imagePath);
      }
    } catch (e) {
      _logger.warning('Failed to load large icon: $e');
    }

    return null;
  }
}
