import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
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

      final body = _getNotificationBody(block);
      final firstItem = block.items.firstOrNull;
      final payload = firstItem != null
          ? jsonEncode({'itemId': firstItem.id, 'itemType': firstItem.type.name})
          : null;

      // Add image support
      final androidStyle = await _buildBigPictureStyle(firstItem);
      final iosDetails = await _buildIOSNotificationDetails(firstItem);
      final largeIcon = await _getLargeIcon(firstItem);

      await _plugin.zonedSchedule(
        block.notificationId,
        firstItem?.title ?? 'Time for your practice',
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
  Future<StyleInformation> _buildBigPictureStyle(RoutineItem? item) async {
    if (item == null || item.imageUrl == null || item.imageUrl!.isEmpty) {
      return BigTextStyleInformation(
        item?.title ?? 'Time for your practice',
        htmlFormatBigText: true,
        contentTitle: item?.title,
        htmlFormatContentTitle: true,
      );
    }

    try {
      final imagePath = await _downloadAndCacheImage(item.imageUrl!);
      if (imagePath != null) {
        return BigPictureStyleInformation(
          FilePathAndroidBitmap(imagePath),
          largeIcon: await _getLargeIcon(item),
          contentTitle: item.title,
          summaryText: 'Time for your practice',
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        );
      }
    } catch (e) {
      _logger.warning('Failed to load image for notification: $e');
    }

    return BigTextStyleInformation(
      item.title,
      htmlFormatBigText: true,
      contentTitle: item.title,
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
          );
        }
      } catch (e) {
        _logger.warning('Failed to attach image for iOS notification: $e');
      }
    }

    return const DarwinNotificationDetails(
      threadIdentifier: 'routine_notifications',
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
