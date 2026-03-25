import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_settings.dart';
import 'package:flutter_pecha/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Get notification settings use case.
class GetNotificationSettingsUseCase extends UseCase<NotificationSettings, NoParams> {
  final NotificationsRepository _repository;

  GetNotificationSettingsUseCase(this._repository);

  @override
  Future<Either<Failure, NotificationSettings>> call(NoParams params) async {
    return await _repository.getSettings();
  }
}

/// Update notification settings use case.
class UpdateNotificationSettingsUseCase extends UseCase<NotificationSettings, UpdateSettingsParams> {
  final NotificationsRepository _repository;

  UpdateNotificationSettingsUseCase(this._repository);

  @override
  Future<Either<Failure, NotificationSettings>> call(UpdateSettingsParams params) async {
    return await _repository.updateSettings(params.settings);
  }
}

class UpdateSettingsParams {
  final NotificationSettings settings;
  const UpdateSettingsParams({required this.settings});
}

/// Schedule notification use case.
class ScheduleNotificationUseCase extends UseCase<void, ScheduleNotificationParams> {
  final NotificationsRepository _repository;

  ScheduleNotificationUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(ScheduleNotificationParams params) async {
    if (params.notification.id.isEmpty) {
      return const Left(ValidationFailure('Notification ID cannot be empty'));
    }
    return await _repository.scheduleNotification(params.notification);
  }
}

class ScheduleNotificationParams {
  final AppNotification notification;
  const ScheduleNotificationParams({required this.notification});
}

/// Cancel notification use case.
class CancelNotificationUseCase extends UseCase<void, CancelNotificationParams> {
  final NotificationsRepository _repository;

  CancelNotificationUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(CancelNotificationParams params) async {
    if (params.notificationId.isEmpty) {
      return const Left(ValidationFailure('Notification ID cannot be empty'));
    }
    return await _repository.cancelNotification(params.notificationId);
  }
}

class CancelNotificationParams {
  final String notificationId;
  const CancelNotificationParams({required this.notificationId});
}

/// Get scheduled notifications use case.
class GetScheduledNotificationsUseCase extends UseCase<List<AppNotification>, NoParams> {
  final NotificationsRepository _repository;

  GetScheduledNotificationsUseCase(this._repository);

  @override
  Future<Either<Failure, List<AppNotification>>> call(NoParams params) async {
    return await _repository.getScheduledNotifications();
  }
}

