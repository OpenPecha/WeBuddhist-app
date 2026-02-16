import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/app/presentation/skeleton_screen.dart';

final _logger = AppLogger('NotificationService');

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  
  // Add static references for navigation
  static GoRouter? _router;
  static ProviderContainer? _container;

  // Method to set the router reference
  static void setRouter(GoRouter router) {
    _router = router;
  }

  // Method to set the provider container
  static void setContainer(ProviderContainer container) {
    _container = container;
  }

  bool get isInitialized => _isInitialized;

  /// Map legacy timezone IDs (e.g. from Android) to IANA names used by the timezone package.
  /// Default timezone data (latest.dart) may not include all legacy names.
  static const Map<String, String> _legacyTimezoneToIana = {
    'Asia/Calcutta': 'Asia/Kolkata',
    'US/Eastern': 'America/New_York',
    'US/Central': 'America/Chicago',
    'US/Mountain': 'America/Denver',
    'US/Pacific': 'America/Los_Angeles',
    'GMT': 'UTC',
  };

  /// Initialize without requesting permissions (for early app initialization)
  Future<void> initializeWithoutPermissions() async {
    if (_isInitialized) return; // prevent re-initialization

    // Initialize timezone: use device local time so scheduled notifications
    // (e.g. "7:10 AM") are in the user's local time, not UTC.
    tz.initializeTimeZones();
    final currentTimezone = await FlutterTimezone.getLocalTimezone();
    bool localSet = false;
    try {
      tz.setLocalLocation(tz.getLocation(currentTimezone));
      localSet = true;
    } catch (_) {
      final ianaName = _legacyTimezoneToIana[currentTimezone];
      if (ianaName != null) {
        try {
          tz.setLocalLocation(tz.getLocation(ianaName));
          _logger.info(
            'Mapped legacy timezone "$currentTimezone" to "$ianaName"',
          );
          localSet = true;
        } catch (_) {
          // fall through to UTC fallback
        }
      }
      if (!localSet) {
        _logger.warning(
          'Unknown timezone "$currentTimezone", falling back to UTC',
        );
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    // Android initialization - do NOT request permissions
    // Use drawable resource for notification icon (not mipmap)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

    // iOS initialization - do NOT request permissions
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        );

    // initialization settings
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // initialize the plugin
    await notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _isInitialized = true;
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      // Routine block reminder channel (only channel needed now)
      const AndroidNotificationChannel routineBlockChannel =
          AndroidNotificationChannel(
            routineBlockNotificationChannelId,
            routineBlockNotificationChannelName,
            description: routineBlockNotificationChannelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );

      await androidImplementation.createNotificationChannel(routineBlockChannel);

      _logger.info('Android notification channels created');
    }
  }

  /// Initialize with permission request (legacy method)
  Future<void> initialize() async {
    await initializeWithoutPermissions();
    await requestPermission();
  }

  // Request permission for notifications
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // Request notification permission
      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();

      // For Android 12+, also request exact alarm permission
      if (granted == true && Platform.isAndroid) {
        await androidImplementation?.requestExactAlarmsPermission();
      }

      return granted ?? false;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      final bool? granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? granted =
          await androidImplementation?.areNotificationsEnabled();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      final NotificationsEnabledOptions? granted =
          await iosImplementation?.checkPermissions();
      return granted?.isEnabled ?? false;
    }
    return false;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Navigate based on notification ID
    if (_router != null && _container != null) {
      // Routine block notifications have ID >= 100
      if (response.id != null && response.id! >= 100) {
        // Routine block notification — navigate to practice screen
        _router!.go('/practice');
      } else {
        // Default fallback - go to texts tab (index 0)
        _container!.read(bottomNavIndexProvider.notifier).state = 0;
        _router!.go('/home');
      }
    }
  }
}

// Routine block notification constants
const routineBlockNotificationChannelId = 'routine_block_reminder';
const routineBlockNotificationChannelName = 'Routine Block Reminder';
const routineBlockNotificationChannelDescription =
    'Daily notifications for routine practice blocks';
