import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:fpdart/fpdart.dart';

/// Contract for the push-messaging subsystem.
///
/// Abstracts Firebase Cloud Messaging (token lifecycle + message streams) and
/// the backend device-token registration behind a single domain interface.
abstract class PushMessagingRepository {
  /// Requests OS permission to display notifications (iOS + Android 13+).
  /// Returns `true` when the user has authorised notifications.
  Future<bool> requestPermission();

  /// Current FCM registration token for this device/install, or `null` if it
  /// could not be resolved yet (e.g. APNs token not ready on iOS).
  Future<String?> getToken();

  /// Emits whenever FCM rotates the token (reinstall, restore, expiry).
  Stream<String> get onTokenRefresh;

  /// Emits messages received while the app is in the foreground.
  Stream<PushMessage> get onForegroundMessage;

  /// Emits when a notification is tapped and the app moves from background to
  /// foreground.
  Stream<PushMessage> get onMessageOpenedApp;

  /// The notification that launched the app from a terminated state, if any.
  Future<PushMessage?> getInitialMessage();

  /// Registers (upserts) [token] for the signed-in user with the backend so it
  /// can target this device. The platform (`ANDROID`/`IOS`) is derived in the
  /// data layer. [deviceId] is an optional stable device identifier that lets
  /// token refreshes update the same record instead of creating duplicates.
  Future<Either<Failure, Unit>> registerDeviceToken(
    String token, {
    String? deviceId,
  });
}
