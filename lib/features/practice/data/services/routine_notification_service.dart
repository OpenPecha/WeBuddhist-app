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

class RoutineNotificationService {
  static final RoutineNotificationService _instance =
      RoutineNotificationService._internal();
  factory RoutineNotificationService() => _instance;
  RoutineNotificationService._internal();

  FlutterLocalNotificationsPlugin get _plugin =>
      NotificationService().notificationsPlugin;

  bool get _isReady => NotificationService().isInitialized;

  /// Schedule a daily repeating notification for a single block.
  Future<void> scheduleBlockNotification(RoutineBlock block) async {
    if (!block.notificationEnabled) return;

    if (!_isReady) {
      _logger.warning('NotificationService not initialized, skipping schedule');
      return;
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
    } catch (e) {
      _logger.error(
        'Failed to schedule notification for block ${block.id}',
        e,
      );
    }
  }

  /// Cancel notification for a single block.
  Future<void> cancelBlockNotification(RoutineBlock block) async {
    if (!_isReady) return;
    await _plugin.cancel(block.notificationId);
    _logger.info('Cancelled routine notification ID=${block.notificationId}');
  }

  /// Cancel all and reschedule enabled blocks that have items.
  Future<void> syncNotifications(List<RoutineBlock> blocks) async {
    if (!_isReady) {
      _logger.warning('NotificationService not initialized, skipping sync');
      return;
    }
    for (final block in blocks) {
      await _plugin.cancel(block.notificationId);
    }
    for (final block in blocks) {
      if (block.notificationEnabled && block.items.isNotEmpty) {
        await scheduleBlockNotification(block);
      }
    }
  }

  /// Cancel all routine block notifications.
  Future<void> cancelAllBlockNotifications(List<RoutineBlock> blocks) async {
    if (!_isReady) return;
    for (final block in blocks) {
      await _plugin.cancel(block.notificationId);
    }
    _logger.info('Cancelled all routine block notifications');
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
