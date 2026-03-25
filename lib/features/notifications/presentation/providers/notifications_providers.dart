import 'package:flutter_pecha/features/notifications/data/datasource/notification_local_datasource.dart';
import 'package:flutter_pecha/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:flutter_pecha/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Data Layer Providers ==========

/// Provider for NotificationLocalDataSource.
final notificationLocalDataSourceProvider = Provider<NotificationLocalDataSource>((ref) {
  return NotificationLocalDataSource();
});

/// Provider for Notification Repository.
final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final localDataSource = ref.watch(notificationLocalDataSourceProvider);
  final notificationService = NotificationService();

  return NotificationsRepositoryImpl(
    localDataSource: localDataSource,
    notificationService: notificationService,
  );
});

// ========== Use Case Providers ==========

/// Provider for GetNotificationSettingsUseCase.
final getNotificationSettingsUseCaseProvider = Provider<GetNotificationSettingsUseCase>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return GetNotificationSettingsUseCase(repository);
});

/// Provider for UpdateNotificationSettingsUseCase.
final updateNotificationSettingsUseCaseProvider = Provider<UpdateNotificationSettingsUseCase>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return UpdateNotificationSettingsUseCase(repository);
});

/// Provider for ScheduleNotificationUseCase.
final scheduleNotificationUseCaseProvider = Provider<ScheduleNotificationUseCase>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return ScheduleNotificationUseCase(repository);
});

/// Provider for CancelNotificationUseCase.
final cancelNotificationUseCaseProvider = Provider<CancelNotificationUseCase>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return CancelNotificationUseCase(repository);
});

/// Provider for GetScheduledNotificationsUseCase.
final getScheduledNotificationsUseCaseProvider = Provider<GetScheduledNotificationsUseCase>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return GetScheduledNotificationsUseCase(repository);
});
