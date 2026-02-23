import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/services/notification_service.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:timezone/timezone.dart' as tz;

final _logger = AppLogger('RoutineNotificationService');

// Channel constants
const routineNotificationChannelId = 'routine_block_reminder';
const routineNotificationChannelName = 'Routine Block Reminder';
const routineNotificationChannelDescription =
    'Daily notifications for routine practice blocks';

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

  FlutterLocalNotificationsPlugin get _plugin =>
      NotificationService().notificationsPlugin;

  bool get _isReady => NotificationService().isInitialized;

  /// Schedule a daily repeating notification for a single block.
  ///
  /// Returns [NotificationResult] indicating success or failure with details.
  Future<NotificationResult> scheduleBlockNotification(RoutineBlock block) async {
    if (!block.notificationEnabled) {
      return NotificationResult.skipped('Notifications disabled for block');
    }

    if (block.items.isEmpty) {
      return NotificationResult.skipped('Block has no items');
    }

    if (!_isReady) {
      _logger.warning('NotificationService not initialized, skipping schedule');
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

      final body = _getNotificationBody(block);

      await _plugin.zonedSchedule(
        block.notificationId,
        'Time for your practice',
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            routineNotificationChannelId,
            routineNotificationChannelName,
            channelDescription: routineNotificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // daily repeat
      );

      _logger.info(
        'Scheduled routine notification ID=${block.notificationId} '
        'at ${block.formattedTime}',
      );

      return NotificationResult.success(block.notificationId);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to schedule notification for block ${block.id}',
        e,
        stackTrace,
      );
      return NotificationResult.failure(e.toString());
    }
  }

  /// Cancel notification for a single block.
  ///
  /// Safe to call even if the notification doesn't exist or service isn't ready.
  Future<void> cancelBlockNotification(RoutineBlock block) async {
    if (!_isReady) return;
    try {
      await _plugin.cancel(block.notificationId);
      _logger.info('Cancelled routine notification ID=${block.notificationId}');
    } catch (e) {
      _logger.warning('Failed to cancel notification ${block.notificationId}: $e');
    }
  }

  /// Synchronize notifications with the current block list.
  ///
  /// This uses a safer approach:
  /// 1. First schedules all new/updated notifications
  /// 2. Then cancels notifications for removed blocks
  ///
  /// This ensures that if the app crashes mid-sync, notifications are more
  /// likely to still be scheduled rather than lost.
  ///
  /// Returns [NotificationSyncResult] with details about the operation.
  Future<NotificationSyncResult> syncNotifications(List<RoutineBlock> blocks) async {
    if (!_isReady) {
      _logger.warning('NotificationService not initialized, skipping sync');
      return const NotificationSyncResult(
        errors: ['Notification service not initialized'],
      );
    }

    int scheduled = 0;
    int failed = 0;
    int cancelled = 0;
    final errors = <String>[];

    try {
      // Step 1: Schedule notifications for active blocks first (safer - ensures
      // notifications exist before we cancel old ones)
      final activeBlocks = blocks.where(
        (b) => b.notificationEnabled && b.items.isNotEmpty,
      ).toList();

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

      // Step 2: Cancel notifications for inactive/removed blocks
      // Cancel all blocks that are either:
      // - Not in the active list (removed or disabled)
      // - Have notifications disabled
      // - Have no items
      for (final block in blocks) {
        if (!activeIds.contains(block.notificationId)) {
          await cancelBlockNotification(block);
          cancelled++;
        }
      }

      _logger.info(
        'Notification sync complete: $scheduled scheduled, $cancelled cancelled, $failed failed',
      );
    } catch (e) {
      _logger.error('Sync failed: $e');
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
  ///
  /// Useful when you need to cancel a notification but don't have the full block.
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
}
