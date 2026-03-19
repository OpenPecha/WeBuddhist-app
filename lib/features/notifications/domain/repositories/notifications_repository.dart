import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_settings.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Notifications repository interface.
abstract class NotificationsRepository extends Repository {
  /// Get notification settings.
  Future<Either<Failure, NotificationSettings>> getSettings();

  /// Update notification settings.
  Future<Either<Failure, NotificationSettings>> updateSettings(NotificationSettings settings);

  /// Schedule a notification.
  Future<Either<Failure, void>> scheduleNotification(AppNotification notification);

  /// Cancel a notification.
  Future<Either<Failure, void>> cancelNotification(String notificationId);

  /// Get scheduled notifications.
  Future<Either<Failure, List<AppNotification>>> getScheduledNotifications();
}
