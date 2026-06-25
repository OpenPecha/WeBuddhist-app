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

  // ── Push (Firebase Cloud Messaging) ─────────────────────────────────────────
  static const String pushDefaultId = 'push_default';
  static const String pushDefaultName = 'General Notifications';
  static const String pushDefaultDescription =
      'Announcements and updates from WeBuddhist';

  /// Android channel for remote (FCM) notifications. Referenced from
  /// AndroidManifest as `default_notification_channel_id` so background /
  /// terminated FCM messages land here, and reused for foreground display.
  static const AndroidNotificationChannel pushDefaultChannel =
      AndroidNotificationChannel(
        pushDefaultId,
        pushDefaultName,
        description: pushDefaultDescription,
        importance: Importance.high,
      );

  /// Platform details used when displaying a foreground FCM message via
  /// flutter_local_notifications (Android suppresses FCM auto-display while the
  /// app is foregrounded).
  static const NotificationDetails pushDefaultDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      pushDefaultId,
      pushDefaultName,
      channelDescription: pushDefaultDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// Action ID used for the Android action button on special-plan day-N
  /// notifications. The tap handler treats this the same as a body tap.
  static const String specialPlanActionId = 'special_plan_action';

  /// Full platform-specific NotificationDetails for routine block notifications.
  ///
  /// [androidActionButtonText] adds a single Android action button (e.g.
  /// "START", "READ ON"). When `null`, no action button is rendered. iOS does
  /// not render this label per product decision — body tap on iOS routes to
  /// the same destination, preserving functionality.
  static NotificationDetails routineBlockDetails({
    String icon = 'ic_notification',
    StyleInformation? styleInformation,
    FilePathAndroidBitmap? largeIcon,
    DarwinNotificationDetails? iOSDetails,
    String? androidActionButtonText,
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
          actions: androidActionButtonText == null
              ? null
              : <AndroidNotificationAction>[
                  AndroidNotificationAction(
                    specialPlanActionId,
                    androidActionButtonText,
                    showsUserInterface: true,
                    cancelNotification: true,
                  ),
                ],
        ),
        iOS: iOSDetails ?? DarwinNotificationDetails(
          sound: routineIosSoundFile,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
}
