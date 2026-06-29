import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:uuid/uuid.dart';

/// Background / terminated-state FCM handler. Must be a top-level function with
/// `@pragma` so it survives AOT and runs in its own isolate. Notification
/// messages are displayed by the OS automatically in this state, so this only
/// re-initialises Firebase and logs.
@pragma('vm:entry-point')
Future<void> pushNotificationBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  AppLogger('PushBackground').info('Background message: ${message.messageId}');
}

/// Drives the push-notification lifecycle:
///   1. Requests permission + creates the Android channel.
///   2. Captures the FCM token (install) and listens for rotations (refresh).
///   3. Registers the token with the backend once a user signs in.
///   4. Shows foreground messages and handles notification taps.
///
/// Depends only on [PushMessagingRepository], so Firebase stays out of this
/// layer and the service is unit-testable.
class PushNotificationService {
  PushNotificationService({
    required PushMessagingRepository repository,
    required LocalStorageService storage,
  })  : _repository = repository,
        _storage = storage;

  final PushMessagingRepository _repository;
  final LocalStorageService _storage;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _logger = AppLogger('PushNotificationService');
  final _subscriptions = <StreamSubscription<dynamic>>[];

  /// Invoked when a notification is opened from the background or terminated
  /// state. Set by the bootstrap layer to route via [PushMessageNavigator].
  /// Foreground taps reach the navigator separately (through the shared
  /// flutter_local_notifications callback), so they don't pass through here.
  void Function(PushMessage message)? onOpenMessage;

  String? _token;
  bool _loggedIn = false;
  bool _initialized = false;
  Future<void>? _initializing;

  /// One-time setup. Concurrent calls share the in-flight attempt, and calls
  /// after a successful run are ignored. A failed attempt does NOT latch — it
  /// tears down any partial wiring and leaves the service ready to retry, so a
  /// transient failure can't permanently disable token refresh / registration.
  Future<void> initialize() {
    if (_initialized) return Future.value();
    return _initializing ??= _runInitialize();
  }

  Future<void> _runInitialize() async {
    try {
      await _createAndroidChannel();
      final granted = await _repository.requestPermission();
      _logger.info('Notification permission granted: $granted');

      _subscriptions
        ..add(_repository.onForegroundMessage.listen(_showNotification))
        ..add(_repository.onMessageOpenedApp.listen(_onNotificationTapped))
        ..add(_repository.onTokenRefresh.listen(_onToken));

      // Terminated-state launch via a notification tap.
      final launchMessage = await _repository.getInitialMessage();
      if (launchMessage != null) _onNotificationTapped(launchMessage);

      // Token for this install.
      final token = await _repository.getToken();
      if (token != null) await _onToken(token);

      // Only latch once the full setup has succeeded.
      _initialized = true;
    } catch (e, st) {
      _logger.warning('Push initialization failed: $e', e, st);
      // Drop any listeners added before the failure so a retry starts clean
      // and we don't double-subscribe.
      for (final sub in _subscriptions) {
        unawaited(sub.cancel());
      }
      _subscriptions.clear();
    } finally {
      _initializing = null;
    }
  }

  /// Feeds in the latest auth snapshot. Registers the token with the backend on
  /// sign-in (the backend keys the device on the JWT, so no profile data is
  /// needed). Guests are treated as signed out for push targeting.
  void onAuthChanged({required bool loggedIn}) {
    final shouldRegister = loggedIn && !_loggedIn;
    _loggedIn = loggedIn;
    if (shouldRegister) unawaited(_registerToken());
  }

  Future<void> _onToken(String token) async {
    if (token == _token) return;
    _token = token;
    await _storage.set(StorageKeys.fcmToken, token);
    _logger.info('FCM token captured/refreshed');
    // Full token logged at debug level only (stripped from release builds) so
    // you can copy it into the Firebase console to send a test push.
    _logger.debug('FCM token: $token');
    await _registerToken();
  }

  Future<void> _registerToken() async {
    final token = _token;
    if (token == null || !_loggedIn) return;
    final deviceId = await _deviceId();
    final result =
        await _repository.registerDeviceToken(token, deviceId: deviceId);
    result.fold(
      (failure) => _logger.warning('Token registration failed: ${failure.message}'),
      (_) => _logger.info('Token registered'),
    );
  }

  /// Returns the stable per-install device id, generating and persisting one on
  /// first use. Lets backend token refreshes update the same record.
  Future<String> _deviceId() async {
    final existing = await _storage.get<String>(StorageKeys.pushDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _storage.set(StorageKeys.pushDeviceId, id);
    return id;
  }

  Future<void> _showNotification(PushMessage message) async {
    if (!message.hasNotification) return;
    _logger.info('Foreground message: ${message.title}');
    await _localNotifications.show(
      // Time-based id kept within the 32-bit range Android requires.
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      message.title,
      message.body,
      NotificationChannels.pushDefaultDetails,
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }

  void _onNotificationTapped(PushMessage message) {
    _logger.info('Notification opened: ${message.title} data=${message.data}');
    onOpenMessage?.call(message);
  }

  Future<void> _createAndroidChannel() async {
    // Resolver returns null off-Android, so this is a no-op on iOS/macOS.
    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      NotificationChannels.pushDefaultChannel,
    );
  }

  void dispose() {
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
  }
}
