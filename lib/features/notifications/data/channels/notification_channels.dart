import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Central registry for all app notification channels.
///
/// To add a new channel (e.g. reminders, announcements):
///   1. Add static const ID/name/description fields
///   2. Add a static final AndroidNotificationChannel
///   3. Add a static NotificationDetails factory method
/// No other file should define channel constants.
class NotificationChannels {
  NotificationChannels._();

  // ── Routine Block Reminder ──────────────────────────────────────────────────
  static const String routineBlockId = 'routine_block_reminder';
  static const String routineBlockName = 'Routine Block Reminder';
  static const String routineBlockDescription =
      'Daily notifications for routine practice blocks';

  /// Android raw resource sound — references android/app/src/main/res/raw/routine.ogg
  /// Specified WITHOUT file extension, as required by Android.
  static const RawResourceAndroidNotificationSound routineAndroidSound =
      RawResourceAndroidNotificationSound('routine');

  /// iOS sound file — routine.caf must be included in the Runner app bundle
  /// (Runner target → Build Phases → Copy Bundle Resources).
  static const String routineIosSoundFile = 'routine.caf';

  /// Android notification channel for routine blocks.
  /// Sound is baked in at channel creation time — Android does not allow
  /// changing it after the channel is registered on device.
  static const AndroidNotificationChannel routineBlockChannel =
      AndroidNotificationChannel(
        routineBlockId,
        routineBlockName,
        description: routineBlockDescription,
        importance: Importance.high,
        playSound: true,
        sound: routineAndroidSound,
        enableVibration: true,
      );

  /// Full platform-specific NotificationDetails for routine block notifications.
  static NotificationDetails routineBlockDetails({
    String icon = 'ic_notification',
    StyleInformation? styleInformation,
    FilePathAndroidBitmap? largeIcon,
    DarwinNotificationDetails? iOSDetails,
  }) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          routineBlockId,
          routineBlockName,
          channelDescription: routineBlockDescription,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: styleInformation,
          icon: icon,
          largeIcon: largeIcon,
          enableVibration: true,
          playSound: true,
          sound: routineAndroidSound,
        ),
        iOS: iOSDetails ?? DarwinNotificationDetails(
          sound: routineIosSoundFile,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
}
