import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
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
