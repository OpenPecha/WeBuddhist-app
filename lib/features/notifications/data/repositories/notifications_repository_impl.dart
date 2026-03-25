import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/notifications/data/datasource/notification_local_datasource.dart';
import 'package:flutter_pecha/features/notifications/data/models/notification_model.dart';
import 'package:flutter_pecha/features/notifications/data/models/notification_settings_model.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_settings.dart';
import 'package:flutter_pecha/features/notifications/domain/repositories/notifications_repository.dart';

/// Notifications repository implementation.
class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationLocalDataSource _localDataSource;
  final NotificationService _notificationService;

  NotificationsRepositoryImpl({
    required NotificationLocalDataSource localDataSource,
    required NotificationService notificationService,
  })  : _localDataSource = localDataSource,
        _notificationService = notificationService;

  @override
  Future<Either<Failure, NotificationSettings>> getSettings() async {
    try {
      final model = await _localDataSource.getSettings();
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load notification settings: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationSettings>> updateSettings(
    NotificationSettings settings,
  ) async {
    try {
      final model = NotificationSettingsModel.fromEntity(settings);
      await _localDataSource.saveSettings(model);
      return Right(settings);
    } catch (e) {
      return Left(CacheFailure('Failed to update notification settings: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> scheduleNotification(AppNotification notification) async {
    try {
      final model = NotificationModel.fromEntity(notification);

      // Add to local storage
      await _localDataSource.addScheduledNotification(model);

      // Schedule with notification service
      // Note: The actual scheduling logic would be implemented here
      // using the notification service

      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to schedule notification: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelNotification(String notificationId) async {
    try {
      // Remove from local storage
      await _localDataSource.removeScheduledNotification(notificationId);

      // Cancel with notification service
      // Note: The actual cancellation logic would be implemented here
      // using the notification service

      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to cancel notification: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AppNotification>>> getScheduledNotifications() async {
    try {
      final models = await _localDataSource.getScheduledNotifications();
      final notifications = models.map((model) => model.toEntity()).toList();
      return Right(notifications);
    } catch (e) {
      return Left(CacheFailure('Failed to load scheduled notifications: $e'));
    }
  }
}
